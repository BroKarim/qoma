import Foundation
import Testing
@testable import Qoma

@MainActor
struct SessionCoordinatorTests {
    private func makeCoordinator(accountID: String = "test", now: @escaping () -> Date = Date.init) -> SessionCoordinator {
        SessionCoordinator(
            accountID: accountID,
            sessionRepository: SessionRepository.shared,
            catchRepository: CatchRepository.shared,
            canStartSession: { true },
            now: now
        )
    }

    @Test
    func startSessionCreatesActiveSnapshot() {
        let coordinator = makeCoordinator()
        let draft = SessionDraft(taskTitle: "Write tests", plannedMinutes: 10, policy: .timerOnly)
        let snapshot = coordinator.startSession(draft: draft)
        #expect(snapshot != nil)
        #expect(coordinator.isActive == true)
        #expect(coordinator.currentTaskTitle == "Write tests")
    }

    @Test
    func pauseAndResumeUpdatesSnapshot() {
        let coordinator = makeCoordinator()
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10, policy: .timerOnly))
        coordinator.pauseSession()
        #expect(coordinator.isPaused == true)
        coordinator.resumeSession()
        #expect(coordinator.isActive == true)
    }

    @Test
    func stopBeforeFiveMinutesDiscardsProvisionalCatch() {
        let accountID = UUID().uuidString
        let coordinator = makeCoordinator(accountID: accountID)
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 10, policy: .timerOnly))
        coordinator.scheduleNextBite()
        coordinator.beginReel()
        _ = coordinator.depositCatch()

        let session = coordinator.stopSession()
        #expect(session?.status == .interrupted)
        #expect(CatchRepository.shared.listBanked(accountID: accountID).isEmpty)
    }

    @Test
    func completedSessionFinalizesOnce() {
        let accountID = UUID().uuidString
        let start = Date()
        var current = start
        let coordinator = makeCoordinator(accountID: accountID) { current }
        coordinator.startSession(draft: SessionDraft(plannedMinutes: 1, policy: .timerOnly))

        current = start.addingTimeInterval(61)
        let first = coordinator.completeIfDue()
        let second = coordinator.completeIfDue()

        #expect(first != nil)
        #expect(second == nil)
        #expect(first?.status == .completed)
        #expect(SessionRepository.shared.loadActive(accountID: accountID) == nil)
    }

    @Test
    func restoreLoadsActiveSnapshot() {
        let accountID = UUID().uuidString
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
        SessionRepository.shared.saveActive(snapshot)

        let coordinator = makeCoordinator(accountID: accountID) { start.addingTimeInterval(30) }
        coordinator.restore()

        #expect(coordinator.isActive == true)
        #expect(SessionRepository.shared.loadActive(accountID: accountID)?.id == snapshot.id)
    }

    @Test
    func restoreDueSessionCompletes() {
        let accountID = UUID().uuidString
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
        SessionRepository.shared.saveActive(snapshot)

        let coordinator = makeCoordinator(accountID: accountID) { start.addingTimeInterval(120) }
        coordinator.restore()

        #expect(coordinator.isActive == false)
        #expect(SessionRepository.shared.loadActive(accountID: accountID) == nil)
    }
}
