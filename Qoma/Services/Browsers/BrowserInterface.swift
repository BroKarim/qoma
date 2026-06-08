import Foundation
import OSLog

struct AppleScriptResult {
    let result: String?
    let errorCode: Int
    let error: NSDictionary?
}

protocol BrowserInterface {
    var bundleId: String { get }
    var displayName: String { get }
    func getCurrentURL() -> String?
    func isInPrivateBrowsingMode() -> Bool?
}

class BaseBrowser: BrowserInterface {
    let bundleId: String
    let displayName: String

    var currentURLScript: String {
        fatalError("Subclasses must override currentURLScript")
    }

    init(bundleId: String, displayName: String) {
        self.bundleId = bundleId
        self.displayName = displayName
    }

    func getCurrentURL() -> String? {
        let scriptResult = executeAppleScript(currentURLScript)

        if scriptResult.errorCode == -1743 || scriptResult.errorCode == -1744 {
            AnalyticsPermissionsManager.shared.handleBrowserPermissionResult(
                success: false, browserName: displayName)
            return nil
        } else if scriptResult.errorCode == -1712 {
            Logger.browser.warning("\(self.displayName, privacy: .public) AppleScript timeout — transient error")
            return nil
        } else if scriptResult.errorCode == -1719 {
            Logger.browser.warning(
                "\(self.displayName, privacy: .public) AppleScript invalid index — tab may have changed")
            return nil
        }

        AnalyticsPermissionsManager.shared.handleBrowserPermissionResult(
            success: scriptResult.result != nil, browserName: displayName)
        return scriptResult.result
    }

    func isInPrivateBrowsingMode() -> Bool? {
        // Default: no private browsing detection
        return nil
    }

    internal func executeAppleScript(_ script: String) -> AppleScriptResult {
        let wrappedScript = """
            with timeout of 3 seconds
            \(script)
            end timeout
            """

        guard let appleScript = NSAppleScript(source: wrappedScript) else {
            return AppleScriptResult(result: nil, errorCode: -1, error: nil)
        }

        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)

        if let error = error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 0
            return AppleScriptResult(result: nil, errorCode: code, error: error)
        }

        return AppleScriptResult(result: result.stringValue, errorCode: 0, error: nil)
    }
}
