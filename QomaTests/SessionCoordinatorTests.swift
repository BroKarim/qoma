import Foundation
import Testing
@testable import Qoma

@MainActor
struct SessionCoordinatorTests {
    private final class FailingSessionRepository: SessionRepositoryProtocol, @unchecked Sendable {
        let base: SessionRepository
        var failNextSave = false

        init(base: SessionRepository) {
            self.base = base
        }

        func loadActive(accountID: String) -> ActiveSessionSnapshot? { base.loadActive(accountID: accountID) }
        func saveActive(_ snapshot: ActiveSessionSnapshot) -> Bool {
            if failNextSave {
                failNextSave = false
                return false
            }
            return base.saveActive(snapshot)
        }
        func deleteActive(accountID: String) -> Bool { base.deleteActive(accountID: accountID) }
        func finalizeOnce(_ session: FocusSession) -> Bool { base.finalizeOnce(session) }
        func loadHistory(accountID: String) -> [FocusSession] { base.loadHistory(accountID: accountID) }
    }

    private struct Repositories {
        let sessions: SessionRepository
        let catches: CatchRepository
        let directory: URL
    }

    private func makeRepositories() -> Repositories {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return Repositories(
            sessions: SessionRepository(storageDirectory: directory.appendingPathComponent("sessions")),
            catches: CatchRepository(storageDirectory: directory.appendingPathComponent("catches")),
            directory: directory
        )
    }

    private func cleanup(_ repositories: Repositories) {
        try? FileManager.default.removeItem(at: repositories.directory)
    }

    private func makeCoordinator(
        accountID: String = "test",
        repositories: Repositories,
        now: @escaping () -> Date = Date.init
    ) -> SessionCoordinator {
        SessionCoordinator(
            accountID: accountID,
            sessionRepository: repositories.sessions,
            catchRepository: repositories.catches,
            canStartSession: { true },
            now: now,
            autoCatchEnabled: false
        )
    }

    @Test
    func legacyHistoryDoesNotBlockRecoveryOrStartingNextSession() throws {
        let repositories = makeRepositories()
        defer { cleanup(repositories) }
        let start = Date()
        let legacy = FocusSession(
            accountID: "test", startedAt: start, endedAt: start,
            plannedMinutes: 10, actualActiveSeconds: 60, status: .completed,
            draftSnapshot: SessionDraft(plannedMinutes: 10), taskTitle: "Legacy session"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        var records = try JSONSerialization.jsonObject(with: encoder.encode([legacy])) as! [[String: Any]]
        var draft = records[0]["draftSnapshot"] as! [String: Any]
        draft.removeValue(forKey: "domainBrowserBundleID")
        records[0]["draftSnapshot"] = draft
        try JSONSerialization.data(withJSONObject: records).write(
            to: repositories.directory.appendingPathComponent("sessions/history-test.json")
        )
        let terminal = ActiveSessionSnapshot(
            accountID: "test", startedAt: start, deadline: start,
            accumulatedActiveSeconds: 30, draft: SessionDraft(plannedMinutes: 10),
            status: .interrupted, endedAt: start
        )
        #expect(repositories.sessions.saveActive(terminal))
        let coordinator = makeCoordinator(repositories: repositories)
        coordinator.restore()
        #expect(coordinator.snapshot == nil)
        let history = repositories.sessions.loadHistory(accountID: "test")
        #expect(history.count == 2)
        #expect(history.first?.id == legacy.id)
        #expect(history.first?.draftSnapshot.domainBrowserBundleID == "com.apple.Safari")
        #expect(coordinator.startSession(draft: SessionDraft())?.status == .active)
    }

    @Test
    func startSessionCreatesActiveSnapshot() {
        let repositories = makeRepositories()
        let coordinator = makeCoordinator(repositories: repositories)
        let draft = SessionDraft(taskTitle: "Write tests", plannedMinutes: 10, policy: .timerOnly)
        let snapshot = coordinator.startSession(draft: draft)
        #expect(snapshot != nil)
        #expect(coordinator.isActive == true)
        #expect(coordinator.currentTaskTitle == "Write tests")
        cleanup(repositories)
    }

    @Test
    func pauseAndResumeUpdatesSnapshot() {
        let repositories = makeRepositories()
        let coordinator = makeCoordinator(repositories: repositories)
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10, policy: .timerOnly))
        coordinator.pauseSession()
        #expect(coordinator.isPaused == true)
        coordinator.resumeSession()
        #expect(coordinator.isActive == true)
        cleanup(repositories)
    }

    @Test
    func allowingRequiresAnAppAndLiveUpdateKeepsSessionIdentity() {
        let repositories = makeRepositories()
        defer { cleanup(repositories) }
        let coordinator = makeCoordinator(repositories: repositories)
        #expect(coordinator.startSession(draft: SessionDraft(policy: SessionPolicy(mode: .allowing))) == nil)

        var policy = SessionPolicy(mode: .allowing)
        policy.allowedApps = ["com.example.Editor"]
        policy.blockedApps = ["com.example.Distraction"]
        let started = coordinator.startSession(draft: SessionDraft(policy: policy))
        #expect(started != nil)
        #expect(coordinator.updateAppRules(
            allowedApps: ["com.example.Editor", "com.example.Browser"],
            blockedApps: []))
        #expect(coordinator.snapshot?.id == started?.id)
        #expect(coordinator.snapshot?.draft.policy.allowedApps.contains("com.example.Browser") == true)
        #expect(coordinator.snapshot?.draft.policy.blockedApps == ["com.example.Distraction"])
        #expect(coordinator.updateAppRules(allowedApps: [], blockedApps: []) == false)
    }

    @Test
    func resetEndsSessionAndNextStartUsesNewIdentity() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories) { current }
        let first = coordinator.startSession(draft: SessionDraft(plannedMinutes: 1))!
        current = start.addingTimeInterval(30)
        #expect(coordinator.resetSession())
        #expect(coordinator.snapshot == nil)
        #expect(repositories.sessions.loadHistory(accountID: accountID).first?.id == first.id)
        let second = coordinator.startSession(draft: SessionDraft(plannedMinutes: 1))
        #expect(second?.id != first.id)
        #expect(second?.accumulatedActiveSeconds == 0)
        #expect(repositories.sessions.loadHistory(accountID: accountID).count == 1)
        cleanup(repositories)
    }

    @Test
    func resetFromPauseEndsSessionWithoutResuming() {
        let repositories = makeRepositories()
        defer { cleanup(repositories) }
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(repositories: repositories) { current }
        let first = coordinator.startSession(draft: SessionDraft(plannedMinutes: 25))!
        current = start.addingTimeInterval(40)
        coordinator.pauseSession()
        current = start.addingTimeInterval(100)
        #expect(coordinator.resetSession())
        #expect(coordinator.snapshot == nil)
        let ended = repositories.sessions.loadHistory(accountID: "test").first
        #expect(ended?.id == first.id)
        #expect(ended?.actualActiveSeconds == 40)
    }

    @Test
    func failedResetCanRetryWithoutAddingActiveTime() {
        let repositories = makeRepositories()
        defer { cleanup(repositories) }
        let sessionRepository = FailingSessionRepository(base: repositories.sessions)
        let start = Date()
        var current = start
        let coordinator = SessionCoordinator(
            accountID: "test",
            sessionRepository: sessionRepository,
            catchRepository: repositories.catches,
            now: { current },
            autoCatchEnabled: false
        )
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10))
        current = start.addingTimeInterval(30)
        sessionRepository.failNextSave = true

        #expect(coordinator.resetSession() == false)
        #expect(coordinator.finalizationState == .failed("Could not save this session."))
        current = start.addingTimeInterval(180)
        coordinator.retryFinalization()

        #expect(coordinator.snapshot == nil)
        #expect(repositories.sessions.loadHistory(accountID: "test").first?.actualActiveSeconds == 30)
    }

    @Test
    func failedLiveRuleSaveDoesNotPublishCandidate() {
        let repositories = makeRepositories()
        defer { cleanup(repositories) }
        let sessionRepository = FailingSessionRepository(base: repositories.sessions)
        var policy = SessionPolicy(mode: .allowing)
        policy.allowedApps = ["com.example.Editor"]
        let coordinator = SessionCoordinator(
            accountID: "test",
            sessionRepository: sessionRepository,
            catchRepository: repositories.catches,
            autoCatchEnabled: false
        )
        coordinator.startSession(draft: SessionDraft(policy: policy))
        sessionRepository.failNextSave = true

        #expect(coordinator.updateAppRules(
            allowedApps: ["com.example.Editor", "com.example.Browser"],
            blockedApps: []
        ) == false)
        #expect(coordinator.snapshot?.draft.policy.allowedApps == ["com.example.Editor"])
    }

    @Test
    func stopBeforeFiveMinutesDiscardsProvisionalCatch() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories)
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10, policy: .timerOnly))
        coordinator.scheduleNextBite()
        coordinator.beginReel()
        _ = coordinator.depositCatch()

        let session = coordinator.stopSession()
        #expect(session?.status == .interrupted)
        #expect(repositories.catches.listBanked(accountID: accountID).isEmpty)
        #expect(repositories.catches.listProvisional(sessionID: session!.id, accountID: accountID).isEmpty)
        cleanup(repositories)
    }

    @Test
    func completedSessionFinalizesOnce() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories) { current }
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 1, policy: .timerOnly))

        current = start.addingTimeInterval(61)
        let first = coordinator.completeIfDue()
        let second = coordinator.completeIfDue()

        #expect(first != nil)
        #expect(second == nil)
        #expect(first?.status == .completed)
        #expect(repositories.sessions.loadActive(accountID: accountID) == nil)
        cleanup(repositories)
    }

    @Test
    func stopAfterDeadlineRecordsCompletion() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories) { current }
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 1))
        current = start.addingTimeInterval(61)

        let result = coordinator.stopSession()
        #expect(result?.status == .completed)
        #expect(result?.actualActiveSeconds == 60)
        cleanup(repositories)
    }

    @Test
    func restoreLoadsActiveSnapshot() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let start = Date()
        let draft = SessionDraft(plannedMinutes: 10, policy: .timerOnly)
        let snapshot = ActiveSessionSnapshot(
            id: UUID(),
            accountID: accountID,
            startedAt: start,
            deadline: start.addingTimeInterval(600),
            pausedAt: nil,
            accumulatedActiveSeconds: 0,
            draft: draft,
            status: .active
        )
        #expect(repositories.sessions.saveActive(snapshot))

        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories) { start.addingTimeInterval(30) }
        coordinator.restore()

        #expect(coordinator.isActive == true)
        #expect(repositories.sessions.loadActive(accountID: accountID)?.id == snapshot.id)
        cleanup(repositories)
    }

    @Test
    func restoreDueSessionCompletes() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let start = Date()
        let draft = SessionDraft(plannedMinutes: 1, policy: .timerOnly)
        let snapshot = ActiveSessionSnapshot(
            id: UUID(),
            accountID: accountID,
            startedAt: start,
            deadline: start.addingTimeInterval(60),
            pausedAt: nil,
            accumulatedActiveSeconds: 0,
            draft: draft,
            status: .active
        )
        #expect(repositories.sessions.saveActive(snapshot))

        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories) { start.addingTimeInterval(120) }
        coordinator.restore()

        #expect(coordinator.isActive == false)
        #expect(repositories.sessions.loadActive(accountID: accountID) == nil)
        cleanup(repositories)
    }

    @Test
    func stopPersistsTerminalSnapshotWhenHistoryWriteFailsAndRestoresItLater() {
        let accountID = UUID().uuidString
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let repository = SessionRepository(
            storageDirectory: directory.appendingPathComponent("sessions"),
            historyDirectoryURL: directory.appendingPathComponent("missing-history-parent")
        )
        let catches = CatchRepository(storageDirectory: directory.appendingPathComponent("catches"))
        let coordinator = SessionCoordinator(
            accountID: accountID,
            sessionRepository: repository,
            catchRepository: catches,
            now: Date.init,
            autoCatchEnabled: false
        )
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10))

        let session = coordinator.stopSession(reason: "test")
        #expect(session?.status == .interrupted)
        #expect(repository.loadActive(accountID: accountID)?.status == .interrupted)
        try? FileManager.default.createDirectory(at: directory.appendingPathComponent("missing-history-parent"), withIntermediateDirectories: true)
        let restoredCoordinator = SessionCoordinator(
            accountID: accountID,
            sessionRepository: repository,
            catchRepository: catches,
            autoCatchEnabled: false
        )
        restoredCoordinator.restore()
        #expect(repository.loadActive(accountID: accountID) == nil)
        #expect(repository.loadHistory(accountID: accountID).count == 1)
        try? FileManager.default.removeItem(at: directory)
    }
}
