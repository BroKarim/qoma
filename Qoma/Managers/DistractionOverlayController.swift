import Cocoa
import SwiftUI

/// Temporary click-through fish overlay that appears when a distraction is detected.
/// Does not become key window, does not capture mouse, and respects Reduce Motion.
@MainActor
final class DistractionOverlayController {
    private var window: NSPanel?
    private var fadeWorkItem: DispatchWorkItem?

    func show(decision: PolicyDecision) {
        ensureWindow()
        window?.orderFrontRegardless()
        updateContent(decision: decision, intensity: 1)

        fadeWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        fadeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: workItem)
    }

    func hide() {
        window?.orderOut(nil)
        fadeWorkItem?.cancel()
        fadeWorkItem = nil
    }

    func updateIntensity(_ intensity: CGFloat) {
        guard let window = window else { return }
        updateContent(decision: nil, intensity: intensity)
        window.alphaValue = min(1.0, 0.25 + (0.15 * Double(intensity)))
    }

    private func ensureWindow() {
        guard window == nil else { return }

        let panel = NSPanel(
            contentRect: NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1280, height: 800),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false
        panel.isRestorable = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let contentView = DistractionOverlayContentView(
            decision: PolicyDecision(isDistraction: true, reason: .blockedExplicitly),
            intensity: 1,
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        )
        panel.contentView = NSHostingView(rootView: contentView)

        window = panel
    }

    private func updateContent(decision: PolicyDecision?, intensity: CGFloat) {
        guard let hostingView = window?.contentView as? NSHostingView<DistractionOverlayContentView> else { return }
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        hostingView.rootView = DistractionOverlayContentView(
            decision: decision ?? hostingView.rootView.decision,
            intensity: intensity,
            reduceMotion: reduceMotion
        )
    }
}

struct DistractionOverlayContentView: View {
    let decision: PolicyDecision
    let intensity: CGFloat
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if reduceMotion {
                    staticCue(in: geometry.size)
                } else {
                    animatedFish(in: geometry.size)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func staticCue(in size: CGSize) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "fish.fill")
                .font(.system(size: 24, weight: .medium))
            Text(labelText)
                .font(.system(size: 15, weight: .medium))
        }
        .foregroundColor(.qyubeAccent)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
        )
        .position(x: size.width * 0.5, y: size.height * 0.82)
    }

    private func animatedFish(in size: CGSize) -> some View {
        let count = min(6, max(1, Int(intensity * 3)))
        return ZStack {
            ForEach(0..<count, id: \.self) { index in
                Image(systemName: "fish.fill")
                    .font(.system(size: 18 + CGFloat(index) * 4, weight: .medium))
                    .foregroundColor(.qyubeAccent.opacity(0.6 - Double(index) * 0.08))
                    .offset(
                        x: sin(Double(index)) * 24,
                        y: cos(Double(index)) * 16
                    )
                    .animation(
                        .easeInOut(duration: 1.8 + Double(index) * 0.3)
                            .repeatForever(autoreverses: true),
                        value: UUID()
                    )
            }
        }
        .position(x: size.width * 0.5, y: size.height * 0.82)
    }

    private var labelText: String {
        switch decision.reason {
        case .blockedExplicitly, .blockedBrowser, .blockedDomain:
            return "This app/site is outside your focus rules"
        default:
            return "Stay focused"
        }
    }
}
