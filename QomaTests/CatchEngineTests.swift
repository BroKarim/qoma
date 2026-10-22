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

    @Test
    func approvedCatalogAndPityBoundariesAreUsed() {
        #expect(CatalogDefinitions.allKinds.count == 150)
        #expect(CatchRarityRules.baseOdds == [
            .common: 0.701, .uncommon: 0.24, .rare: 0.055, .legendary: 0.004
        ])
        #expect(CatchRarityRules.intervalSeconds == 50...70)
        #expect(CatalogDefinitions.Rarity.allCases.map { rarity in
            CatalogDefinitions.allKinds.filter { $0.rarity == rarity }.count
        } == [60, 36, 24, 30])
        #expect(CatchRarityRules.pityBoost(30, start: 30, hard: 60) == 0)
        #expect(CatchRarityRules.pityBoost(59, start: 30, hard: 60) == 1)

        let hardLegendary = CatchRarityRules.roll(
            pity: CatchPityState(rarePlusCount: 0, legendaryCount: 439),
            using: { 0 }
        )
        #expect(CatalogDefinitions.kind(id: hardLegendary)?.rarity == .legendary)

        let engine = CatchEngine()
        let wait = engine.scheduleNextBite()
        #expect((50...70).contains(wait + engine.currentReelDuration))
    }
}
