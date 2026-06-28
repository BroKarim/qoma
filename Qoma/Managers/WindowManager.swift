import Cocoa
import Combine
import SwiftUI

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
}
