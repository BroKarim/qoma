import Foundation

/// Catalog IDs are stable because catch events persist them directly.
enum CatalogDefinitions {
    struct Kind: Equatable, Sendable {
        let id: String
        let name: String
        let rarity: Rarity
        let isFish: Bool
        let weight: Double
        let artworkID: String?
    }

    enum Rarity: String, Codable, CaseIterable, Sendable {
        case common
        case uncommon
        case rare
        case legendary
    }

    /// Keeps old generated IDs readable in saved catch history; only `allKinds` is collectible.
    static let knownKinds: [Kind] = Rarity.allCases.flatMap { rarity in
        (0..<(historicalSlotCounts[rarity] ?? 0)).map { index in
            let legacy = legacyKinds[rarity].flatMap { kinds in
                kinds.indices.contains(index) ? kinds[index] : nil
            }
            let id = legacy?.id ?? "\(rarity.rawValue)-\(String(format: "%02d", index + 1))"
            let artwork = artworkByKindID[id]
            return Kind(
                id: id,
                name: artwork?.name ?? legacy?.name ?? "\(rarity.displayName) \(String(format: "%02d", index + 1))",
                rarity: rarity,
                isFish: artwork?.isFish ?? legacy?.isFish ?? true,
                weight: CatchRarityRules.itemWeight(for: rarity, index: index),
                artworkID: artwork?.id ?? (directArtworkKindIDs.contains(id) ? id : nil)
            )
        }
    }

    static let allKinds: [Kind] = Rarity.allCases.flatMap { rarity in
        knownKinds.filter { $0.rarity == rarity && $0.artworkID != nil }
            .enumerated()
            .map { index, kind in
                Kind(
                    id: kind.id,
                    name: kind.name,
                    rarity: kind.rarity,
                    isFish: kind.isFish,
                    weight: CatchRarityRules.itemWeight(for: rarity, index: index),
                    artworkID: kind.artworkID
                )
            }
    }

    private static let historicalSlotCounts: [Rarity: Int] = [
        .common: 60, .uncommon: 36, .rare: 24, .legendary: 30
    ]

    private static let legacyKinds: [Rarity: [(id: String, name: String, isFish: Bool)]] = [
        .common: [
            ("anchovy", "Anchovy", true), ("perch", "Perch", true),
            ("stick", "Driftwood Stick", false), ("pebble", "Smooth Pebble", false),
            ("common-sea-pebble", "Sea Pebble", false),
            ("common-clam-shell", "Clam Shell", false),
            ("common-spiral-shell", "Spiral Shell", false),
            ("common-driftwood", "Driftwood", false),
            ("common-shell-shard", "Shell Shard", false),
            ("common-sea-glass", "Sea Glass", false)
        ],
        .uncommon: [("trout", "Trout", true), ("shell", "Seashell", false)],
        .rare: [("salmon", "Salmon", true)],
        .legendary: [("narwhal", "Narwhal", true)]
    ]

    private static let directArtworkKindIDs: Set<String> = [
        "stick", "pebble", "shell", "common-sea-pebble", "common-clam-shell",
        "common-spiral-shell", "common-driftwood", "common-shell-shard", "common-sea-glass"
    ]

    // Artwork IDs can change without invalidating persisted catch IDs.
    private static let artworkByKindID: [String: (name: String, id: String, isFish: Bool)] = [
        "uncommon-03": ("Icefish Sirip Kipas", "uncommon-icefish-fan", true),
        "uncommon-04": ("Toothfish Berbintik", "uncommon-toothfish-mottle", true),
        "uncommon-05": ("Silverfish Pita", "uncommon-silverfish-ribbon", true),
        "uncommon-06": ("Lanternfish Plum", "uncommon-lanternfish-plum", true),
        "uncommon-07": ("Eelpout Melengkung", "uncommon-eelpout-curl", true),
        "uncommon-08": ("Notothen Sirip Lebar", "uncommon-notothen-broadfin", true),
        "uncommon-09": ("Icefish Sirip Layar", "uncommon-icefish-sail", true),
        "uncommon-10": ("Toothfish Berpita", "uncommon-toothfish-banded", true),
        "uncommon-11": ("Silverfish Oval", "uncommon-silverfish-deep", true),
        "uncommon-12": ("Lanternfish Amber", "uncommon-lanternfish-amber", true),
        "uncommon-13": ("Eelpout Lingkar", "uncommon-eelpout-loop", true),
        "uncommon-14": ("Ikan Sirip Kelopak", "uncommon-plunderfish-flowerfin", true),
        "uncommon-15": ("Icefish Sirip Sayap", "uncommon-icefish-wingfin", true),
        "uncommon-16": ("Toothfish Tutul Halus", "uncommon-toothfish-speckled", true),
        "uncommon-17": ("Silverfish Ekor Panjang", "uncommon-silverfish-longtail", true),
        "uncommon-18": ("Lanternfish Batu Tulis", "uncommon-lanternfish-slate", true),
        "uncommon-19": ("Eelpout Gelombang", "uncommon-eelpout-sway", true),
        "uncommon-20": ("Snailfish Batu", "uncommon-snailfish-pebble", true),
        "uncommon-21": ("Icefish Krim", "uncommon-icefish-cream", true),
        "uncommon-22": ("Toothfish Batu", "uncommon-toothfish-stone", true),
        "uncommon-23": ("Silverfish Melengkung", "uncommon-silverfish-arch", true),
        "uncommon-24": ("Lanternfish Tembaga", "uncommon-lanternfish-copper", true),
        "uncommon-25": ("Eelpout Lengkung Ganda", "uncommon-eelpout-knot", true),
        "uncommon-26": ("Ikan Kepala Lebar", "uncommon-dragonfish-blunt", true),
        "uncommon-27": ("Icefish Kelopak", "uncommon-icefish-petal", true),
        "uncommon-28": ("Toothfish Zaitun", "uncommon-toothfish-olive", true),
        "uncommon-29": ("Silverfish Gelendong", "uncommon-silverfish-spindle", true),
        "uncommon-30": ("Lanternfish Indigo", "uncommon-lanternfish-indigo", true),
        "uncommon-31": ("Eelpout Sabit", "uncommon-eelpout-crescent", true),
        "uncommon-32": ("Ikan Ekor Pita", "uncommon-rattail-taper", true),
        "uncommon-33": ("Icefish Rumbai", "uncommon-icefish-frill", true),
        "uncommon-34": ("Toothfish Ekor Dayung", "uncommon-toothfish-paddle", true),
        "uncommon-35": ("Eelpout Ekor Kipas", "uncommon-eelpout-fan", true),
        "uncommon-36": ("Skate Layang", "uncommon-skate-kite", true),
        "rare-02": ("Golden Icefish", "rare-golden-icefish", true),
        "rare-03": ("Skeletal Fish", "rare-skeletal-fish", true),
        "rare-04": ("Frostwing Ray", "rare-frostwing-ray", true),
        "rare-05": ("Aurora Shell", "rare-aurora-shell", false),
        "legendary-02": ("Glacier Leviathan", "legendary-glacier-leviathan", true),
        "legendary-03": ("Ice Kraken", "legendary-ice-kraken", true),
        "narwhal": ("Narwhal Roh", "legendary-spirit-narwhal", true),
        "rare-06": ("Krill Kristal", "rare-crystal-krill", true),
        "rare-07": ("Lanternfish Api Biru", "rare-blueflame-lanternfish", true),
        "rare-08": ("Silverfish Lipatan", "rare-origami-silverfish", true),
        "rare-09": ("Amphipod Opal", "rare-opal-amphipod", true),
        "rare-10": ("Keong Jam Pasir", "rare-hourglass-conch", false),
        "rare-11": ("Batu Nebula", "rare-nebula-pebble", false),
        "rare-12": ("Ubur Bulan", "rare-moon-jelly", true),
        "rare-13": ("Kayu Prisma", "rare-prism-driftwood", false),
        "rare-14": ("Copepod Amber", "rare-amber-copepod", true),
        "rare-15": ("Lichen Aurora", "rare-aurora-lichen", false),
        "rare-16": ("Toothfish Kaca", "rare-glass-toothfish", true),
        "rare-17": ("Cacing Bulu Salju", "rare-frostfeather-worm", true),
        "rare-18": ("Kancing Mutiara", "rare-pearl-button", false),
        "rare-19": ("Kompas Pasang", "rare-tide-compass", false),
        "rare-20": ("Kepiting Keping Salju", "rare-snowflake-crab", true),
        "rare-21": ("Botol Peta Bintang", "rare-star-map-bottle", false),
        "rare-22": ("Ikan Buntal Malam", "rare-midnight-puffer", true),
        "rare-23": ("Teripang Kristal", "rare-crystal-sea-cucumber", true),
        "rare-24": ("Bulu Babi Safir", "rare-sapphire-urchin", true),
        "legendary-04": ("Naga Langit Aurora", "legendary-aurora-sky-dragon", true),
        "legendary-05": ("Paus Rasi Bintang", "legendary-constellation-whale", true),
        "legendary-06": ("Petrel Angin Utara", "legendary-rime-petrel", true),
        "legendary-07": ("Nautilus Atlas", "legendary-atlas-nautilus", true),
        "legendary-08": ("Hydra Salju", "legendary-snow-hydra", true),
        "legendary-09": ("Ngengat Kristal Kutub", "legendary-crystal-moth", true),
        "legendary-10": ("Kura-Kura Pulau Salju", "legendary-island-turtle", true),
        "legendary-11": ("Kuda Laut Komet", "legendary-comet-seahorse", true),
        "legendary-12": ("Bunga Palung", "legendary-abyss-bloom", false),
        "legendary-13": ("Medusa Lonceng Bulan", "legendary-moonbell-medusa", true),
        "legendary-14": ("Cumi Penenun Mimpi", "legendary-dreamweaver-squid", true),
        "legendary-15": ("Kirin Laut Es", "legendary-ice-kirin", true),
        "legendary-16": ("Kepiting Tungku Salju", "legendary-snowforge-crab", true),
        "legendary-17": ("Telur Badai Salju", "legendary-blizzard-egg", false),
        "legendary-18": ("Mahkota Laut Beku", "legendary-frozen-sea-crown", false),
        "legendary-19": ("Kompas Peramal Musim", "legendary-winter-oracle-compass", false),
        "legendary-20": ("Gong Bulan Pasang", "legendary-tide-moon-gong", false),
        "legendary-21": ("Mercusuar Kenangan", "legendary-memory-lighthouse", false),
        "legendary-22": ("Harpa Aurora", "legendary-aurora-harp", false),
        "legendary-23": ("Trisula Badai", "legendary-storm-trident", false),
        "legendary-24": ("Kunci Bintang Kutub", "legendary-polestar-key", false),
        "legendary-25": ("Lentera Cahaya Bintang", "legendary-starlight-lantern", false),
        "legendary-26": ("Kapal Layar Gletser", "legendary-glacier-sailing-ship", false),
        "legendary-27": ("Jam Pasir Kaca Salju", "legendary-snowglass-hourglass", false),
        "legendary-28": ("Arsip Embun Beku", "legendary-frost-archive", false),
        "legendary-29": ("Astrolab Pasang", "legendary-tide-astrolabe", false),
        "legendary-30": ("Kotak Musik Musim Dingin", "legendary-winter-music-box", false),
    ]

    static func kind(id: String) -> Kind? {
        knownKinds.first { $0.id == id }
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
