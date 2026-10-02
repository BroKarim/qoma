import Cocoa
import Combine
import SwiftUI

/// Reduced menu bar controller for qyube: status icon only.
/// Tapping the icon restores/shows the timer panel if a session is active,
/// or opens the Home window if not.
@MainActor
final class MenuBarController: NSObject {
    static var shared: MenuBarController?

    private let statusItem: NSStatusItem
    private var onStatusClick: (() -> Void)?
    private var cancellables = Set<AnyCancellable>()

    override init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.action = #selector(self.statusItemClicked(_:))
            button.target = self
            button.image = makeStatusIcon()
            button.imagePosition = .imageOnly
        }

        MenuBarController.shared = self
    }

    func configure(onClick: @escaping () -> Void) {
        self.onStatusClick = onClick
    }

    func updateTitle(_ title: String) {
        statusItem.button?.title = title
        statusItem.length = title.isEmpty ? NSStatusItem.squareLength : NSStatusItem.variableLength
    }

    /// Legacy hook for old FocusSessionManager; new flow uses status-click restore instead.
    func showPopover() {
        onStatusClick?()
    }

    @objc private func statusItemClicked(_: Any?) {
        onStatusClick?()
    }

    private func makeStatusIcon() -> NSImage {
        let text = "Q"
        let targetSize = NSSize(width: 16, height: 16)
        let cornerRadius: CGFloat = 4
        let image = NSImage(size: targetSize, flipped: false) { rect in
            let bgRect = rect.insetBy(dx: 0.5, dy: 0.5)
            let path = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
            NSColor.white.setFill()
            path.fill()

            let font = NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black,
            ]
            let string = NSString(string: text)
            let textSize = string.size(withAttributes: attributes)
            let drawPoint = NSPoint(
                x: rect.midX - (textSize.width / 2),
                y: rect.midY - (textSize.height / 2) - 0.5)

            let context = NSGraphicsContext.current
            let priorOp = context?.compositingOperation ?? .sourceOver
            context?.compositingOperation = .destinationOut
            string.draw(at: drawPoint, withAttributes: attributes)
            context?.compositingOperation = priorOp

            NSColor.black.withAlphaComponent(0.18).setStroke()
            path.lineWidth = 1
            path.stroke()
            return true
        }
        image.isTemplate = false
        return image
    }
}
