import SwiftUI

enum FloatingLayoutMode: String, CaseIterable, Identifiable {
    case timerOnly
    case todolistCollapsed
    case todolistExpanded

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .timerOnly: "Timer Only"
        case .todolistCollapsed: "Todolist Collapsed"
        case .todolistExpanded: "Todolist Expanded"
        }
    }

    var subtitle: String {
        switch self {
        case .timerOnly: "Minimal floating countdown for deep focus."
        case .todolistCollapsed: "Compact todolist with timer."
        case .todolistExpanded: "Full todolist with timer."
        }
    }

    var systemImage: String {
        switch self {
        case .timerOnly: "timer"
        case .todolistCollapsed: "list.bullet.rectangle"
        case .todolistExpanded: "list.bullet.rectangle.fill"
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
        case .todolistCollapsed:
            return CGSize(
                width: AppConstants.ExtensionSettings.extendedWidth,
                height: AppConstants.ExtensionSettings.collapsedStateHeight)
        case .todolistExpanded:
            return CGSize(
                width: AppConstants.ExtensionSettings.extendedWidth,
                height: AppConstants.ExtensionSettings.expandedStateMinHeight)
        }
    }

    static func from(id: String) -> FloatingLayoutMode {
        FloatingLayoutMode(rawValue: id) ?? .timerOnly
    }
}
