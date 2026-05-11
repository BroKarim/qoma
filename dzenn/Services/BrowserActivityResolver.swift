import Foundation
import AppKit

final class BrowserActivityResolver {
    static let shared = BrowserActivityResolver()

    private init() {}

    func resolveCurrentTab(for bundleID: String) -> (domain: String, title: String?)? {
        guard let browserName = AppConstants.AnalyticsSettings.supportedBrowsers[bundleID] else {
            print("[BrowserActivityResolver] Unsupported browser: \(bundleID)")
            return nil
        }

        print("[BrowserActivityResolver] Resolving for: \(browserName) (\(bundleID))")

        switch bundleID {
        case "com.apple.Safari":
            return runSafariScript()
        case "com.google.Chrome":
            return runChromeScript()
        default:
            print("[BrowserActivityResolver] No handler for: \(bundleID)")
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

    private func runAppleScript(_ scriptSource: String, appName: String) -> (domain: String, title: String?)? {
        guard let script = NSAppleScript(source: scriptSource) else {
            print("[BrowserActivityResolver] Failed to create script for \(appName)")
            return nil
        }

        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)

        if let error = error {
            print("[BrowserActivityResolver] \(appName) script error: \(error)")
            return nil
        }

        guard let resultString = result.stringValue else {
            print("[BrowserActivityResolver] \(appName) returned nil result")
            return nil
        }

        print("[BrowserActivityResolver] \(appName) result: \(resultString)")

        if resultString.isEmpty || !resultString.contains("|||") {
            print("[BrowserActivityResolver] \(appName) invalid result format")
            return nil
        }

        let components = resultString.components(separatedBy: "|||")
        guard components.count >= 1,
              let url = URL(string: components[0]),
              let host = url.host else {
            print("[BrowserActivityResolver] Failed to parse URL: \(components[0])")
            return nil
        }

        let title = components.count >= 2 ? components[1] : nil
        print("[BrowserActivityResolver] Resolved: \(host) - \(title ?? "no title")")
        return (domain: host, title: title)
    }
}
