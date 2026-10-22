import Foundation

/// Catalog IDs are stable because catch events persist them directly.
enum CatalogDefinitions {
    struct Kind: Equatable, Sendable {
        let id: String
        let name: String
        let rarity: Rarity
        let isFish: Bool
        let weight: Double
    }

    enum Rarity: String, Codable, CaseIterable, Sendable {
        case common
        case uncommon
        case rare
        case legendary
    }

    static let counts = CatchRarityRules.config.itemCounts

    // shortcut: generated entries use numbered names and shared fish art, replace when the species manifest is approved.
    static let allKinds: [Kind] = Rarity.allCases.flatMap { rarity in
        (0..<(counts[rarity] ?? 0)).map { index in
            let legacy = legacyKinds[rarity].flatMap { kinds in
                kinds.indices.contains(index) ? kinds[index] : nil
            }
            let id = legacy?.id ?? "\(rarity.rawValue)-\(String(format: "%02d", index + 1))"
            return Kind(
                id: id,
                name: legacy?.name ?? "\(rarity.displayName) \(String(format: "%02d", index + 1))",
                rarity: rarity,
                isFish: legacy?.isFish ?? true,
                weight: CatchRarityRules.itemWeight(for: rarity, index: index)
            )
        }
    }

    private static let legacyKinds: [Rarity: [(id: String, name: String, isFish: Bool)]] = [
        .common: [
            ("anchovy", "Anchovy", true), ("perch", "Perch", true),
            ("stick", "Driftwood Stick", false), ("pebble", "Smooth Pebble", false)
        ],
        .uncommon: [("trout", "Trout", true), ("shell", "Seashell", false)],
        .rare: [("salmon", "Salmon", true)],
        .legendary: [("narwhal", "Narwhal", true)]
    ]

    static func kind(id: String) -> Kind? {
        allKinds.first { $0.id == id }
    }
}

extension CatalogDefinitions.Rarity {
    var displayName: String {
        switch self {
        case .common: "Common"
        case .uncommon: "Uncommon"
        case .rare: "Rare"
        case .legendary: "Legendary"
        }
    }
}
