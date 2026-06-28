import SwiftUI

enum FloatingLayoutMode: Equatable {
    case timerOnly
    case featureCollapsed(any FeatureExtension)
    case featureExpanded(any FeatureExtension)

    static func == (lhs: FloatingLayoutMode, rhs: FloatingLayoutMode) -> Bool {
        switch (lhs, rhs) {
        case (.timerOnly, .timerOnly):
            return true
        case (.featureCollapsed(let l), .featureCollapsed(let r)):
            return l.id == r.id
        case (.featureExpanded(let l), .featureExpanded(let r)):
            return l.id == r.id
        default:
            return false
        }
    }

    var title: String {
        switch self {
        case .timerOnly:
            return "Timer Only"
        case .featureCollapsed(let ext):
            return "\(ext.title) Collapsed"
        case .featureExpanded(let ext):
            return "\(ext.title) Expanded"
        }
    }

    var subtitle: String {
        switch self {
        case .timerOnly:
            return "Minimal floating countdown for deep focus."
        case .featureCollapsed(let ext):
            return "Compact \(ext.title.lowercased()) with timer."
        case .featureExpanded(let ext):
            return "Full \(ext.title.lowercased()) with timer."
        }
    }

    var systemImage: String {
        switch self {
        case .timerOnly:
            return "timer"
        case .featureCollapsed(let ext):
            return ext.systemImage
        case .featureExpanded(let ext):
            return ext.systemImage
        }
    }

    var requiresImage: Bool {
        false
    }

    var showsTimer: Bool {
        true
    }

    var contentSize: CGSize {
        switch self {
        case .timerOnly:
            return CGSize(
                width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
                height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)
        case .featureCollapsed(let ext):
            return ext.collapsedSize()
        case .featureExpanded(let ext):
            return ext.expandedSize()
        }
    }
}
