import Testing
@testable import Qoma

struct CoveVisitorScheduleTests {
    @Test func visitsWaitForIdleFishingAndFreezeDuringPause() {
        var schedule = CoveVisitorSchedule(interval: { 1 })
        schedule.advance(by: 2, active: true, canArrive: false)
        #expect(schedule.kind == nil)
        schedule.advance(by: 1, active: false, canArrive: true)
        #expect(schedule.kind == nil)
        schedule.advance(by: 0.1, active: true, canArrive: true)
        #expect(schedule.kind != nil)
        schedule.advance(by: 5, active: false, canArrive: true)
        #expect(schedule.elapsed == 0)
        schedule.advance(by: 21, active: true, canArrive: true)
        #expect(schedule.kind == nil)
    }
}
