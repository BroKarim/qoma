import AppKit

/// Owns the episode clock, window tracking, drawing and sound transitions together.
@MainActor
final class DistractionOverlayController {
    var onVisualStateChanged: ((DistractionVisualState?) -> Void)?
    private(set) var state: DistractionVisualState?
    private(set) var window: NSPanel?
    private(set) var surface: DistractionEffectView?
    private let frontmostPID: @MainActor () -> pid_t?
    private let locate: @MainActor (pid_t) -> DistractionTargetWindow?
    private let now: () -> Date
    private let chooseEffect: () -> DistractionEffect
    private let audio: DistractionAudioPlayer
    private var target: DistractionTargetWindow?
    private var timer: Timer?
    private var lastTrackedAt = Date.distantPast
    private var soundCursor = DistractionSoundCursor()
    private var raisedPanels: [NSWindow: NSWindow.Level] = [:]

    init(
        frontmostPID: @escaping @MainActor () -> pid_t? = {
            let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier
            return pid == ProcessInfo.processInfo.processIdentifier ? nil : pid
        },
        locate: @escaping @MainActor (pid_t) -> DistractionTargetWindow? = {
            DistractionTargetWindowLocator().frontWindow(for: $0)
        },
        now: @escaping () -> Date = Date.init,
        chooseEffect: @escaping () -> DistractionEffect = {
            [.iceFlower, .dimBright].randomElement() ?? .iceFlower
        },
        audio: DistractionAudioPlayer? = nil
    ) {
        self.frontmostPID = frontmostPID
        self.locate = locate
        self.now = now
        self.chooseEffect = chooseEffect
        self.audio = audio ?? DistractionAudioPlayer()
    }

    func show(decision: PolicyDecision) {
        guard decision.isDistraction, let pid = frontmostPID() else { hide(); return }
        if state?.ownerPID != pid {
            hide()
            state = DistractionVisualState(
                effect: chooseEffect(), startedAt: now(), seed: .random(in: .min ... .max), ownerPID: pid)
            lastTrackedAt = .distantPast
        }
        updateFrame()
        guard state != nil, timer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateFrame() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func hide() {
        timer?.invalidate()
        timer = nil
        window?.orderOut(nil)
        for (panel, level) in raisedPanels { panel.level = level }
        raisedPanels.removeAll()
        target = nil
        soundCursor = DistractionSoundCursor()
        audio.stop()
        guard state != nil else { return }
        state = nil
        onVisualStateChanged?(nil)
    }

    /// One explicit frame drives pixels and sound, even when qyube is inactive.
    func updateFrame() {
        guard let state else { return }
        guard frontmostPID() == state.ownerPID else { hide(); return }
        let date = now()
        if date.timeIntervalSince(lastTrackedAt) >= 0.1 || target == nil {
            lastTrackedAt = date
            guard let next = locate(state.ownerPID) else { hide(); return }
            ensureWindow()
            surface?.occludedRegions = next.occludedRegions
            if target != next || window?.isVisible != true {
                window?.setFrame(next.frame, display: true, animate: false)
                // Keep normal app content below the effect, and the floating timer above it.
                window?.level = NSWindow.Level(rawValue: next.level + 1)
                window?.orderFrontRegardless()
            }
            // WindowServer composites the sprites' alpha over the veil; never cut a rectangular hole for them.
            for panel in NSApp.windows where panel !== window && panel.isVisible
                && panel.level.rawValue >= NSWindow.Level.floating.rawValue {
                guard panel.level.rawValue <= next.level + 1 else { continue }
                if raisedPanels[panel] == nil { raisedPanels[panel] = panel.level }
                panel.level = NSWindow.Level(rawValue: next.level + 2)
            }
            let firstFrame = target == nil
            target = next
            if firstFrame { onVisualStateChanged?(state) }
        }
        guard let surface, window?.isVisible == true else { return }
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let elapsed = max(0, date.timeIntervalSince(state.startedAt))
        surface.render(state: state, elapsed: elapsed, reduceMotion: reduceMotion)
        if let cue = soundCursor.advance(effect: state.effect, elapsed: elapsed, reduceMotion: reduceMotion) {
            audio.play(cue)
        }
    }

    private func ensureWindow() {
        guard window == nil else { return }
        let panel = DistractionPanel(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isRestorable = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        let view = DistractionEffectView(frame: .zero)
        view.autoresizingMask = [.width, .height]
        view.setAccessibilityElement(false)
        panel.contentView = view
        surface = view
        window = panel
    }
}

private final class DistractionPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
