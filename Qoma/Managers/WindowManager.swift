import Cocoa
import Combine
import SwiftUI

private final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}

@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()
    let objectWillChange = ObservableObjectPublisher()

    var floatingWindow: NSWindow?

    func showFloating() {
        if self.floatingWindow != nil { return }

        self.objectWillChange.send()

        let ext = ExtensionManager.shared.activeExtension
        let layout: FloatingLayoutMode = ext != nil
            ? .featureExpanded(ext!)
            : .timerOnly
        let contentSize = layout.contentSize

        let contentView = FloatingTimerView()

        let window = FloatingPanel(
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
        window.makeKey()

        self.floatingWindow = window
    }

    func hideFloating() {
        guard self.floatingWindow != nil else { return }
        self.objectWillChange.send()
        self.floatingWindow?.orderOut(nil)
        self.floatingWindow = nil
    }



    func updateFloatingSize() {
        let ext = ExtensionManager.shared.activeExtension
        let layout: FloatingLayoutMode = ext != nil
            ? .featureExpanded(ext!)
            : .timerOnly
        updateFloatingSize(to: layout.contentSize)
    }

    func updateFloatingSize(to contentSize: CGSize) {
        guard let window = floatingWindow else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().setContentSize(contentSize)
        }
    }

    private func startMonitoringClicksOutside() {
        stopMonitoringClicksOutside()

        // Klik di app lain / di luar semua window app ini
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.onClickOutside?()
            }
        }

        // Klik di window lain milik app ini sendiri (mis. settings window)
        localClickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self, let panel = self.floatingWindow else { return event }
            if event.window !== panel {
                Task { @MainActor in
                    self.onClickOutside?()
                }
            }
            return event
        }
    }

    private func stopMonitoringClicksOutside() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
            localClickMonitor = nil
        }
    }
}
