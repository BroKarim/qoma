import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: QyubeAppCoordinator?
    private let updaterManager = UpdaterManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
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

        // Isolated artwork review: no focus records, monitoring request, or timer session.
        if ProcessInfo.processInfo.arguments.contains("--companion-preview") {
            NSApp.setActivationPolicy(.accessory)
            WindowManager.shared.showFloating()
            return
        }
        #endif

        NSApp.setActivationPolicy(.regular)
        updaterManager.start()

        // qyube runtime
        coordinator = QyubeAppCoordinator()
        coordinator?.showHomeWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        coordinator?.showHomeWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
