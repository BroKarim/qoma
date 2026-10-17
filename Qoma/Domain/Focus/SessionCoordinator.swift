import Foundation
import Combine
import OSLog

enum SessionFinalizationState: Equatable {
    case idle
    case saving
    case failed(String)
}

/// Coordinates a single active focus session: timer, persistence, policy, and catch.
/// Replaces the legacy FocusSessionManager break/session mixing.
@MainActor
final class SessionCoordinator: ObservableObject {

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
    @Published private(set) var lastCatchEvent: CatchEvent?
    @Published private(set) var currentReelKindID: String?
    @Published private(set) var finalizationState: SessionFinalizationState = .idle
    @Published private(set) var catchesRevision = 0

    private var clock: SessionClock?
    private var catchEngine: CatchEngine?
    private var timerCancellable: AnyCancellable?
    private var finalizedSessionIDs = Set<UUID>()
    private var thresholdBankedSessionIDs = Set<UUID>()
    private var pendingFinalizationSnapshot: ActiveSessionSnapshot?
    private var pendingRestorationSnapshot: ActiveSessionSnapshot?

    // Catch timer state
    private var catchTimer: Timer?
    private var catchDeadline: Date?
    private var catchPhase: CatchEngine.Phase = .waiting
    private let autoCatchEnabled: Bool

    var isActive: Bool { snapshot?.status == .active }
    var isPaused: Bool { snapshot?.status == .paused }
    var currentTaskTitle: String { snapshot?.draft.displayTitle ?? "" }
    var currentPolicy: SessionPolicy { snapshot?.draft.policy ?? .timerOnly }
    var sessionAccountID: String { accountID }

    var onSessionEnded: ((FocusSession) -> Void)?

    init(
        accountID: String = "local",
        sessionRepository: any SessionRepositoryProtocol = SessionRepository.shared,
        catchRepository: any CatchRepositoryProtocol = CatchRepository.shared,
        canStartSession: @escaping () -> Bool = { true },
        now: @escaping () -> Date = Date.init,
        autoCatchEnabled: Bool = true
    ) {
        self.accountID = accountID
        self.sessionRepository = sessionRepository
        self.catchRepository = catchRepository
        self.canStartSession = canStartSession
        self.now = now
        self.autoCatchEnabled = autoCatchEnabled
    }

    // MARK: - Lifecycle

    /// Attempt to restore an active session from disk.
    func restore() {
        guard snapshot == nil else { return }
        guard var stored = sessionRepository.loadActive(accountID: accountID) else { return }

        if stored.status == .completed || stored.status == .interrupted {
            snapshot = stored
            finalizationState = .saving
            recoverFinalizedSnapshot(stored)
            return
        }

        if !stored.draft.policy.allowedDomains.isEmpty || !stored.draft.policy.blockedDomains.isEmpty {
            stored.draft.policy.allowedDomains = []
            stored.draft.policy.blockedDomains = []
            guard sessionRepository.saveActive(stored) else {
                pendingRestorationSnapshot = stored
                snapshot = stored
                finalizationState = .failed("Could not update this restored session.")
                return
            }
        }

        let plannedDuration = TimeInterval(stored.draft.plannedMinutes) * 60
        let segmentStart = stored.activeSegmentStartedAt
            ?? (stored.status == .active && stored.accumulatedActiveSeconds > 0
                ? stored.deadline.addingTimeInterval(-plannedDuration + stored.accumulatedActiveSeconds)
                : stored.startedAt)

        let clock = SessionClock(
            plannedDuration: plannedDuration,
            startTime: segmentStart,
            accumulatedActiveSeconds: stored.accumulatedActiveSeconds,
            pausedAt: stored.pausedAt,
            deadline: stored.deadline,
            now: now
        )

        self.clock = clock
        self.snapshot = stored
        self.catchEngine = CatchEngine()

        if clock.isDue {
            completeIfDue()
        } else {
            startTicking()
            startCatchTimer(afterResume: false)
            bankIfThresholdReached()
            Logger.session.info("Restored session \(stored.id, privacy: .public)")
        }
    }

    /// Start a new session from a draft.
    @discardableResult
    func startSession(draft: SessionDraft) -> ActiveSessionSnapshot? {
        guard canStartSession() else { return nil }
        guard finalizationState == .idle else { return nil }
        guard snapshot == nil else { return snapshot }
        guard draft.policy.mode != .allowing || !draft.policy.allowedApps.isEmpty else { return nil }

        var draft = draft
        draft.policy.allowedDomains = []
        draft.policy.blockedDomains = []

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
            activeSegmentStartedAt: startedAt,
            draft: draft,
            status: .active
        )

        guard sessionRepository.saveActive(newSnapshot) else {
            Logger.session.error("Could not persist new session before starting")
            return nil
        }

        self.clock = SessionClock(
            plannedDuration: plannedDuration,
            startTime: startedAt,
            now: now
        )
        self.snapshot = newSnapshot
        self.catchEngine = CatchEngine()
        startTicking()
        startCatchTimer(afterResume: false)
        Logger.session.info("Started session \(id, privacy: .public)")
        return newSnapshot
    }

    func pauseSession() {
        guard var snap = snapshot, snap.status == .active else { return }
        if clock?.isDue == true { _ = completeIfDue(); return }
        clock?.pause()
        snap.status = .paused
        snap.pausedAt = now()
        snap.accumulatedActiveSeconds = clock?.activeSeconds ?? snap.accumulatedActiveSeconds
        snap.activeSegmentStartedAt = nil
        guard sessionRepository.saveActive(snap) else {
            clock?.resume()
            Logger.session.error("Could not persist pause")
            return
        }
        snapshot = snap
        stopTicking()
        pauseCatchTimer()
        Logger.session.info("Paused session \(snap.id, privacy: .public)")
    }

    func resumeSession() {
        guard var snap = snapshot, snap.status == .paused else { return }
        clock?.resume()
        snap.status = .active
        snap.pausedAt = nil
        snap.deadline = clock?.deadline ?? snap.deadline
        snap.activeSegmentStartedAt = now()
        guard sessionRepository.saveActive(snap) else {
            clock?.pause()
            Logger.session.error("Could not persist resume")
            return
        }
        snapshot = snap
        startTicking()
        startCatchTimer(afterResume: true)
        Logger.session.info("Resumed session \(snap.id, privacy: .public)")
    }

    @discardableResult
    func resetSession() -> Bool {
        guard snapshot?.status == .active || snapshot?.status == .paused else { return false }
        _ = stopSession(reason: "Reset from menu bar")
        return snapshot == nil
    }

    /// Stop the session early. Records `interrupted` and discards provisional catches
    /// when active time is below five minutes.
    func stopSession(reason: String? = nil) -> FocusSession? {
        guard var snap = snapshot else { return nil }
        if clock?.isDue == true { return completeIfDue() }

        let activeSeconds = clock?.activeSeconds ?? snap.accumulatedActiveSeconds
        let endedAt = now()

        snap.status = .interrupted
        snap.accumulatedActiveSeconds = activeSeconds
        snap.endedAt = endedAt
        snap.interruptedReason = reason
        snap.activeSegmentStartedAt = nil
        pendingFinalizationSnapshot = snap
        stopTicking()
        stopCatchTimer(discardInFlight: true)
        guard sessionRepository.saveActive(snap) else {
            Logger.session.error("Could not persist stopped session")
            finalizationState = .failed("Could not save this session.")
            return nil
        }
        snapshot = snap
        finalizationState = .saving
        return recoverFinalizedSnapshot(snap)
    }

    /// Complete the session because the countdown reached zero.
    @discardableResult
    func completeIfDue() -> FocusSession? {
        guard let clock, clock.isDue, var snap = snapshot else { return nil }
        guard snap.status == .active || snap.status == .paused else { return nil }
        guard !finalizedSessionIDs.contains(snap.id) else { return nil }

        let activeSeconds = clock.activeSeconds
        let endedAt = snap.deadline
        snap.status = .completed
        snap.accumulatedActiveSeconds = activeSeconds
        snap.endedAt = endedAt
        snap.activeSegmentStartedAt = nil
        pendingFinalizationSnapshot = snap
        stopTicking()
        stopCatchTimer(discardInFlight: true)
        guard sessionRepository.saveActive(snap) else {
            Logger.session.error("Could not persist completed session")
            finalizationState = .failed("Could not save the completed session.")
            return nil
        }
        snapshot = snap
        finalizationState = .saving
        return recoverFinalizedSnapshot(snap)
    }

    func retryFinalization() {
        if let pending = pendingRestorationSnapshot {
            finalizationState = .saving
            guard sessionRepository.saveActive(pending) else {
                finalizationState = .failed("Could not update this restored session.")
                return
            }
            pendingRestorationSnapshot = nil
            snapshot = nil
            finalizationState = .idle
            restore()
            return
        }
        if let pending = pendingFinalizationSnapshot {
            finalizationState = .saving
            guard sessionRepository.saveActive(pending) else {
                finalizationState = .failed("Could not save this session.")
                return
            }
            snapshot = pending
            _ = recoverFinalizedSnapshot(pending)
            return
        }
        guard let snap = snapshot,
              snap.status == .completed || snap.status == .interrupted else { return }
        finalizationState = .saving
        _ = recoverFinalizedSnapshot(snap)
    }

    @discardableResult
    func updateAppRules(allowedApps: Set<String>, blockedApps: Set<String>) -> Bool {
        guard var snap = snapshot, snap.status == .active || snap.status == .paused else { return false }
        let allowedApps = Self.validBundleIDs(allowedApps)
        let blockedApps = Self.validBundleIDs(blockedApps)
        switch snap.draft.policy.mode {
        case .allowing:
            guard !allowedApps.isEmpty else { return false }
            snap.draft.policy.allowedApps = allowedApps
        case .blocking:
            snap.draft.policy.blockedApps = blockedApps
        case .timerOnly:
            return false
        }
        snap.draft.policy.allowedDomains = []
        snap.draft.policy.blockedDomains = []
        guard sessionRepository.saveActive(snap) else { return false }
        snapshot = snap
        return true
    }

    // MARK: - Policy / distraction

    /// Consume a foreground activity decision. This only updates the distraction flag;
    /// it never cancels an in-flight catch (fishing continues during visual friction).
    func setDistractionActive(_ active: Bool) {
        isDistractionActive = active
    }

    // MARK: - Catch (manual/test hooks)

    @discardableResult
    func scheduleNextBite() -> TimeInterval {
        catchEngine?.scheduleNextBite() ?? 0
    }

    @discardableResult
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

        guard catchRepository.saveProvisional(result.event) else {
            Logger.session.error("Could not persist provisional catch")
            catchEngine?.cancelInFlight()
            return nil
        }
        if result.banked {
            guard catchRepository.bank(result.event.id, sessionID: result.event.sessionID, accountID: accountID, at: now()) else {
                Logger.session.error("Could not persist banked catch")
                catchEngine?.cancelInFlight()
                return nil
            }
        }
        lastCatchEvent = result.event
        if result.banked { catchesRevision += 1 }
        return result
    }

    // MARK: - Catch timer

    private func startCatchTimer(afterResume: Bool) {
        guard autoCatchEnabled else { return }
        guard catchEngine != nil else { return }
        guard snapshot?.status == .active else { return }

        if afterResume, let deadline = catchDeadline {
            let remaining = deadline.timeIntervalSince(now())
            if remaining > 0 {
                scheduleCatchTimer(after: remaining)
                return
            }
        }

        let wait = catchEngine?.scheduleNextBite() ?? 0
        catchDeadline = now().addingTimeInterval(wait)
        catchPhase = .waiting
        scheduleCatchTimer(after: wait)
    }

    private func scheduleCatchTimer(after interval: TimeInterval) {
        catchTimer?.invalidate()
        catchTimer = Timer.scheduledTimer(withTimeInterval: max(0.01, interval), repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleCatchTimerFired() }
        }
    }

    private func handleCatchTimerFired() {
        guard snapshot?.status == .active else { return }

        switch catchPhase {
        case .waiting, .bite:
            guard let result = catchEngine?.beginReel() else {
                startCatchTimer(afterResume: false)
                return
            }
            catchPhase = .reeling(kindID: result.kindID)
            currentReelKindID = result.kindID
            catchDeadline = now().addingTimeInterval(result.duration)
            scheduleCatchTimer(after: result.duration)
        case .reeling(let kindID):
            depositCatch(kindID: kindID)
            currentReelKindID = nil
            startCatchTimer(afterResume: false)
        case .depositing:
            startCatchTimer(afterResume: false)
        }
    }

    private func depositCatch(kindID: String) {
        guard let snap = snapshot, let clock else { return }
        guard let result = catchEngine?.deposit(
            sessionID: snap.id,
            accountID: accountID,
            activeSeconds: clock.activeSeconds,
            now: now()
        ) else { return }

        guard catchRepository.saveProvisional(result.event) else {
            Logger.session.error("Could not persist provisional catch")
            catchEngine?.cancelInFlight()
            return
        }
        if result.banked {
            guard catchRepository.bank(
                result.event.id, sessionID: result.event.sessionID, accountID: accountID, at: now()) else {
                Logger.session.error("Could not persist banked catch")
                catchEngine?.cancelInFlight()
                return
            }
        }
        lastCatchEvent = result.event
        if result.banked { catchesRevision += 1 }
        Logger.session.info("Deposited catch \(result.event.kindID) banked=\(result.banked, privacy: .public)")
    }

    private func pauseCatchTimer() {
        catchTimer?.invalidate()
        catchTimer = nil
    }

    private func stopCatchTimer(discardInFlight: Bool) {
        catchTimer?.invalidate()
        catchTimer = nil
        catchDeadline = nil
        currentReelKindID = nil
        if discardInFlight {
            catchEngine?.cancelInFlight()
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
                self.bankIfThresholdReached()
                if self.clock?.isDue == true {
                    self.completeIfDue()
                }
            }
    }

    private func stopTicking() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func bankIfThresholdReached() {
        guard let snap = snapshot, let clock,
              clock.activeSeconds >= CatchEngine.bankThresholdSeconds,
              !thresholdBankedSessionIDs.contains(snap.id) else { return }
        if catchRepository.bankProvisional(sessionID: snap.id, accountID: accountID, at: now()) {
            thresholdBankedSessionIDs.insert(snap.id)
            catchesRevision += 1
        } else {
            Logger.session.error("Could not bank provisional catches at threshold")
        }
    }

    @discardableResult
    private func recoverFinalizedSnapshot(_ snap: ActiveSessionSnapshot) -> FocusSession? {
        let endedAt = snap.endedAt ?? now()
        let status = snap.status
        if status == .interrupted && snap.accumulatedActiveSeconds < CatchEngine.bankThresholdSeconds {
            guard catchRepository.deleteProvisional(sessionID: snap.id, accountID: accountID) else {
                finalizationState = .failed("Could not clean up this session. Try saving again.")
                snapshot = snap
                return nil
            }
        } else if !catchRepository.bankProvisional(sessionID: snap.id, accountID: accountID, at: endedAt) {
            Logger.session.error("Could not reconcile provisional catches for terminal session")
            finalizationState = .failed("Could not save today’s catches. Try saving again.")
            snapshot = snap
            return nil
        } else {
            catchesRevision += 1
        }
        let session = FocusSession(
            id: snap.id,
            accountID: snap.accountID,
            startedAt: snap.startedAt,
            endedAt: endedAt,
            plannedMinutes: snap.draft.plannedMinutes,
            actualActiveSeconds: snap.accumulatedActiveSeconds,
            status: status,
            draftSnapshot: snap.draft,
            taskTitle: snap.draft.displayTitle,
            interruptedReason: snap.interruptedReason
        )
        let wasAlreadyFinalized = sessionRepository.loadHistory(accountID: accountID).contains { $0.id == session.id }
        guard finalizedSessionIDs.contains(session.id) || sessionRepository.finalizeOnce(session) else {
            Logger.session.error("Could not finalize session history")
            finalizationState = .failed("Could not finish saving this session.")
            snapshot = snap
            return session
        }
        finalizedSessionIDs.insert(session.id)
        if !sessionRepository.deleteActive(accountID: accountID) {
            Logger.session.error("Could not remove finalized active snapshot; recovery will deduplicate it")
        }
        reset()
        if !wasAlreadyFinalized { onSessionEnded?(session) }
        return session
    }

    private func reset() {
        snapshot = nil
        clock = nil
        catchEngine = nil
        thresholdBankedSessionIDs.removeAll()
        pendingFinalizationSnapshot = nil
        pendingRestorationSnapshot = nil
        isDistractionActive = false
        finalizationState = .idle
        stopTicking()
        stopCatchTimer(discardInFlight: false)
    }

    private static func validBundleIDs(_ ids: Set<String>) -> Set<String> {
        Set(ids.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
    }
}
