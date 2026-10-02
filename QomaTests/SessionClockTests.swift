import Foundation
import Testing
@testable import Qoma

struct SessionClockTests {
    @Test
    func remainingCountsDown() {
        let start = Date()
        let clock = SessionClock(plannedMinutes: 10, startTime: start) { start.addingTimeInterval(30) }
        #expect(clock.remaining == 600 - 30)
    }

    @Test
    func activeSecondsExcludesPause() {
        let start = Date()
        var current = start
        let clock = SessionClock(plannedMinutes: 10, startTime: start) { current }

        current = start.addingTimeInterval(120)
        clock.pause()

        current = start.addingTimeInterval(300)
        #expect(clock.activeSeconds == 120)

        clock.resume()
        current = start.addingTimeInterval(420)
        #expect(clock.activeSeconds == 240)
    }

    @Test
    func deadlineDoesNotDriftWhenPaused() {
        let start = Date()
        var current = start
        let clock = SessionClock(plannedMinutes: 10, startTime: start) { current }

        current = start.addingTimeInterval(120)
        clock.pause()
        current = start.addingTimeInterval(300)
        clock.resume()

        #expect(clock.remaining == 600 - 120)
    }

    @Test
    func isDueAfterDeadline() {
        let start = Date()
        let clock = SessionClock(plannedMinutes: 1, startTime: start) { start.addingTimeInterval(61) }
        #expect(clock.isDue)
    }

    @Test
    func zeroRemainingWhenPastDeadline() {
        let start = Date()
        let clock = SessionClock(plannedMinutes: 1, startTime: start) { start.addingTimeInterval(120) }
        #expect(clock.remaining == 0)
    }
}
