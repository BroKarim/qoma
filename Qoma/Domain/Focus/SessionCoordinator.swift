import Foundation
import Combine
import OSLog

/// Coordinates a single active focus session: timer, persistence, policy, and catch.
/// Replaces the legacy FocusSessionManager break/session mixing.
@MainActor
final class SessionCoordinator: ObservableObject {
    enum Event: Equatable {
        case started
        case paused
        case resumed
        case taskUpdated(String)
        case policyUpdated(SessionPolicy)
        case completed
        case interrupted(reason: String?)
        case catchDeposited(CatchEvent, banked: Bool)
        case distractionChanged(Bool)
        case timeRemainingUpdated(TimeInterval)
    }

    // MARK: - Dependencies

    private let accountID: String
    private let sessionRepository: any SessionRepositoryProtocol
    private let catchRepository: any CatchRepositoryProtocol
    private let canStartSession: () -> Bool
    private let now: () -> Date

    // MARK: - State

    @Published private(set) var snapshot: ActiveSessionSnapshot?
    @Published private(set) var remainingTime: TimeInterval = 0
    @Published private(set) var isDistractionActive = false
    private var clock: SessionClock?
    private var catchEngine: CatchEngine?
    private var timerCancellable: AnyCancellable?
    private var finalizedSessionIDs = Set<UUID>()

    var isActive: Bool { snapshot?.status == .active }
    var isPaused: Bool { snapshot?.status == .paused }
    var currentTaskTitle: String { snapshot?.draft.displayTitle ?? "" }
    var currentPolicy: SessionPolicy { snapshot?.draft.policy ?? .timerOnly }

    init(
        accountID: String = "local",
        sessionRepository: any SessionRepositoryProtocol = SessionRepository.shared,
        catchRepository: any CatchRepositoryProtocol = CatchRepository.shared,
        canStartSession: @escaping () -> Bool = { true },
        now: @escaping () -> Date = Date.init
    ) {
        self.accountID = accountID
        self.sessionRepository = sessionRepository
        self.catchRepository = catchRepository
        self.canStartSession = canStartSession
        self.now = now
    }

    // MARK: - Lifecycle

    /// Attempt to restore an active session from disk.
    func restore() {
        guard snapshot == nil else { return }
        guard let stored = sessionRepository.loadActive(accountID: accountID) else { return }

        let clock = SessionClock(
            plannedDuration: stored.deadline.timeIntervalSince(stored.startedAt),
            startTime: stored.startedAt,
            accumulatedActiveSeconds: stored.accumulatedActiveSeconds,
            pausedAt: stored.pausedAt,
            now: now
        )

        self.clock = clock
        self.snapshot = stored
        self.catchEngine = CatchEngine()

        if clock.isDue {
            completeIfDue()
        } else {
            startTicking()
            Logger.session.info("Restored session \(stored.id, privacy: .public)")
        }
    }

    /// Start a new session from a draft.
    @discardableResult
    func startSession(draft: SessionDraft) -> ActiveSessionSnapshot? {
        guard canStartSession() else { return nil }
        guard snapshot == nil else { return snapshot }

        let plannedDuration = TimeInterval(draft.plannedMinutes) * 60
        let id = UUID()
        let startedAt = now()
        let newSnapshot = ActiveSessionSnapshot(
            id: id,
            accountID: accountID,
            startedAt: startedAt,
            deadline: startedAt.addingTimeInterval(plannedDuration),
            pausedAt: nil,
            accumulatedActiveSeconds: 0,
            draft: draft,
            status: .active
        )

        self.clock = SessionClock(
            plannedDuration: plannedDuration,
            startTime: startedAt,
            now: now
        )
        self.snapshot = newSnapshot
        self.catchEngine = CatchEngine()
        sessionRepository.saveActive(newSnapshot)
        startTicking()
        Logger.session.info("Started session \(id, privacy: .public)")
        return newSnapshot
    }

    func pauseSession() {
        guard var snap = snapshot, snap.status == .active else { return }
        clock?.pause()
        snap.status = .paused
        snap.pausedAt = now()
        snap.accumulatedActiveSeconds = clock?.activeSeconds ?? snap.accumulatedActiveSeconds
        snapshot = snap
        sessionRepository.saveActive(snap)
        stopTicking()
        Logger.session.info("Paused session \(snap.id, privacy: .public)")
    }

    func resumeSession() {
        guard var snap = snapshot, snap.status == .paused else { return }
        clock?.resume()
        snap.status = .active
        snap.pausedAt = nil
        snap.deadline = clock?.deadline ?? snap.deadline
        snapshot = snap
        sessionRepository.saveActive(snap)
        startTicking()
        Logger.session.info("Resumed session \(snap.id, privacy: .public)")
    }

    /// Stop the session early. Records `interrupted` and discards provisional catches
    /// when active time is below five minutes.
    func stopSession(reason: String? = nil) -> FocusSession? {
        guard var snap = snapshot else { return nil }

        stopTicking()

        let activeSeconds = clock?.activeSeconds ?? snap.accumulatedActiveSeconds
        let endedAt = now()

        snap.status = .interrupted
        snap.accumulatedActiveSeconds = activeSeconds
        snapshot = snap
        sessionRepository.saveActive(snap)

        if activeSeconds < CatchEngine.bankThresholdSeconds {
            catchRepository.deleteProvisional(sessionID: snap.id, accountID: accountID)
            Logger.session.info("Discarded provisional catches for short session")
        }

        let session = FocusSession(
            id: snap.id,
            accountID: accountID,
            startedAt: snap.startedAt,
            endedAt: endedAt,
            plannedMinutes: snap.draft.plannedMinutes,
            actualActiveSeconds: activeSeconds,
            status: .interrupted,
            draftSnapshot: snap.draft,
            taskTitle: snap.draft.displayTitle,
            interruptedReason: reason
        )

        finalizeOnce(session)
        reset()
        Logger.session.info("Stopped session \(snap.id, privacy: .public)")
        return session
    }

    /// Complete the session because the countdown reached zero.
    @discardableResult
    func completeIfDue() -> FocusSession? {
        guard let clock, clock.isDue, var snap = snapshot else { return nil }
        guard snap.status == .active || snap.status == .paused else { return nil }
        guard !finalizedSessionIDs.contains(snap.id) else { return nil }

        stopTicking()

        let activeSeconds = clock.activeSeconds
        let endedAt = now()

        snap.status = .completed
        snap.accumulatedActiveSeconds = activeSeconds
        snap.deadline = endedAt
        snapshot = snap
        sessionRepository.saveActive(snap)

        let session = FocusSession(
            id: snap.id,
            accountID: accountID,
            startedAt: snap.startedAt,
            endedAt: endedAt,
            plannedMinutes: snap.draft.plannedMinutes,
            actualActiveSeconds: activeSeconds,
            status: .completed,
            draftSnapshot: snap.draft,
            taskTitle: snap.draft.displayTitle
        )

        finalizeOnce(session)
        reset()
        Logger.session.info("Completed session \(snap.id, privacy: .public)")
        return session
    }

    func updateTask(title: String) {
        guard var snap = snapshot else { return }
        snap.draft.taskTitle = title
        snapshot = snap
        sessionRepository.saveActive(snap)
        Logger.session.info("Updated task title")
    }

    func updatePolicy(_ policy: SessionPolicy) {
        guard var snap = snapshot else { return }
        snap.draft.policy = policy
        snapshot = snap
        sessionRepository.saveActive(snap)
        Logger.session.info("Updated session policy")
    }

    /// Temporarily allow a resource for the current session only.
    func allowForCurrentSession(_ resource: FocusResource) {
        guard var snap = snapshot else { return }
        switch resource {
        case .app(let bundleID):
            if snap.draft.policy.mode == .allowing {
                snap.draft.policy.allowedApps.insert(bundleID)
            } else if snap.draft.policy.mode == .blocking {
                snap.draft.policy.blockedApps.remove(bundleID)
            }
        case .domain(let host):
            let normalized = FocusPolicyEvaluator.normalizeDomain(host)
            if snap.draft.policy.mode == .allowing {
                snap.draft.policy.allowedDomains.insert(normalized)
            } else if snap.draft.policy.mode == .blocking {
                snap.draft.policy.blockedDomains.remove(normalized)
            }
        }
        snapshot = snap
        sessionRepository.saveActive(snap)
    }

    // MARK: - Catch integration

    func scheduleNextBite() -> TimeInterval {
        catchEngine?.scheduleNextBite() ?? 0
    }

    func beginReel() -> (kindID: String, duration: TimeInterval)? {
        catchEngine?.beginReel()
    }

    func depositCatch() -> (event: CatchEvent, banked: Bool)? {
        guard let snap = snapshot, let clock else { return nil }
        guard let result = catchEngine?.deposit(
            sessionID: snap.id,
            accountID: accountID,
            activeSeconds: clock.activeSeconds,
            now: now()
        ) else { return nil }

        catchRepository.saveProvisional(result.event)
        if result.banked {
            catchRepository.bank(result.event.id, accountID: accountID, at: now())
        }
        return result
    }

    func cancelInFlightCatch() {
        catchEngine?.cancelInFlight()
    }

    // MARK: - Policy / distraction

    func consume(activity: ForegroundActivity) {
        guard let snap = snapshot, snap.status == .active else { return }
        let decision = FocusPolicyEvaluator.evaluate(activity, against: snap.draft.policy)
        let wasDistraction = isDistractionActive
        isDistractionActive = decision.isDistraction
        if decision.isDistraction {
            cancelInFlightCatch()
        }
        if wasDistraction != isDistractionActive {
            Logger.session.info("Distraction changed: \(self.isDistractionActive, privacy: .public)")
        }
    }

    // MARK: - Private

    private func startTicking() {
        stopTicking()
        remainingTime = clock?.remaining ?? 0
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.remainingTime = self.clock?.remaining ?? 0
                if self.clock?.isDue == true {
                    self.completeIfDue()
                }
            }
    }

    private func stopTicking() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func finalizeOnce(_ session: FocusSession) {
        guard !finalizedSessionIDs.contains(session.id) else { return }
        sessionRepository.finalizeOnce(session)
        finalizedSessionIDs.insert(session.id)
        sessionRepository.deleteActive(accountID: accountID)
    }

    private func reset() {
        snapshot = nil
        clock = nil
        catchEngine = nil
        isDistractionActive = false
        stopTicking()
    }
}
