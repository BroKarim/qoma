import Foundation
import AppKit

final class BrowserActivityResolver {
    static let shared = BrowserActivityResolver()

    private init() {}

    func resolveCurrentTab(for bundleID: String) -> (domain: String, title: String?)? {
        guard let browserName = AppConstants.AnalyticsSettings.supportedBrowsers[bundleID] else {
            print("[BrowserActivityResolver] ⚠️ Unsupported browser: \(bundleID)")
            return nil
        }

        print("[BrowserActivityResolver] 🔍 Resolving for: \(browserName) (\(bundleID))")

        switch bundleID {
        case "com.apple.Safari":
            return runSafariScript()
        case "com.google.Chrome":
            return runChromeScript()
        case "org.mozilla.firefox":
            return runFirefoxScript()
        case "com.microsoft.edgemac":
            return runEdgeScript()
        case "com.brave.Browser":
            return runBraveScript()
        default:
            print("[BrowserActivityResolver] ⚠️ No handler for: \(bundleID)")
            return nil
        }
    }

    private func runSafariScript() -> (domain: String, title: String?)? {
        let script = """
            tell application "Safari"
                if not (exists window 1) then return ""
                set currentTab to current tab of window 1
                set tabURL to URL of currentTab
                set tabName to name of currentTab
                return tabURL & "|||" & tabName
            end tell
        """

        return runAppleScript(script, appName: "Safari")
    }

    private func runChromeScript() -> (domain: String, title: String?)? {
        let script = """
            tell application "Google Chrome"
                if not (exists window 1) then return ""
                set currentTab to active tab of window 1
                set tabURL to URL of currentTab
                set tabName to title of currentTab
                return tabURL & "|||" & tabName
            end tell
        """

        return runAppleScript(script, appName: "Google Chrome")
    }

    private func runFirefoxScript() -> (domain: String, title: String?)? {
        let script = """
            tell application "Firefox"
                if not (exists window 1) then return ""
                return ""
            end tell
        """
        return runAppleScript(script, appName: "Firefox")
    }

    private func runEdgeScript() -> (domain: String, title: String?)? {
        let script = """
            tell application "Microsoft Edge"
                if not (exists window 1) then return ""
                set currentTab to active tab of window 1
                set tabURL to URL of currentTab
                set tabName to title of currentTab
                return tabURL & "|||" & tabName
            end tell
        """

        return runAppleScript(script, appName: "Microsoft Edge")
    }

    private func runBraveScript() -> (domain: String, title: String?)? {
        let script = """
            tell application "Brave Browser"
                if not (exists window 1) then return ""
                set currentTab to active tab of window 1
                set tabURL to URL of currentTab
                set tabName to title of currentTab
                return tabURL & "|||" & tabName
            end tell
        """

        return runAppleScript(script, appName: "Brave Browser")
    }

    private func runAppleScript(_ scriptSource: String, appName: String) -> (domain: String, title: String?)? {
        guard let script = NSAppleScript(source: scriptSource) else {
            print("[BrowserActivityResolver] ❌ Failed to create AppleScript for \(appName)")
            return nil
        }

        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)

        if let error = error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            let message = error[NSAppleScript.errorMessage] as? String ?? "unknown error"
            
            if code == -1743 || message.lowercased().contains("not allowed") {
                print("[BrowserActivityResolver] ❌ \(appName) - Automation permission denied (Error \(code))")
                print("[BrowserActivityResolver] → User must add Dzenn to System Settings > Privacy & Security > Accessibility")
            } else {
                print("[BrowserActivityResolver] ❌ \(appName) error (Code \(code)): \(message)")
            }
            return nil
        }

        guard let resultString = result.stringValue else {
            print("[BrowserActivityResolver] ⚠️ \(appName) returned nil result")
            return nil
        }

        print("[BrowserActivityResolver] ✅ \(appName) result: \(resultString)")

        if resultString.isEmpty || !resultString.contains("|||") {
            print("[BrowserActivityResolver] ⚠️ \(appName) returned empty or invalid format: '\(resultString)'")
            return nil
        }

        let components = resultString.components(separatedBy: "|||")
        guard components.count >= 1,
              let url = URL(string: components[0]),
              let host = url.host else {
            print("[BrowserActivityResolver] ❌ Failed to parse URL from \(appName): \(components[0])")
            return nil
        }

        let title = components.count >= 2 ? components[1] : nil
        print("[BrowserActivityResolver] ✅ Resolved from \(appName): \(host) - \(title ?? "(no title)")")
        return (domain: host, title: title)
    }
}
