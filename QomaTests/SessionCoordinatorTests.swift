import Foundation
import Testing
@testable import Qoma

@MainActor
struct SessionCoordinatorTests {
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
    func restartKeepsSessionIdentityAndCumulativeTimeAfterRestore() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories) { current }
        let first = coordinator.startSession(draft: SessionDraft(plannedMinutes: 1))!
        current = start.addingTimeInterval(30)
        #expect(coordinator.restartSession())
        #expect(coordinator.snapshot?.id == first.id)
        #expect(coordinator.snapshot?.accumulatedActiveSeconds == 30)
        #expect(coordinator.remainingTime == 60)

        let restored = makeCoordinator(accountID: accountID, repositories: repositories) { current }
        restored.restore()
        current = start.addingTimeInterval(91)
        let completed = restored.completeIfDue()
        #expect(completed?.id == first.id)
        #expect(completed?.actualActiveSeconds == 90)
        #expect(repositories.sessions.loadHistory(accountID: accountID).count == 1)
        cleanup(repositories)
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
