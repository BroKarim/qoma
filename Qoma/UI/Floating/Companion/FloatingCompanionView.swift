import SpriteKit
import SwiftUI

struct FloatingCompanionView: NSViewRepresentable {
    let scene: CompanionScene
    var onTap: (() -> Void)?
    var onBucket: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(scene: CompanionScene, onTap: (() -> Void)? = nil, onBucket: (() -> Void)? = nil) {
        self.scene = scene
        self.onTap = onTap
        self.onBucket = onBucket
    }

    func makeNSView(context: Context) -> SKView {
        let view = CompanionSpriteView()
        view.onTap = onTap
        view.onBucket = onBucket
        view.allowsTransparency = true
        view.preferredFramesPerSecond = 60
        view.ignoresSiblingOrder = false
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.button)
        view.setAccessibilityLabel("Fishing companion. Press to show session catches; click penguin to show timer.")
        self.scene.reduceMotion = self.reduceMotion
        view.presentScene(self.scene)
        return view
    }

    func updateNSView(_ view: SKView, context: Context) {
        (view as? CompanionSpriteView)?.onTap = onTap
        (view as? CompanionSpriteView)?.onBucket = onBucket
        let shouldReduceMotion = self.reduceMotion
        if self.scene.reduceMotion != shouldReduceMotion { self.scene.reduceMotion = shouldReduceMotion }
    }

    static func dismantleNSView(_ view: SKView, coordinator: ()) {
        view.presentScene(nil)
    }
}

private final class CompanionSpriteView: SKView {
    var onTap: (() -> Void)?
    var onBucket: (() -> Void)?
    private var dragStartLocation: NSPoint?
    private var hasDragged = false

    override var mouseDownCanMoveWindow: Bool { false }
    override var isOpaque: Bool {
        false
    }

    override var acceptsFirstResponder: Bool {
        true
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
        if !hasDragged {
            let point = convert(event.locationInWindow, from: nil)
            if let scene {
                let location = scene.convertPoint(fromView: point)
                if CGRect(x: 104, y: 52, width: 28, height: 28).contains(location) { onBucket?() }
                else { onTap?() }
            }
        }
        dragStartLocation = nil
        hasDragged = false
    }

    override func accessibilityPerformPress() -> Bool {
        onBucket?()
        return true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 || event.keyCode == 36 { onBucket?() }
        else { super.keyDown(with: event) }
    }
}
