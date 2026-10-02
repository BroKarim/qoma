import Cocoa
import SwiftUI

/// Standalone timer panel. Can be closed without stopping the session.
@MainActor
final class FloatingTimerController {
    private var window: NSPanel?
    private let positionKey = "qyube.timer.origin"
    private var actions: FloatingTimerActions?

    var isVisible: Bool { window?.isVisible ?? false }

    func configure(actions: FloatingTimerActions) {
        self.actions = actions
    }

    func show(remainingTime: TimeInterval, taskTitle: String) {
        if let window = window {
            window.orderFrontRegardless()
            updateContent(remainingTime: remainingTime, taskTitle: taskTitle)
            return
        }

        let contentSize = CGSize(width: 210, height: 160)
        let panel = NSPanel(
            contentRect: NSRect(origin: initialOrigin(size: contentSize), size: contentSize),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.isRestorable = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let contentView = FloatingTimerContentView(
            remainingTime: remainingTime,
            taskTitle: taskTitle,
            actions: actions ?? FloatingTimerActions()
        )
        panel.contentView = NSHostingView(rootView: contentView)

        window = panel
        panel.orderFrontRegardless()
    }

    func hide() {
        window?.orderOut(nil)
    }

    func update(remainingTime: TimeInterval, taskTitle: String) {
        updateContent(remainingTime: remainingTime, taskTitle: taskTitle)
    }

    private func updateContent(remainingTime: TimeInterval, taskTitle: String) {
        guard let hostingView = window?.contentView as? NSHostingView<FloatingTimerContentView> else { return }
        hostingView.rootView = FloatingTimerContentView(
            remainingTime: remainingTime,
            taskTitle: taskTitle,
            actions: actions ?? FloatingTimerActions()
        )
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

struct FloatingTimerActions {
    var onClose: () -> Void = {}
    var onPause: () -> Void = {}
    var onResume: () -> Void = {}
    var onStop: () -> Void = {}
    var onTaskChange: (String) -> Void = { _ in }
}

struct FloatingTimerContentView: View {
    let remainingTime: TimeInterval
    let taskTitle: String
    let actions: FloatingTimerActions
    @State private var editingTitle: String = ""
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Button(action: actions.onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text(formattedTime)
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)

            TextField("Focus session", text: $editingTitle)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .focused($isTitleFocused)
                .onAppear { editingTitle = taskTitle }
                .onChange(of: taskTitle) { editingTitle = taskTitle }
                .onSubmit { actions.onTaskChange(editingTitle) }

            HStack(spacing: 12) {
                Button(action: actions.onStop) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.qyubeAccent))
                }
                .buttonStyle(.plain)

                Button(action: actions.onPause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.secondary.opacity(0.12)))
                }
                .buttonStyle(.plain)

                Button(action: actions.onResume) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.secondary.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
        )
    }

    private var formattedTime: String {
        let totalSeconds = max(0, Int(remainingTime.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
