import AppKit
import SwiftUI

/// A click-through surface ordered directly above the offending app's front window.
@MainActor
final class DistractionOverlayController {
    var onVisualStateChanged: ((DistractionVisualState?) -> Void)?

    private let locator = DistractionTargetWindowLocator()
    private var window: NSPanel?
    private var target: DistractionTargetWindow?
    private var state: DistractionVisualState?
    private var trackingTimer: Timer?

    func show(decision: PolicyDecision) {
        guard decision.isDistraction,
            let app = NSWorkspace.shared.frontmostApplication,
            app.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else { hide(); return }

        if state?.ownerPID != app.processIdentifier {
            state = DistractionVisualState(
                effect: DistractionEffect.allCases.randomElement() ?? .iceFlower,
                startedAt: Date(),
                seed: UInt64.random(in: UInt64.min...UInt64.max),
                ownerPID: app.processIdentifier)
            target = nil
            window?.orderOut(nil)
            onVisualStateChanged?(state)
        }

        refreshTarget()
        if trackingTimer == nil {
            let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in self?.refreshTarget() }
            }
            RunLoop.main.add(timer, forMode: .common)
            trackingTimer = timer
        }
    }

    func hide() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        window?.orderOut(nil)
        target = nil
        guard state != nil else { return }
        state = nil
        onVisualStateChanged?(nil)
    }

    private func refreshTarget() {
        guard let state else { return }
        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == state.ownerPID else {
            hide()
            return
        }
        guard let nextTarget = locator.frontWindow(for: state.ownerPID) else {
            window?.orderOut(nil)
            target = nil
            return
        }

        ensureWindow(for: state, target: nextTarget)
        guard let window else { return }
        if target?.frame != nextTarget.frame {
            window.setFrame(nextTarget.frame, display: true, animate: false)
        }
        window.level = NSWindow.Level(rawValue: nextTarget.level)
        // Use the target's own WindowServer order, so unrelated windows above it
        // continue to occlude this visual cue. No display-sized floating panel.
        window.order(.above, relativeTo: nextTarget.number)
        target = nextTarget
    }

    private func ensureWindow(for state: DistractionVisualState, target: DistractionTargetWindow) {
        if let window {
            if let hostingView = window.contentView as? NSHostingView<DistractionOverlayContentView>,
                hostingView.rootView.state != state
            {
                hostingView.rootView = DistractionOverlayContentView(state: state)
            }
            return
        }

        let panel = NSPanel(
            contentRect: target.frame,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false
        panel.isRestorable = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.contentView = NSHostingView(rootView: DistractionOverlayContentView(state: state))
        window = panel
    }
}

struct DistractionOverlayContentView: View {
    let state: DistractionVisualState
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage("qyube.reduceMotionOverride") private var reduceMotionOverride = false

    private var reduceMotion: Bool { systemReduceMotion || reduceMotionOverride }

    var body: some View {
        let interval = state.effect == .dimBright && !reduceMotion ? 1.0 / 30 : 0.25
        TimelineView(.animation(minimumInterval: interval)) { timeline in
            let elapsed = max(0, timeline.date.timeIntervalSince(state.startedAt))
            GeometryReader { geometry in
                ZStack {
                    switch state.effect {
                    case .iceFlower:
                        IceFlowerField(seed: state.seed, elapsed: elapsed, reduceMotion: reduceMotion)
                    case .dimBright:
                        Color.black.opacity(reduceMotion ? 0.2 : 0.35 * DistractionMotion.dimStrength(elapsed: elapsed))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .accessibilityHidden(true)
    }
}

private struct IceFlowerField: View {
    let seed: UInt64
    let elapsed: TimeInterval
    let reduceMotion: Bool

    var body: some View {
        Canvas { context, size in
            let flowers = IceFlowerSpec.make(seed: seed)
            let count = DistractionMotion.iceFlowerCount(elapsed: elapsed)
            for index in 0..<count {
                let flower = flowers[index]
                let appearanceTime: TimeInterval = index < 6 ? 0 : Double(((index - 6) / 4) + 1) * 10
                let fade = reduceMotion ? 1 : min(1, max(0, (elapsed - appearanceTime) / 0.6))
                guard fade > 0 else { continue }
                let center = CGPoint(x: size.width * flower.x, y: size.height * flower.y)
                let path = flower.path(at: center)
                context.stroke(
                    path,
                    with: .color(Color(red: 0.25, green: 0.72, blue: 0.92).opacity(flower.opacity * fade)),
                    style: StrokeStyle(lineWidth: 1.35, lineCap: .round, lineJoin: .round))
            }
        }
        .allowsHitTesting(false)
    }
}

private struct IceFlowerSpec {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let rotation: CGFloat
    let opacity: Double

    static func make(seed: UInt64) -> [Self] {
        var generator = SnowflakeRandom(seed: seed)
        return (0..<24).map { _ in
            Self(
                x: 0.05 + 0.9 * generator.unit(),
                y: 0.06 + 0.88 * generator.unit(),
                radius: 17 + 14 * generator.unit(),
                rotation: .pi * generator.unit(),
                opacity: 0.65 + 0.25 * Double(generator.unit()))
        }
    }

    func path(at center: CGPoint) -> Path {
        var path = Path()
        for arm in 0..<6 {
            let angle = rotation + CGFloat(arm) * .pi / 3
            let dx = cos(angle)
            let dy = sin(angle)
            path.move(to: center)
            path.addLine(to: CGPoint(x: center.x + dx * radius, y: center.y + dy * radius))
            for fraction in [CGFloat(0.47), 0.72] {
                let pivot = CGPoint(x: center.x + dx * radius * fraction, y: center.y + dy * radius * fraction)
                for sign in [CGFloat(-1), CGFloat(1)] {
                    let branchAngle = angle + sign * .pi / 3
                    let length = radius * (fraction < 0.5 ? 0.21 : 0.17)
                    path.move(to: pivot)
                    path.addLine(to: CGPoint(
                        x: pivot.x + cos(branchAngle) * length,
                        y: pivot.y + sin(branchAngle) * length))
                }
            }
        }
        return path
    }
}

private struct SnowflakeRandom {
    private var value: UInt64

    init(seed: UInt64) { value = seed }

    mutating func unit() -> CGFloat {
        value &+= 0x9E3779B97F4A7C15
        var z = value
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z ^= z >> 31
        return CGFloat(Double(z >> 11) / Double(1 << 53))
    }
}
