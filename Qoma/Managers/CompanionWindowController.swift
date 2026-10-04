import Cocoa
import SwiftUI

/// Persistent transparent penguin panel during active sessions.
@MainActor
final class CompanionWindowController: NSObject, NSWindowDelegate {
    private var window: NSPanel?
    private var scene: CompanionScene?
    private var sessionID: UUID?
    private let positionKey = "qyube.companion.origin"
    private var onTap: (() -> Void)?

    var isVisible: Bool { window?.isVisible ?? false }

    func configure(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }

    func show(sessionID: UUID, paused: Bool) {
        if let window = window {
            if self.sessionID != sessionID {
                scene?.startSession()
                self.sessionID = sessionID
            }
            scene?.setSessionPaused(paused)
            if !window.isVisible { window.orderFrontRegardless() }
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
        panel.delegate = self
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let scene = CompanionScene()
        scene.startSession()
        scene.setSessionPaused(paused)
        let contentView = FloatingCompanionView(scene: scene, onTap: { [weak self] in
            self?.onTap?()
        })
        panel.contentView = NSHostingView(rootView: contentView)
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor

        self.scene = scene
        self.sessionID = sessionID
        window = panel
        panel.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
        scene?.shutDown()
        scene = nil
        sessionID = nil
        window?.contentView = nil
        window = nil
    }

    func close() {
        hide()
    }

    func setDistractionVisual(_ visual: DistractionVisualState?) {
        scene?.setDistractionVisual(visual)
    }

    func windowDidMove(_ notification: Notification) {
        guard let window else { return }
        UserDefaults.standard.set(NSStringFromPoint(window.frame.origin), forKey: positionKey)
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
