import SwiftUI

enum FloatingLayoutMode: String, CaseIterable, Identifiable {
    case timerOnly
    case mixed
    case imageOnly

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .timerOnly:
            "Timer Only"
        case .mixed:
            "Timer + Image"
        case .imageOnly:
            "Image Only"
        }
    }

    var subtitle: String {
        switch self {
        case .timerOnly:
            "Minimal floating countdown for deep focus."
        case .mixed:
            "Balanced card with artwork and live timer."
        case .imageOnly:
            "Artwork-only floating board for quiet sessions."
        }
    }

    var systemImage: String {
        switch self {
        case .timerOnly:
            "timer"
        case .mixed:
            "rectangle.stack.badge.play"
        case .imageOnly:
            "photo"
        }
    }

    var requiresImage: Bool {
        self != .timerOnly
    }

    var showsTimer: Bool {
        self != .imageOnly
    }

    var contentSize: CGSize {
        switch self {
        case .timerOnly:
            CGSize(
                width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
                height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)
        case .mixed:
            CGSize(
                width: AppConstants.FloatingLayoutSettings.width,
                height: AppConstants.FloatingLayoutSettings.mixedHeight)
        case .imageOnly:
            CGSize(
                width: AppConstants.FloatingLayoutSettings.width,
                height: AppConstants.FloatingLayoutSettings.imageOnlyHeight)
        }
    }

    static func from(id: String) -> FloatingLayoutMode {
        FloatingLayoutMode(rawValue: id) ?? .timerOnly
    }
}
