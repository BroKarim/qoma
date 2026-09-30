import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private let updaterManager = UpdaterManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return }
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--companion-snapshots"), arguments.count > index + 1 {
            do {
                try CompanionVisualCheck.write(to: URL(fileURLWithPath: arguments[index + 1]))
            } catch {
                NSLog("Companion visual check failed: %@", error.localizedDescription)
            }
            NSApp.terminate(nil)
            return
        }
        #endif
        updaterManager.start()
        self.menuBarController = MenuBarController()
        _ = self.menuBarController

        #if DEBUG
        // Isolated artwork review: no focus records, monitoring request, or timer session.
        if ProcessInfo.processInfo.arguments.contains("--companion-preview") {
            WindowManager.shared.showFloating()
            return
        }
        #endif
        AnalyticsPermissionsManager.shared.requestPermissions()
    }
}
