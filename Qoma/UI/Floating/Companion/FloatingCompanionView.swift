import SpriteKit
import SwiftUI

struct FloatingCompanionView: NSViewRepresentable {
    let scene: CompanionScene
    var onTap: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("qyube.reduceMotionOverride") private var reduceMotionOverride = false

    init(scene: CompanionScene, onTap: (() -> Void)? = nil) {
        self.scene = scene
        self.onTap = onTap
    }

    func makeNSView(context: Context) -> SKView {
        let view = CompanionSpriteView()
        view.onTap = onTap
        view.allowsTransparency = true
        view.preferredFramesPerSecond = 30
        view.ignoresSiblingOrder = false
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.button)
        view.setAccessibilityLabel("Show timer from fishing companion")
        self.scene.reduceMotion = self.reduceMotion || self.reduceMotionOverride
        view.presentScene(self.scene)
        return view
    }

    func updateNSView(_ view: SKView, context: Context) {
        (view as? CompanionSpriteView)?.onTap = onTap
        let shouldReduceMotion = self.reduceMotion || self.reduceMotionOverride
        if self.scene.reduceMotion != shouldReduceMotion { self.scene.reduceMotion = shouldReduceMotion }
    }

    static func dismantleNSView(_ view: SKView, coordinator: ()) {
        view.presentScene(nil)
    }
}

private final class CompanionSpriteView: SKView {
    var onTap: (() -> Void)?
    private var dragStartLocation: NSPoint?
    private var hasDragged = false

    override var mouseDownCanMoveWindow: Bool { false }
    override var isOpaque: Bool {
        false
    }

    override var acceptsFirstResponder: Bool {
        false
    }

    override func mouseDown(with event: NSEvent) {
        dragStartLocation = NSEvent.mouseLocation
        hasDragged = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStartLocation, let window else { return }
        let current = NSEvent.mouseLocation
        let delta = NSPoint(x: current.x - start.x, y: current.y - start.y)
        if !hasDragged && hypot(delta.x, delta.y) < 3 { return }
        hasDragged = true
        window.setFrameOrigin(NSPoint(x: window.frame.origin.x + delta.x, y: window.frame.origin.y + delta.y))
        dragStartLocation = current
    }

    override func mouseUp(with event: NSEvent) {
        if !hasDragged { onTap?() }
        dragStartLocation = nil
        hasDragged = false
    }

    override func accessibilityPerformPress() -> Bool {
        onTap?()
        return true
    }
}
