import Foundation
import Testing
@testable import Qoma

struct CatchEngineTests {
    @Test
    func depositBeforeBankThresholdIsProvisional() {
        let engine = CatchEngine(rollKind: { "trout" }, biteWait: { 1 }, reelTime: { 1 })
        engine.scheduleNextBite()
        engine.beginReel()
        let result = engine.deposit(sessionID: UUID(), accountID: "a", activeSeconds: 299)
        #expect(result?.banked == false)
        #expect(result?.event.kindID == "trout")
        #expect(result?.event.isBanked == false)
    }

    @Test
    func depositAtBankThresholdIsBanked() {
        let engine = CatchEngine(rollKind: { "salmon" }, biteWait: { 1 }, reelTime: { 1 })
        engine.scheduleNextBite()
        engine.beginReel()
        let result = engine.deposit(sessionID: UUID(), accountID: "a", activeSeconds: 300)
        #expect(result?.banked == true)
        #expect(result?.event.isBanked == true)
    }

    @Test
    func cancelInFlightBeforeDepositProducesNoEvent() {
        let engine = CatchEngine(rollKind: { "salmon" }, biteWait: { 1 }, reelTime: { 1 })
        engine.scheduleNextBite()
        engine.beginReel()
        engine.cancelInFlight()
        let result = engine.deposit(sessionID: UUID(), accountID: "a", activeSeconds: 300)
        #expect(result == nil)
    }

    @Test
    func identityRolledWhenReelingBegins() {
        let engine = CatchEngine(rollKind: { "narwhal" }, biteWait: { 1 }, reelTime: { 1 })
        engine.scheduleNextBite()
        let reel = engine.beginReel()
        #expect(reel.kindID == "narwhal")
    }
}
