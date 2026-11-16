import Cocoa
import Combine
import SwiftUI

/// Owns the movable focus timer presentation.
@MainActor
final class FloatingTimerController: NSObject, NSWindowDelegate {
    private var window: NSPanel?
    private let positionKey = "qyube.timer.origin"
    private let readout = TimerReadoutModel()
    private var onTogglePause: (() -> Bool)?
    private var onStop: (() -> Void)?
    private var onEdit: (() -> Void)?
    private var onToday: (() -> Void)?

    var isVisible: Bool {
        self.window?.isVisible ?? false
    }

    func configure(
        onTogglePause: @escaping () -> Bool,
        onEdit: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onToday: @escaping () -> Void)
    {
        self.onTogglePause = onTogglePause
        self.onEdit = onEdit
        self.onStop = onStop
        self.onToday = onToday
    }

    func show(remainingTime: TimeInterval, title: String, isPaused: Bool) {
        self.readout.remainingTime = remainingTime
        self.readout.taskTitle = title
        self.readout.isPaused = isPaused
        if self.window?.contentView == nil {
            let panel = self.preparePanel(size: CGSize(
                width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
                height: AppConstants.FloatingLayoutSettings.timerOnlyHeight))
            panel.contentView = NSHostingView(rootView: FloatingTimerView(
                timer: self.readout,
                onTogglePause: { [weak self] in self?.onTogglePause?() ?? false },
                onEdit: { [weak self] in self?.onEdit?() },
                onStop: { [weak self] in self?.onStop?() }))
        }
        self.window?.orderFrontRegardless()
    }

    func update(remainingTime: TimeInterval, title: String, isPaused: Bool) {
        self.readout.remainingTime = remainingTime
        self.readout.taskTitle = title
        self.readout.isPaused = isPaused
    }

    func showCompletion() {
        self.hide()
        self.onToday?()
    }

    func hide() {
        self.window?.orderOut(nil)
    }

    func hideFocus() {
        self.hide()
    }

    func windowDidMove(_ notification: Notification) {
        guard let window else { return }
        UserDefaults.standard.set(NSStringFromPoint(window.frame.origin), forKey: self.positionKey)
    }

    private func preparePanel(size: CGSize, animate: Bool = false) -> NSPanel {
        if let window {
            let frame = window.frame
            let visible = (window.screen ?? NSScreen.main)?.visibleFrame ?? frame
            let anchorRight = abs(visible.maxX - frame.maxX) < abs(frame.minX - visible.minX)
            let anchorTop = abs(visible.maxY - frame.maxY) < abs(frame.minY - visible.minY)
            let x = anchorRight ? frame.maxX - size.width : frame.minX
            let y = anchorTop ? frame.maxY - size.height : frame.minY
            let target = NSRect(
                x: min(max(x, visible.minX), max(visible.minX, visible.maxX - size.width)),
                y: min(max(y, visible.minY), max(visible.minY, visible.maxY - size.height)),
                width: size.width, height: size.height)
            assert(target.width > 0 && target.height > 0 && target.origin.x.isFinite && target.origin.y.isFinite)
            if animate, window.isVisible, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    window.animator().setFrame(target, display: true)
                }
            } else {
                window.setFrame(target, display: true)
            }
            return window
        }
        let panel = QyubeTimerPanel(
            contentRect: NSRect(origin: initialOrigin(size: size), size: size),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.isRestorable = false
        panel.delegate = self
        panel.onDismiss = { [weak self] in
            guard let self else { return }
            self.hide()
        }
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window = panel
        return panel
    }

    func resetPosition() {
        UserDefaults.standard.removeObject(forKey: positionKey)
        guard let window else { return }
        window.setFrameOrigin(initialOrigin(size: window.frame.size))
    }

    private func initialOrigin(size: CGSize) -> CGPoint {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1280, height: 800)
        let saved = UserDefaults.standard.string(forKey: self.positionKey).map(NSPointFromString)
        let proposed = saved ?? CGPoint(x: visible.minX + 36, y: visible.maxY - size.height - 36)
        return CGPoint(
            x: min(max(proposed.x, visible.minX), visible.maxX - size.width),
            y: min(max(proposed.y, visible.minY), visible.maxY - size.height))
    }
}

private final class QyubeTimerPanel: NSPanel {
    var onDismiss: (() -> Void)?
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    override func cancelOperation(_ sender: Any?) {
        self.onDismiss?()
    }
}

@MainActor
final class TimerReadoutModel: ObservableObject {
    @Published var remainingTime: TimeInterval = 0
    @Published var taskTitle = ""
    @Published var isPaused = false
}
