import SwiftUI

enum FloatingTheme: String, CaseIterable, Identifiable {
    case graphite
    case ocean
    case forest
    case ember
    case pearl

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .graphite:
            "Graphite"
        case .ocean:
            "Ocean"
        case .forest:
            "Forest"
        case .ember:
            "Ember"
        case .pearl:
            "Pearl"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .graphite:
            .black
        case .ocean:
            Color(red: 15.0 / 255.0, green: 44.0 / 255.0, blue: 63.0 / 255.0)
        case .forest:
            Color(red: 20.0 / 255.0, green: 50.0 / 255.0, blue: 37.0 / 255.0)
        case .ember:
            Color(red: 60.0 / 255.0, green: 30.0 / 255.0, blue: 22.0 / 255.0)
        case .pearl:
            Color(red: 241.0 / 255.0, green: 236.0 / 255.0, blue: 228.0 / 255.0)
        }
    }

    var textColor: Color {
        switch self {
        case .pearl:
            Color(red: 37.0 / 255.0, green: 37.0 / 255.0, blue: 41.0 / 255.0)
        default:
            .white
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .pearl:
            Color.black.opacity(0.58)
        default:
            Color.white.opacity(0.78)
        }
    }

    var borderColor: Color {
        switch self {
        case .pearl:
            Color.black.opacity(0.08)
        case .ember:
            Color(red: 1.0, green: 181.0 / 255.0, blue: 137.0 / 255.0).opacity(0.24)
        case .ocean:
            Color(red: 124.0 / 255.0, green: 214.0 / 255.0, blue: 1.0).opacity(0.24)
        case .forest:
            Color(red: 120.0 / 255.0, green: 214.0 / 255.0, blue: 158.0 / 255.0).opacity(0.24)
        case .graphite:
            Color.white.opacity(0.1)
        }
    }

    var swatchLeadingColor: Color {
        switch self {
        case .graphite:
            Color(red: 92.0 / 255.0, green: 102.0 / 255.0, blue: 133.0 / 255.0)
        case .ocean:
            Color(red: 64.0 / 255.0, green: 189.0 / 255.0, blue: 1.0)
        case .forest:
            Color(red: 88.0 / 255.0, green: 194.0 / 255.0, blue: 131.0 / 255.0)
        case .ember:
            Color(red: 1.0, green: 161.0 / 255.0, blue: 101.0 / 255.0)
        case .pearl:
            Color(red: 1.0, green: 1.0, blue: 1.0)
        }
    }

    var swatchTrailingColor: Color {
        switch self {
        case .graphite:
            Color(red: 31.0 / 255.0, green: 36.0 / 255.0, blue: 48.0 / 255.0)
        case .ocean:
            Color(red: 19.0 / 255.0, green: 82.0 / 255.0, blue: 113.0 / 255.0)
        case .forest:
            Color(red: 29.0 / 255.0, green: 91.0 / 255.0, blue: 62.0 / 255.0)
        case .ember:
            Color(red: 120.0 / 255.0, green: 64.0 / 255.0, blue: 46.0 / 255.0)
        case .pearl:
            Color(red: 220.0 / 255.0, green: 210.0 / 255.0, blue: 195.0 / 255.0)
        }
    }

    static func from(id: String) -> FloatingTheme {
        FloatingTheme(rawValue: id) ?? .graphite
    }
}
