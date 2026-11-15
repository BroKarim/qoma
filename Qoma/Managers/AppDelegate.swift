import Cocoa
import CoreText
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: QyubeAppCoordinator?
    private let updaterManager = UpdaterManager.shared

    func quitWithoutConfirmation() {
        NSApp.terminate(nil)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let url = Bundle.main.url(forResource: "GeistPixel-Regular-VariableFont_ELSH", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return }
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--crystal-bloom-snapshots"), arguments.count > index + 1 {
            do { try DistractionVisualCheck.writeCrystalClip(to: URL(fileURLWithPath: arguments[index + 1])) }
            catch { NSLog("Crystal Bloom preview failed: %@", error.localizedDescription) }
            NSApp.terminate(nil)
            return
        }
        if let index = arguments.firstIndex(of: "--distraction-snapshots"), arguments.count > index + 1 {
            do {
                try DistractionVisualCheck.write(to: URL(fileURLWithPath: arguments[index + 1]))
            } catch {
                NSLog("Distraction visual check failed: %@", error.localizedDescription)
            }
            NSApp.terminate(nil)
            return
        }
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

        NSApp.setActivationPolicy(.accessory)
        updaterManager.start()

        // qyube runtime
        coordinator = QyubeAppCoordinator()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        coordinator?.showHomeWindow()
        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        Task { @MainActor in await AccessCoordinator.shared.refreshAccess() }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        if coordinator?.sessionCoordinator.snapshot != nil { return }
        Task { @MainActor in
            await AccessCoordinator.shared.handleCallback(url)
            coordinator?.showHomeWindow()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let session = coordinator?.sessionCoordinator.snapshot,
              session.status == .active || session.status == .paused else { return .terminateNow }
        guard coordinator?.sessionCoordinator.stopSession(reason: "Quit application") != nil else {
            let failure = NSAlert()
            failure.messageText = "The session could not be saved"
            failure.informativeText = "Keep qyube open and try quitting again so your session can be recorded safely."
            failure.runModal()
            return .terminateCancel
        }
        return .terminateNow
    }
}
