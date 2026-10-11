import SwiftUI

struct MenuBarView: View {
    @ObservedObject var coordinator: SessionCoordinator
    @ObservedObject var panelState: MenuBarPanelState
    let onStart: (Int) async -> Bool
    let onOpen: () -> Void
    let onSettings: () -> Void
    let onShowTimer: () -> Void
    let onViewCatches: (FocusSession) -> Void

    @AppStorage(AppConstants.MenuBarSettings.selectedPresetMinutesKey)
    private var minutes = AppConstants.MenuBarSettings.defaultPresetMinutes
    @AppStorage(AppConstants.QuickPresets.preset1Key)
    private var preset1 = AppConstants.QuickPresets.defaultValues[0]
    @AppStorage(AppConstants.QuickPresets.preset2Key)
    private var preset2 = AppConstants.QuickPresets.defaultValues[1]
    @AppStorage(AppConstants.QuickPresets.preset3Key)
    private var preset3 = AppConstants.QuickPresets.defaultValues[2]
    @State private var startFailed = false
    @State private var actionError: String?
    @State private var requestingPermission = false
    @State private var confirmingStop = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let session = panelState.completedSession {
                completion(session)
            } else if let snapshot = coordinator.snapshot,
                      snapshot.status == .completed || snapshot.status == .interrupted {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Could not finish saving the session.")
                    Button("Retry saving") { coordinator.retryFinalization() }
                }
            } else if coordinator.snapshot != nil {
                activeControls
            } else {
                idleControls
            }
            Divider()
            HStack {
                Button("Open qyube", action: onOpen)
                Spacer()
                Menu {
                    Button("Settings…", action: onSettings)
                    Button("Show floating timer", action: onShowTimer)
                        .disabled(coordinator.snapshot == nil)
                    Divider()
                    Button("Quit qyube") { NSApp.terminate(nil) }
                } label: {
                    Image(systemName: "ellipsis").frame(width: 20, height: 20)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .accessibilityLabel("More actions")
            }
            .font(.system(size: 12))
        }
        .padding(16)
        .frame(width: 282)
        .background(.regularMaterial)
        .buttonStyle(.plain)
        .confirmationDialog("Stop this focus session?", isPresented: $confirmingStop) {
            Button("Stop session", role: .destructive) {
                if coordinator.stopSession() == nil || coordinator.snapshot != nil {
                    actionError = "Could not save this session."
                }
            }
            Button("Keep focusing", role: .cancel) {}
        } message: {
            Text("Catches return to the sea if you focused for less than five minutes.")
        }
        .onAppear { minutes = min(60, max(1, minutes)) }
    }

    private var idleControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Focus duration").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(minutes)m").monospacedDigit()
            }
            Slider(
                value: Binding(
                    get: { Double(minutes) },
                    set: { minutes = min(60, max(1, Int($0.rounded()))) }
                ),
                in: 1...60,
                step: 1
            )
            .accessibilityLabel("Focus duration")
            HStack(spacing: 18) {
                ForEach(Array([preset1, preset2, preset3].enumerated()), id: \.offset) { _, value in
                    let preset = min(60, max(1, value))
                    Button("\(preset)m") { minutes = preset }
                        .foregroundStyle(minutes == preset ? .primary : .secondary)
                }
            }
            Button {
                Task {
                    requestingPermission = true
                    defer { requestingPermission = false }
                    startFailed = !(await onStart(minutes))
                }
            } label: {
                Text("Start focus").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(requestingPermission)
            if startFailed {
                Text("Could not start. Check the focus permissions in Settings.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var activeControls: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(coordinator.isPaused ? "Paused" : "Focusing")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(QyubeFormat.countdown(coordinator.remainingTime))
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .monospacedDigit()
            }
            HStack {
                Button(coordinator.isPaused ? "Resume" : "Pause") {
                    if coordinator.isPaused {
                        coordinator.resumeSession()
                    } else {
                        coordinator.pauseSession()
                    }
                }
                Spacer()
                Button("Restart") {
                    if !coordinator.restartSession() {
                        actionError = "Could not restart this session."
                    } else {
                        actionError = nil
                    }
                }
                Spacer()
                Button("Stop") { confirmingStop = true }
            }
            .font(.system(size: 12))
            if let actionError {
                Text(actionError).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func completion(_ session: FocusSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus complete").font(.system(size: 15, weight: .semibold))
            Text("\(QyubeFormat.duration(session.actualActiveSeconds)) focused · "
                + "\(panelState.completedCatchCount) catches")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            HStack {
                Button("Start again") {
                    panelState.completedSession = nil
                    Task { startFailed = !(await onStart(minutes)) }
                }
                Spacer()
                Button("Lihat hasil tangkapan") { onViewCatches(session) }
            }
            .font(.system(size: 12))
        }
    }
}
