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
    private let bucketPopover = NSPopover()
    var bucketEvents: ((UUID) -> [CatchEvent])?
    var previouslyCaughtKinds: ((UUID) -> Set<String>)?
    var onOpenCatalog: (() -> Void)?

    private func showBucket() {
        guard let window, let anchor = window.contentView, let sessionID else { return }
        if bucketPopover.isShown { bucketPopover.close(); return }
        bucketPopover.behavior = .transient
        bucketPopover.appearance = NSAppearance(named: .aqua)
        bucketPopover.contentViewController = NSHostingController(rootView: CoveBucketView(
            events: { [weak self] in self?.bucketEvents?(sessionID) ?? [] },
            previouslyCaughtKinds: previouslyCaughtKinds?(sessionID) ?? [],
            onCatalog: { [weak self] in self?.bucketPopover.close(); self?.onOpenCatalog?() }))
        let size = bucketPopover.contentViewController?.view.fittingSize ?? NSSize(width: 210, height: 240)
        let visible = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let island = window.convertToScreen(NSRect(x: 0, y: 0, width: 164, height: 164))
        let options: [(NSRectEdge, CGFloat, CGFloat, NSRect)] = [
            (.maxY, visible.maxY - island.maxY, size.height, NSRect(x: 82, y: 168, width: 1, height: 1)),
            (.maxX, visible.maxX - island.maxX, size.width, NSRect(x: 168, y: 82, width: 1, height: 1)),
            (.minX, island.minX - visible.minX, size.width, NSRect(x: -4, y: 82, width: 1, height: 1)),
            (.minY, island.minY - visible.minY, size.height, NSRect(x: 82, y: -4, width: 1, height: 1))
        ]
        let choice = options.first(where: { $0.1 >= $0.2 + 12 }) ?? options.max(by: { $0.1 - $0.2 < $1.1 - $1.2 })!
        bucketPopover.show(relativeTo: choice.3, of: anchor, preferredEdge: choice.0)
    }

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

        let contentSize = CompanionScene.stageSize
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
        }, onBucket: { [weak self] in
            self?.showBucket()
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
        bucketPopover.close()
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

    func recordCatch(kindID: String) {
        scene?.recordCatch(kindID: kindID)
    }

    func windowDidMove(_ notification: Notification) {
        guard let window else { return }
        UserDefaults.standard.set(NSStringFromPoint(window.frame.origin), forKey: positionKey)
    }

    func resetPosition() {
        UserDefaults.standard.removeObject(forKey: positionKey)
        guard let window else { return }
        window.setFrameOrigin(initialOrigin(size: window.frame.size))
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
