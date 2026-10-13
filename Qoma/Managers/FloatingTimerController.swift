import Cocoa
import Combine
import SwiftUI

/// Standalone timer panel. Can be closed without stopping the session.
@MainActor
final class FloatingTimerController: NSObject, NSWindowDelegate {
    private var window: NSPanel?
    private let positionKey = "qyube.timer.origin"
    private let readout = TimerReadoutModel()

    var isVisible: Bool { window?.isVisible ?? false }

    func show(remainingTime: TimeInterval) {
        readout.remainingTime = remainingTime
        if let window {
            window.orderFrontRegardless()
            return
        }

        let contentSize = CGSize(
            width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
            height: AppConstants.FloatingLayoutSettings.timerOnlyHeight
        )
        let panel = QyubeTimerPanel(
            contentRect: NSRect(origin: initialOrigin(size: contentSize), size: contentSize),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.isRestorable = false
        panel.delegate = self
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: FloatingTimerView(timer: readout))
        window = panel
        panel.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    func windowDidMove(_ notification: Notification) {
        guard let window else { return }
        UserDefaults.standard.set(NSStringFromPoint(window.frame.origin), forKey: positionKey)
    }

    func update(remainingTime: TimeInterval) {
        readout.remainingTime = remainingTime
    }

    private func initialOrigin(size: CGSize) -> CGPoint {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1280, height: 800)
        let saved = UserDefaults.standard.string(forKey: positionKey).map(NSPointFromString)
        let proposed = saved ?? CGPoint(x: visible.minX + 36, y: visible.maxY - size.height - 36)
        return CGPoint(
            x: min(max(proposed.x, visible.minX), visible.maxX - size.width),
            y: min(max(proposed.y, visible.minY), visible.maxY - size.height)
        )
    }
}

private final class QyubeTimerPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class TimerReadoutModel: ObservableObject {
    @Published var remainingTime: TimeInterval = 0
}
