import Foundation
import Combine
import AppKit

final class AnalyticsPermissionsManager: ObservableObject {
    @Published private(set) var automationStatus: AutomationStatus = .unknown

    var hasAutomationAccess: Bool {
        automationStatus == .granted
    }

    var needsAutomationPermission: Bool {
        automationStatus == .denied
    }

    func checkAutomation() {
        let script = NSAppleScript(source: """
            tell application "System Events"
                get name of every process
            end tell
        """)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)

        if let error = error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            automationStatus = (code == -1743) ? .denied : .granted
        } else {
            automationStatus = .granted
        }
    }

    func openAutomationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }

    enum AutomationStatus {
        case unknown
        case granted
        case denied
    }
}
