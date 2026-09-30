import SpriteKit
import SwiftUI

struct FloatingCompanionView: NSViewRepresentable {
    let scene: CompanionScene
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeNSView(context: Context) -> SKView {
        let view = CompanionSpriteView()
        view.allowsTransparency = true
        view.preferredFramesPerSecond = 30
        view.ignoresSiblingOrder = false
        view.setAccessibilityElement(true)
        view.setAccessibilityRole(.image)
        view.setAccessibilityLabel("qyube fishing companion")
        self.scene.reduceMotion = self.reduceMotion
        view.presentScene(self.scene)
        return view
    }

    func updateNSView(_ view: SKView, context: Context) {
        if self.scene.reduceMotion != self.reduceMotion { self.scene.reduceMotion = self.reduceMotion }
    }

    static func dismantleNSView(_ view: SKView, coordinator: ()) {
        view.presentScene(nil)
    }
}

private final class CompanionSpriteView: SKView {
    override var isOpaque: Bool {
        false
    }

    override var acceptsFirstResponder: Bool {
        false
    }

    override func mouseDown(with event: NSEvent) {
        // Drag the compact companion without activating the app or taking keyboard focus.
        window?.performDrag(with: event)
    }
}
