import Foundation
import AppKit

final class BrowserActivityResolver {
    static let shared = BrowserActivityResolver()

    private init() {}

    func resolve(for app: NSRunningApplication) -> WebsiteVisitRecord? {
        guard let bundleID = app.bundleIdentifier,
              let browserName = AppConstants.AnalyticsSettings.supportedBrowsers[bundleID] else {
            return nil
        }

        return nil
    }
}
