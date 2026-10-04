import Cocoa
import Combine
import SwiftUI

/// Standalone timer panel. Can be closed without stopping the session.
@MainActor
final class FloatingTimerController: NSObject, NSWindowDelegate {
    private var window: NSPanel?
    private let positionKey = "qyube.timer.origin"
    private var actions: FloatingTimerActions?
    private let readout = TimerReadoutModel()

    var isVisible: Bool { window?.isVisible ?? false }

    func configure(actions: FloatingTimerActions) {
        self.actions = actions
    }

    func show(remainingTime: TimeInterval, taskTitle: String, isPaused: Bool) {
        readout.remainingTime = remainingTime
        if let window = window {
            window.orderFrontRegardless()
            updateContent(remainingTime: remainingTime, taskTitle: taskTitle, isPaused: isPaused)
            return
        }

        let contentSize = CGSize(width: 210, height: 143)
        let panel = QyubeTimerPanel(
            contentRect: NSRect(origin: initialOrigin(size: contentSize), size: contentSize),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.appearance = NSAppearance(named: .aqua)
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.isRestorable = false
        panel.delegate = self
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let contentView = FloatingTimerContentView(
            readout: readout,
            taskTitle: taskTitle,
            isPaused: isPaused,
            actions: actions ?? FloatingTimerActions()
        )
        panel.contentView = NSHostingView(rootView: contentView)

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

    func update(remainingTime: TimeInterval, taskTitle: String, isPaused: Bool) {
        updateContent(remainingTime: remainingTime, taskTitle: taskTitle, isPaused: isPaused)
    }

    private func updateContent(remainingTime: TimeInterval, taskTitle: String, isPaused: Bool) {
        readout.remainingTime = remainingTime
        guard let hostingView = window?.contentView as? NSHostingView<FloatingTimerContentView> else { return }
        // Updating only the readout keeps an open actions menu or editor stable across ticks.
        guard hostingView.rootView.taskTitle != taskTitle || hostingView.rootView.isPaused != isPaused else { return }
        hostingView.rootView = FloatingTimerContentView(
            readout: readout,
            taskTitle: taskTitle,
            isPaused: isPaused,
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

private final class QyubeTimerPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

struct FloatingTimerActions {
    var onClose: () -> Void = {}
    var onPause: () -> Void = {}
    var onResume: () -> Void = {}
    var onStop: () -> Void = {}
    var onTaskChange: (String) -> Void = { _ in }
}

struct FloatingTimerContentView: View {
    let readout: TimerReadoutModel
    let taskTitle: String
    let isPaused: Bool
    let actions: FloatingTimerActions
    @State private var editingTitle: String = ""
    @State private var confirmingStop = false
    @State private var editingTask = false
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Button(action: actions.onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hide timer panel")
                Spacer()
                Menu {
                    Button(isPaused ? "Resume" : "Pause") {
                        if isPaused { actions.onResume() } else { actions.onPause() }
                    }
                    Button("Stop session", role: .destructive) { confirmingStop = true }
                    Divider()
                    Button("Edit task…") {
                        editingTitle = taskTitle
                        editingTask = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .accessibilityLabel("Session actions")
            }

            TimerReadout(model: readout)

            if isPaused {
                Text("Paused")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.qyubeAccent)
            }
        }
        .padding(14)
        .frame(width: 210, height: 143)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 8)
        )
        .popover(isPresented: $editingTask) {
            VStack(alignment: .leading, spacing: 12) {
                Text("What are you working on?").font(.headline)
                TextField("Focus session", text: $editingTitle).textFieldStyle(.roundedBorder)
                    .focused($isTitleFocused)
                    .onSubmit { actions.onTaskChange(editingTitle); editingTask = false }
                Button("Save") { actions.onTaskChange(editingTitle); editingTask = false }
                    .keyboardShortcut(.defaultAction)
            }.padding(18).frame(width: 230)
        }
        .confirmationDialog("Stop this session?", isPresented: $confirmingStop) {
            Button("Stop session", role: .destructive, action: actions.onStop)
            Button("Keep focusing", role: .cancel) {}
        } message: {
            Text("Catches are returned to the sea if you have focused for less than five minutes.")
        }
    }

}

@MainActor
final class TimerReadoutModel: ObservableObject {
    @Published var remainingTime: TimeInterval = 0
}

private struct TimerReadout: View {
    @ObservedObject var model: TimerReadoutModel
    var body: some View {
        Text(QyubeFormat.countdown(model.remainingTime))
            .font(.system(size: 42, weight: .medium, design: .rounded))
            .monospacedDigit().foregroundStyle(Color.qyubeInk)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Time remaining \(QyubeFormat.countdown(model.remainingTime))")
    }
}
