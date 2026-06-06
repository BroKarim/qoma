import Foundation
import AppKit

class FirefoxBrowser: BrowserInterface {
    let bundleId = "org.mozilla.firefox"
    let displayName = "Firefox"

    func getCurrentURL() -> String? {
        guard let app = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleId
        ).first else {
            return nil
        }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        var windowRef: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(
            axApp, kAXWindowsAttribute as CFString, &windowRef)

        guard windowResult == .success,
              let windows = windowRef as? [AXUIElement],
              let firstWindow = windows.first else {
            return nil
        }

        var focusedRef: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            firstWindow, kAXFocusedUIElementAttribute as CFString, &focusedRef)

        guard focusResult == .success,
              let focusedElement = focusedRef else {
            return nil
        }

        let axFocused = focusedElement as! AXUIElement // swiftlint:disable:this force_cast
        var valueRef: CFTypeRef?
        let valueResult = AXUIElementCopyAttributeValue(
            axFocused, kAXValueAttribute as CFString, &valueRef)

        guard valueResult == .success,
              let urlString = valueRef as? String else {
            return nil
        }

        guard urlString.hasPrefix("http://") || urlString.hasPrefix("https://") else {
            return nil
        }

        return urlString
    }
}
