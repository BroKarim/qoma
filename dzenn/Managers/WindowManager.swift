import Cocoa
import Combine
import SwiftUI

@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()
    let objectWillChange = ObservableObjectPublisher()

    private enum MainWindowChrome {
        static let trafficLightsHorizontalOffset: CGFloat = 6
        static let trafficLightsVerticalOffset: CGFloat = -6
    }

    var floatingWindow: NSWindow?
    var mainWindow: NSWindow?

    func showFloating() {
        if self.floatingWindow != nil { return }

        self.objectWillChange.send()

        let layoutMode = FloatingLayoutMode.from(
            id: UserDefaults.standard.string(forKey: AppConstants.FloatingLayoutSettings.selectedLayoutKey)
                ?? AppConstants.FloatingLayoutSettings.defaultLayoutID)
        let contentSize = layoutMode.contentSize

        let contentView = FloatingTimerView()

        let window = NSPanel(
            contentRect: NSRect(x: 100, y: 600, width: contentSize.width, height: contentSize.height),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false)

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
        ]

        // Hosting View
        window.contentView = NSHostingView(rootView: contentView)
        window.orderFrontRegardless()

        self.floatingWindow = window
    }

    func hideFloating() {
        guard self.floatingWindow != nil else { return }
        self.objectWillChange.send()
        self.floatingWindow?.orderOut(nil)
        self.floatingWindow = nil
    }

    func showMainWindow() {
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.activate(ignoringOtherApps: true)

        if self.mainWindow == nil {
            self.mainWindow = self.makeMainWindow()
        }
        guard let window = mainWindow else { return }

        window.level = .normal
        window.deminiaturize(nil)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)

        // Ensure visible & focused
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func makeMainWindow() -> NSWindow {
        let fixedSize = NSSize(width: 860, height: 580)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: fixedSize.width, height: fixedSize.height),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .dzennBackground
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.identifier = NSUserInterfaceItemIdentifier("DzennMainWindow")
        window.minSize = fixedSize
        window.maxSize = fixedSize
        window.center()
        window.contentView = NSHostingView(rootView: MainView())

        window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        DispatchQueue.main.async { [weak window] in
            guard let window else { return }
            self.applyMainWindowTrafficLightsOffset(window)
        }

        return window
    }

    private func applyMainWindowTrafficLightsOffset(_ window: NSWindow) {
        guard let closeButton = window.standardWindowButton(.closeButton),
              let miniButton = window.standardWindowButton(.miniaturizeButton),
              let zoomButton = window.standardWindowButton(.zoomButton) else { return }

        closeButton.frame.origin.x += MainWindowChrome.trafficLightsHorizontalOffset
        miniButton.frame.origin.x += MainWindowChrome.trafficLightsHorizontalOffset
        zoomButton.frame.origin.x += MainWindowChrome.trafficLightsHorizontalOffset

        closeButton.frame.origin.y += MainWindowChrome.trafficLightsVerticalOffset
        miniButton.frame.origin.y += MainWindowChrome.trafficLightsVerticalOffset
        zoomButton.frame.origin.y += MainWindowChrome.trafficLightsVerticalOffset
    }

    func updateFloatingSize(mode: FloatingLayoutMode) {
        guard let window = floatingWindow else { return }
        let size = mode.contentSize

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().setContentSize(size)
        }
    }
}
