import Foundation

struct CatchPityState: Codable, Equatable, Sendable {
    var rarePlusCount = 0
    var legendaryCount = 0

    mutating func record(_ rarity: CatalogDefinitions.Rarity) {
        switch rarity {
        case .common, .uncommon:
            rarePlusCount += 1
            legendaryCount += 1
        case .rare:
            rarePlusCount = 0
            legendaryCount += 1
        case .legendary:
            rarePlusCount = 0
            legendaryCount = 0
        }
    }
}

struct CatchCycleState: Codable, Equatable, Sendable {
    var sessionID: UUID?
    var sessionActiveSeconds = 0.0
    var remainingUntilBite: TimeInterval?
    var reelDuration: TimeInterval?
    var pendingKindID: String?
    var pendingEventID: UUID?
    var remainingReel: TimeInterval?
}

struct CatchAccountProgress: Codable, Equatable, Sendable {
    var pity = CatchPityState()
    var cycle = CatchCycleState()
}

enum CatchRarityRules {
    struct Config: Decodable, Sendable {
        struct Threshold: Decodable, Sendable {
            let start: Int
            let hard: Int
        }

        struct Pity: Decodable, Sendable {
            let rarePlus: Threshold
            let legendary: Threshold
        }

        struct Interval: Decodable, Sendable {
            let min: Double
            let max: Double
        }

        struct ItemWeights: Decodable, Sendable {
            let cycle: [Double]
            let legendaryStart: Double
            let legendaryStep: Double
        }

        let version: Int
        let intervalSeconds: Interval
        let baseOdds: [CatalogDefinitions.Rarity: Double]
        let pity: Pity
        let itemCounts: [CatalogDefinitions.Rarity: Int]
        let itemWeights: ItemWeights
    }

    private final class BundleToken: NSObject {}

    static let config: Config = {
        guard let url = Bundle(for: BundleToken.self).url(forResource: "rarity-config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(Config.self, from: data),
              config.version == 1 else {
            preconditionFailure("Could not load the bundled rarity configuration")
        }
        return config
    }()

    static var baseOdds: [CatalogDefinitions.Rarity: Double] { config.baseOdds }
    static var rarePlusPity: (start: Int, hard: Int) { (config.pity.rarePlus.start, config.pity.rarePlus.hard) }
    static var legendaryPity: (start: Int, hard: Int) { (config.pity.legendary.start, config.pity.legendary.hard) }
    static var intervalSeconds: ClosedRange<Double> { config.intervalSeconds.min...config.intervalSeconds.max }

    static func itemWeight(for rarity: CatalogDefinitions.Rarity, index: Int) -> Double {
        if rarity == .legendary {
            return config.itemWeights.legendaryStart + Double(index) * config.itemWeights.legendaryStep
        }
        let cycle = config.itemWeights.cycle
        return cycle[index % cycle.count]
    }

    static var helpOddsText: String {
        CatalogDefinitions.Rarity.allCases.map { rarity in
            "\(rarity.displayName) \(String(format: "%.1f%%", baseOdds[rarity, default: 0] * 100))"
        }.joined(separator: " · ")
    }

    static func pityBoost(_ count: Int, start: Int, hard: Int) -> Double {
        if count >= hard - 1 { return 1 }
        if count < start { return 0 }
        return Double(count - start) / Double(hard - start)
    }

    static func probabilities(for state: CatchPityState) -> [CatalogDefinitions.Rarity: Double] {
        let baseRare = baseOdds[.rare]!
        let baseLegendary = baseOdds[.legendary]!
        let baseRarePlus = baseRare + baseLegendary
        let rarePlusBoost = pityBoost(state.rarePlusCount, start: rarePlusPity.start, hard: rarePlusPity.hard)
        let legendaryBoost = pityBoost(state.legendaryCount, start: legendaryPity.start, hard: legendaryPity.hard)

        let legendary = legendaryBoost == 1
            ? 1
            : min(1 - baseRare, baseLegendary + (1 - baseLegendary) * legendaryBoost)
        let rarePlus = max(
            baseRare + legendary,
            baseRarePlus + (1 - baseRarePlus) * rarePlusBoost
        )
        let rare = rarePlus - legendary
        let commonUncommon = max(0, 1 - rarePlus)
        let commonBase = baseOdds[.common]!
        let uncommonBase = baseOdds[.uncommon]!
        let common = commonUncommon * commonBase / (commonBase + uncommonBase)
        let uncommon = commonUncommon - common
        return [.common: common, .uncommon: uncommon, .rare: rare, .legendary: legendary]
    }

    static func roll(pity: CatchPityState, using random: () -> Double = { Double.random(in: 0..<1) }) -> String {
        let odds = probabilities(for: pity)
        let roll = random()
        var edge = 0.0
        let rarity = CatalogDefinitions.Rarity.allCases.first { tier in
            edge += odds[tier, default: 0]
            return roll < edge
        } ?? .legendary
        let items = CatalogDefinitions.allKinds.filter { $0.rarity == rarity }
        let totalWeight = items.reduce(0) { $0 + $1.weight }
        let itemRoll = random() * totalWeight
        var itemEdge = 0.0
        return items.first { item in
            itemEdge += item.weight
            return itemRoll < itemEdge
        }?.id ?? items[0].id
    }

    static func record(_ kindID: String, into state: inout CatchPityState) {
        guard let rarity = CatalogDefinitions.kind(id: kindID)?.rarity else { return }
        state.record(rarity)
    }
}
