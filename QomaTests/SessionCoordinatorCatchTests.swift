import Foundation
import Testing
@testable import Qoma

@MainActor
struct SessionCoordinatorCatchTests {
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
        now: @escaping () -> Date = Date.init,
        autoCatchEnabled: Bool = false
    ) -> SessionCoordinator {
        SessionCoordinator(
            accountID: accountID,
            sessionRepository: repositories.sessions,
            catchRepository: repositories.catches,
            canStartSession: { true },
            now: now,
            autoCatchEnabled: autoCatchEnabled
        )
    }

    @Test
    func depositedCatchBelowThresholdIsProvisional() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories)
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10, policy: .timerOnly))
        coordinator.scheduleNextBite()
        coordinator.beginReel()
        let result = coordinator.depositCatch()

        #expect(result != nil)
        #expect(result?.banked == false)
        #expect(repositories.catches.listBanked(accountID: accountID).isEmpty)
        #expect(!repositories.catches.listProvisional(sessionID: result!.event.sessionID, accountID: accountID).isEmpty)
        cleanup(repositories)
    }

    @Test
    func depositedCatchAtThresholdIsBanked() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories, now: { current })
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10, policy: .timerOnly))

        current = start.addingTimeInterval(300)
        coordinator.scheduleNextBite()
        coordinator.beginReel()
        let result = coordinator.depositCatch()

        #expect(result?.banked == true)
        #expect(repositories.catches.listBanked(accountID: accountID).count == 1)
        cleanup(repositories)
    }

    @Test
    func distractionDoesNotCancelInFlightCatch() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories)
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10, policy: .timerOnly))
        coordinator.scheduleNextBite()
        coordinator.beginReel()
        coordinator.setDistractionActive(true)
        let result = coordinator.depositCatch()

        #expect(result != nil)
        cleanup(repositories)
    }

    @Test
    func stopAfterThresholdKeepsBankedCatches() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories, now: { current })
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10, policy: .timerOnly))

        current = start.addingTimeInterval(300)
        coordinator.scheduleNextBite()
        coordinator.beginReel()
        _ = coordinator.depositCatch()

        let session = coordinator.stopSession()
        #expect(session?.status == .interrupted)
        #expect(repositories.catches.listBanked(accountID: accountID).count == 1)
        cleanup(repositories)
    }

    @Test
    func resetBeforeThresholdDiscardsProvisionalCatch() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories, now: { current })
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10))
        current = start.addingTimeInterval(240)
        coordinator.scheduleNextBite()
        coordinator.beginReel()
        let catchEvent = coordinator.depositCatch()!.event
        #expect(!catchEvent.isBanked)

        #expect(coordinator.resetSession())
        #expect(repositories.catches.listProvisional(sessionID: catchEvent.sessionID, accountID: accountID).isEmpty)
        #expect(repositories.catches.listBanked(accountID: accountID).isEmpty)
        #expect(repositories.sessions.loadHistory(accountID: accountID).count == 1)
        cleanup(repositories)
    }

    @Test
    func sessionEndCallbackReceivesCompletedSession() {
        let accountID = UUID().uuidString
        let repositories = makeRepositories()
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(accountID: accountID, repositories: repositories, now: { current })
        var endedSession: FocusSession?
        coordinator.onSessionEnded = { endedSession = $0 }

        coordinator.startSession(draft: SessionDraft(plannedMinutes: 1, policy: .timerOnly))
        current = start.addingTimeInterval(61)
        _ = coordinator.completeIfDue()

        #expect(endedSession != nil)
        #expect(endedSession?.status == .completed)
        cleanup(repositories)
    }
}
