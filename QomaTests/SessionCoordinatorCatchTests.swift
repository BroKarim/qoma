import Foundation
import Testing
@testable import Qoma

@MainActor
struct SessionCoordinatorCatchTests {
    private func makeCoordinator(
        accountID: String = "test",
        now: @escaping () -> Date = Date.init,
        autoCatchEnabled: Bool = false
    ) -> SessionCoordinator {
        SessionCoordinator(
            accountID: accountID,
            sessionRepository: SessionRepository.shared,
            catchRepository: CatchRepository.shared,
            canStartSession: { true },
            now: now,
            autoCatchEnabled: autoCatchEnabled
        )
    }

    @Test
    func depositedCatchBelowThresholdIsProvisional() {
        let accountID = UUID().uuidString
        let coordinator = makeCoordinator(accountID: accountID)
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10, policy: .timerOnly))
        coordinator.scheduleNextBite()
        coordinator.beginReel()
        let result = coordinator.depositCatch()

        #expect(result != nil)
        #expect(result?.banked == false)
        #expect(CatchRepository.shared.listBanked(accountID: accountID).isEmpty)
        #expect(!CatchRepository.shared.listProvisional(sessionID: result!.event.sessionID, accountID: accountID).isEmpty)
    }

    @Test
    func depositedCatchAtThresholdIsBanked() {
        let accountID = UUID().uuidString
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(accountID: accountID, now: { current })
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10, policy: .timerOnly))

        current = start.addingTimeInterval(300)
        coordinator.scheduleNextBite()
        coordinator.beginReel()
        let result = coordinator.depositCatch()

        #expect(result?.banked == true)
        #expect(CatchRepository.shared.listBanked(accountID: accountID).count == 1)
    }

    @Test
    func distractionDoesNotCancelInFlightCatch() {
        let accountID = UUID().uuidString
        let coordinator = makeCoordinator(accountID: accountID)
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10, policy: .timerOnly))
        coordinator.scheduleNextBite()
        coordinator.beginReel()
        coordinator.setDistractionActive(true)
        let result = coordinator.depositCatch()

        #expect(result != nil)
    }

    @Test
    func stopAfterThresholdKeepsBankedCatches() {
        let accountID = UUID().uuidString
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(accountID: accountID, now: { current })
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10, policy: .timerOnly))

        current = start.addingTimeInterval(300)
        coordinator.scheduleNextBite()
        coordinator.beginReel()
        _ = coordinator.depositCatch()

        let session = coordinator.stopSession()
        #expect(session?.status == .interrupted)
        #expect(CatchRepository.shared.listBanked(accountID: accountID).count == 1)
    }

    @Test
    func sessionEndCallbackReceivesCompletedSession() {
        let accountID = UUID().uuidString
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(accountID: accountID, now: { current })
        var endedSession: FocusSession?
        coordinator.onSessionEnded = { endedSession = $0 }

        coordinator.startSession(draft: SessionDraft(plannedMinutes: 1, policy: .timerOnly))
        current = start.addingTimeInterval(61)
        _ = coordinator.completeIfDue()

        #expect(endedSession != nil)
        #expect(endedSession?.status == .completed)
    }
}
