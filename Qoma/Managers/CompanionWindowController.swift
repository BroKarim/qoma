import Cocoa
import SwiftUI

/// Persistent transparent penguin panel during active sessions.
@MainActor
final class CompanionWindowController {
    private var window: NSPanel?
    private let positionKey = "qyube.companion.origin"
    private var onTap: (() -> Void)?

    var isVisible: Bool { window?.isVisible ?? false }

    func configure(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }

    func show() {
        if let window = window {
            window.orderFrontRegardless()
            return
        }

        let contentSize = CGSize(width: 140, height: 140)
        let panel = NSPanel(
            contentRect: NSRect(origin: initialOrigin(size: contentSize), size: contentSize),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.isRestorable = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let scene = CompanionScene()
        let contentView = FloatingCompanionView(scene: scene)
            .onTapGesture { [weak self] in
                self?.onTap?()
            }
        panel.contentView = NSHostingView(rootView: contentView)

        window = panel
        panel.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    func close() {
        hide()
        window?.contentView = nil
        window = nil
    }

    private func initialOrigin(size: CGSize) -> CGPoint {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1280, height: 800)
        let saved = UserDefaults.standard.string(forKey: positionKey).map(NSPointFromString)
        let proposed = saved ?? CGPoint(x: visible.maxX - size.width - 36, y: visible.minY + 36)
        return CGPoint(
            x: min(max(proposed.x, visible.minX), visible.maxX - size.width),
            y: min(max(proposed.y, visible.minY), visible.maxY - size.height)
        )
    }
}
