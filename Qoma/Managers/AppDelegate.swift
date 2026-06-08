import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private let updaterManager = UpdaterManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        updaterManager.start()
        self.menuBarController = MenuBarController()
        _ = self.menuBarController

        // Don't check permissions on init — let background tracking handle it
    }
}
