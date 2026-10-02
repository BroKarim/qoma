import Foundation

/// Static catalog definitions. Images are referenced by kindID.
enum CatalogDefinitions {
    struct Kind: Equatable, Sendable {
        let id: String
        let name: String
        let rarity: Rarity
        let isFish: Bool
    }

    enum Rarity: String, Codable, Sendable {
        case common
        case uncommon
        case rare
        case legendary
    }

    static let allKinds: [Kind] = [
        Kind(id: "anchovy", name: "Anchovy", rarity: .common, isFish: true),
        Kind(id: "perch", name: "Perch", rarity: .common, isFish: true),
        Kind(id: "trout", name: "Trout", rarity: .uncommon, isFish: true),
        Kind(id: "salmon", name: "Salmon", rarity: .rare, isFish: true),
        Kind(id: "narwhal", name: "Narwhal", rarity: .legendary, isFish: true),
        Kind(id: "stick", name: "Driftwood Stick", rarity: .common, isFish: false),
        Kind(id: "pebble", name: "Smooth Pebble", rarity: .common, isFish: false),
        Kind(id: "shell", name: "Seashell", rarity: .uncommon, isFish: false),
    ]

    static let starterDiscoveredKinds: Set<String> = ["anchovy", "stick"]

    static func kind(id: String) -> Kind? {
        allKinds.first { $0.id == id }
    }
}
