import Cocoa
import Combine
import SwiftUI

@MainActor
final class WindowManager: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = WindowManager()
    let objectWillChange = ObservableObjectPublisher()

    var floatingWindow: NSWindow?
    private(set) var companionScene: CompanionScene?
    private var previewScale: CGFloat = 1
    private let positionKey = "qyube.companion.origin"

    func showFloating() {
        if let window = floatingWindow, let scene = companionScene {
            scene.startSession()
            window.orderFrontRegardless()
            return
        }

        self.objectWillChange.send()

        let contentSize = self.companionSize
        let scene = CompanionScene()
        let contentView = FloatingCompanionView(scene: scene)

        let window = NSPanel(
            contentRect: NSRect(origin: initialOrigin(size: contentSize), size: contentSize),
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
        window.delegate = self
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
        ]

        // Hosting View
        window.contentView = NSHostingView(rootView: contentView)
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        scene.onHidden = { [weak self, weak scene] in
            DispatchQueue.main.async {
                guard let self, self.companionScene === scene, scene?.playback.phase == .hidden else { return }
                self.hideFloating()
            }
        }
        self.companionScene = scene
        scene.startSession()
        window.orderFrontRegardless()

        self.floatingWindow = window
    }

    func hideFloating() {
        guard self.floatingWindow != nil else { return }
        self.objectWillChange.send()
        self.companionScene?.shutDown()
        self.companionScene = nil
        self.floatingWindow?.orderOut(nil)
        self.floatingWindow?.contentView = nil
        self.floatingWindow = nil
    }

    func updateFloatingSize() {
        guard let window = floatingWindow else { return }
        window.setContentSize(self.companionSize)
        if let visible = window.screen?.visibleFrame {
            let origin = window.frame.origin
            window.setFrameOrigin(CGPoint(
                x: min(max(origin.x, visible.minX), visible.maxX - window.frame.width),
                y: min(max(origin.y, visible.minY), visible.maxY - window.frame.height)))
        }
    }

    func pauseCompanion(_ paused: Bool) {
        self.companionScene?.setSessionPaused(paused)
    }

    func completeCompanion() {
        self.companionScene?.completeSession()
    }

    func stopCompanion(activeSeconds: TimeInterval) {
        self.companionScene?.stopSession(activeSeconds: activeSeconds)
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = floatingWindow else { return }
        UserDefaults.standard.set(NSStringFromPoint(window.frame.origin), forKey: self.positionKey)
    }

    private var companionSize: CGSize {
        CGSize(
            width: CompanionScene.stageSize.width * self.previewScale,
            height: CompanionScene.stageSize.height * self.previewScale)
    }

    private func initialOrigin(size: CGSize) -> CGPoint {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1280, height: 800)
        let saved = UserDefaults.standard.string(forKey: self.positionKey).map(NSPointFromString)
        let proposed = saved ?? CGPoint(x: visible.maxX - size.width - 36, y: visible.minY + 36)
        return CGPoint(
            x: min(max(proposed.x, visible.minX), visible.maxX - size.width),
            y: min(max(proposed.y, visible.minY), visible.maxY - size.height))
    }

    #if DEBUG
    func preview(_ action: CompanionPreviewAction) {
        if action == .start { self.showFloating(); return }
        guard let scene = companionScene else { return }
        switch action {
        case .start: break
        case .bite: scene.biteNow()
        case .sleep: scene.setSessionPaused(true)
        case .resume:
            scene.setDistracted(false)
            scene.setSessionPaused(false)
        case .distract: scene.setDistracted(true)
        case .complete: scene.completeSession()
        case .stopEarly: scene.stopSession(activeSeconds: 60)
        case .actualSize: self.previewScale = 1; self.updateFloatingSize()
        case .largeSize: self.previewScale = 2; self.updateFloatingSize()
        case .dismiss: self.hideFloating()
        }
    }
    #endif
}

#if DEBUG
enum CompanionPreviewAction { case start, bite, sleep, resume, distract, complete, stopEarly, actualSize, largeSize,
                                   dismiss
}
#endif
