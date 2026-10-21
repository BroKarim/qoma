import Cocoa
import Combine
import SwiftUI

/// Owns the movable focus timer and its completion and break presentations.
@MainActor
final class FloatingTimerController: NSObject, NSWindowDelegate {
    private enum Presentation { case focus, completion, breakRunning, breakFinished }

    private var window: NSPanel?
    private let positionKey = "qyube.timer.origin"
    private let readout = TimerReadoutModel()
    private var presentation = Presentation.focus
    private var completedSession: FocusSession?
    private var breakDeadline: Date?
    private var breakTimer: Timer?
    private var onTogglePause: (() -> Bool)?
    private var onStop: (() -> Void)?
    private var onEdit: (() -> Void)?
    private var onRepeat: ((FocusSession) -> Bool)?
    private var onReview: ((FocusSession) -> Void)?
    var onBreakChanged: (() -> Void)?

    var isVisible: Bool { window?.isVisible ?? false }
    var isShowingFocus: Bool { presentation == .focus }
    var isOnBreak: Bool { presentation == .breakRunning || presentation == .breakFinished }
    var isBreakFinished: Bool { presentation == .breakFinished }
    var breakRemaining: TimeInterval { readout.breakRemaining }

    func configure(
        onTogglePause: @escaping () -> Bool,
        onEdit: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onRepeat: @escaping (FocusSession) -> Bool,
        onReview: @escaping (FocusSession) -> Void
    ) {
        self.onTogglePause = onTogglePause
        self.onEdit = onEdit
        self.onStop = onStop
        self.onRepeat = onRepeat
        self.onReview = onReview
    }

    func show(remainingTime: TimeInterval, title: String, isPaused: Bool) {
        if isOnBreak {
            breakTimer?.invalidate()
            breakTimer = nil
            breakDeadline = nil
            completedSession = nil
            onBreakChanged?()
        }
        readout.remainingTime = remainingTime
        readout.taskTitle = title
        readout.isPaused = isPaused
        if presentation != .focus || window?.contentView == nil {
            presentation = .focus
            let panel = preparePanel(size: CGSize(
                width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
                height: AppConstants.FloatingLayoutSettings.timerOnlyHeight))
            panel.contentView = NSHostingView(rootView: FloatingTimerView(
                timer: readout,
                onTogglePause: { [weak self] in self?.onTogglePause?() ?? false },
                onEdit: { [weak self] in self?.onEdit?() },
                onStop: { [weak self] in self?.onStop?() }))
        }
        window?.orderFrontRegardless()
    }

    func update(remainingTime: TimeInterval, title: String, isPaused: Bool) {
        guard presentation == .focus else { return }
        readout.remainingTime = remainingTime
        readout.taskTitle = title
        readout.isPaused = isPaused
    }

    func showCompletion(session: FocusSession, catches: [CatchEvent]) {
        completedSession = session
        presentation = .completion
        let panel = preparePanel(size: CGSize(width: 280, height: 280))
        panel.contentView = NSHostingView(rootView: SessionOutcomeView(
            session: session,
            catches: catches,
            onBreak: { [weak self] in self?.startBreak() },
            onRepeat: { [weak self] in self?.repeatSession() ?? false },
            onDone: { [weak self] in self?.done() },
            onReview: { [weak self] in self?.reviewSession() }))
        panel.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    func hideFocus() {
        if presentation == .focus { hide() }
    }

    func windowDidMove(_ notification: Notification) {
        guard let window else { return }
        UserDefaults.standard.set(NSStringFromPoint(window.frame.origin), forKey: positionKey)
    }

    private func startBreak() {
        guard presentation == .completion, completedSession != nil else { return }
        // shortcut: Break lives in memory; add restoration when break persistence is designed.
        breakDeadline = Date().addingTimeInterval(5 * 60)
        readout.breakRemaining = 5 * 60
        presentation = .breakRunning
        showBreakPanel(finished: false)
        breakTimer?.invalidate()
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tickBreak() }
        }
        onBreakChanged?()
    }

    private func tickBreak() {
        guard let breakDeadline else { return }
        readout.breakRemaining = max(0, breakDeadline.timeIntervalSinceNow)
        onBreakChanged?()
        if readout.breakRemaining <= 0 { finishBreak() }
    }

    private func finishBreak() {
        guard presentation == .breakRunning else { return }
        breakTimer?.invalidate()
        breakTimer = nil
        breakDeadline = nil
        readout.breakRemaining = 0
        presentation = .breakFinished
        showBreakPanel(finished: true)
        onBreakChanged?()
    }

    private func showBreakPanel(finished: Bool) {
        let panel = preparePanel(size: CGSize(width: 260, height: 190))
        panel.contentView = NSHostingView(rootView: BreakPanelView(
            readout: readout,
            finished: finished,
            onSkip: { [weak self] in self?.finishBreak() },
            onRepeat: { [weak self] in self?.repeatSession() ?? false },
            onDone: { [weak self] in self?.done() },
            onReview: { [weak self] in self?.reviewSession() }))
        panel.orderFrontRegardless()
    }

    private func repeatSession() -> Bool {
        guard let completedSession, onRepeat?(completedSession) == true else { return false }
        breakTimer?.invalidate()
        breakTimer = nil
        breakDeadline = nil
        self.completedSession = nil
        if presentation != .focus {
            presentation = .focus
            hide()
            window?.contentView = nil
        }
        onBreakChanged?()
        return true
    }

    private func reviewSession() {
        guard let completedSession else { return }
        done()
        onReview?(completedSession)
    }

    private func done() {
        breakTimer?.invalidate()
        breakTimer = nil
        breakDeadline = nil
        completedSession = nil
        presentation = .focus
        hide()
        window?.contentView = nil
        onBreakChanged?()
    }

    private func preparePanel(size: CGSize) -> NSPanel {
        if let window {
            let top = window.frame.maxY
            let screen = window.screen ?? NSScreen.main
            let visible = screen?.visibleFrame ?? window.frame
            let x = min(max(window.frame.minX, visible.minX), visible.maxX - size.width)
            let y = min(max(top - size.height, visible.minY), visible.maxY - size.height)
            window.setFrame(NSRect(
                x: x,
                y: y,
                width: size.width,
                height: size.height), display: true)
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
            if self.presentation == .focus { self.hide() } else { self.done() }
        }
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window = panel
        return panel
    }

    private func initialOrigin(size: CGSize) -> CGPoint {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1280, height: 800)
        let saved = UserDefaults.standard.string(forKey: positionKey).map(NSPointFromString)
        let proposed = saved ?? CGPoint(x: visible.minX + 36, y: visible.maxY - size.height - 36)
        return CGPoint(
            x: min(max(proposed.x, visible.minX), visible.maxX - size.width),
            y: min(max(proposed.y, visible.minY), visible.maxY - size.height))
    }
}

private final class QyubeTimerPanel: NSPanel {
    var onDismiss: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) { onDismiss?() }
}

@MainActor
final class TimerReadoutModel: ObservableObject {
    @Published var remainingTime: TimeInterval = 0
    @Published var taskTitle = ""
    @Published var isPaused = false
    @Published var breakRemaining: TimeInterval = 0
}
