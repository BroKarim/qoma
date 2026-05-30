import Foundation
import Combine
import AppKit
import OSLog

final class AnalyticsPermissionsManager: ObservableObject {
    static let shared = AnalyticsPermissionsManager()

    @Published private(set) var automationStatus: PermissionStatus = .unknown
    @Published private(set) var accessibilityStatus: PermissionStatus = .unknown
    @Published private(set) var lastError: String?

    var hasAutomationAccess: Bool {
        automationStatus == .granted
    }

    var needsAutomationPermission: Bool {
        automationStatus == .denied
    }

    var hasAccessibilityAccess: Bool {
        accessibilityStatus == .granted
    }

    var needsAccessibilityPermission: Bool {
        accessibilityStatus == .denied
    }

    func checkAllPermissions() {
        checkAutomation()
        checkAccessibility()
    }

    func checkAutomation() {
        let testScript = NSAppleScript(source: """
            with timeout of 3 seconds
            tell application "System Events"
                get name of every process
            end tell
            end timeout
            """)

        var error: NSDictionary?
        testScript?.executeAndReturnError(&error)

        if let error = error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            let message = error[NSAppleScript.errorMessage] as? String ?? ""

            if code == -1743 || message.lowercased().contains("not allowed") {
                automationStatus = .denied
                lastError = "Automation permission denied (code \(code))"
                Logger.permissions.error("Automation permission DENIED")
            } else {
                automationStatus = .granted
                lastError = nil
                Logger.permissions.info("Automation permission GRANTED")
            }
        } else {
            automationStatus = .granted
            lastError = nil
            Logger.permissions.info("Automation permission GRANTED")
        }
    }

    func checkAccessibility() {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary
        )
        accessibilityStatus = trusted ? .granted : .denied
        Logger.permissions.info("Accessibility permission: \(trusted ? "GRANTED" : "DENIED", privacy: .public)")
    }

    func promptAccessibilityIfNeeded() {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        )
        accessibilityStatus = trusted ? .granted : .denied
    }

    func openAutomationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
            Logger.permissions.info("Opening System Settings > Privacy & Security > Automation")
        }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
            Logger.permissions.info("Opening System Settings > Privacy & Security > Accessibility")
        }
    }

    func handleBrowserPermissionResult(success: Bool, browserName: String? = nil) {
        if success {
            automationStatus = .granted
            lastError = nil
        } else {
            let browser = browserName ?? "browser"
            lastError = "Automation permission needed for \(browser)"
            Logger.permissions.error("Browser permission failed for \(browser, privacy: .public)")
        }
    }

    enum PermissionStatus {
        case unknown
        case granted
        case denied
    }
}
