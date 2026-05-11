import Foundation
import Combine
import AppKit

final class AnalyticsPermissionsManager: ObservableObject {
    @Published var hasAutomationAccess = false

    private var alreadyPrompted = false

    func checkAutomation() {
        if alreadyPrompted { return }
        alreadyPrompted = true

        let script = NSAppleScript(source: """
            tell application "System Events"
                get name of every process
            end tell
        """)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)

        if let error = error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            hasAutomationAccess = (code != -1743)
        } else {
            hasAutomationAccess = true
        }
    }

    func openAutomationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }
}
