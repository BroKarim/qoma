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
        let testScript = NSAppleScript(source: """
            tell application "System Events"
                get name of every process
            end tell
        """)
        
        var error: NSDictionary?
        testScript?.executeAndReturnError(&error)

        if let error = error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            let message = error[NSAppleScript.errorMessage] as? String ?? ""
            
            // Error code -1743 = "System Events got an error: osascript is not allowed assistive access"
            // Error code -1748 = "Execution error"
            if code == -1743 || message.lowercased().contains("not allowed assistive access") {
                automationStatus = .denied
                print("[AnalyticsPermissionsManager] Automation permission DENIED - user needs to grant in System Settings")
            } else {
                automationStatus = .granted
                print("[AnalyticsPermissionsManager] Automation permission GRANTED")
            }
        } else {
            automationStatus = .granted
            print("[AnalyticsPermissionsManager] Automation permission check successful - GRANTED")
        }
    }

    func openAutomationSettings() {
        // Open System Settings at Privacy & Security > Accessibility
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
            print("[AnalyticsPermissionsManager] Opening System Settings > Privacy & Security > Accessibility")
        }
    }

    enum AutomationStatus {
        case unknown
        case granted
        case denied
    }
}
