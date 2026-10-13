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
    @State private var actionError: String?
    @State private var requestingPermission = false
    @State private var confirmingStop = false

    private var isRunning: Bool { coordinator.isActive || coordinator.isPaused }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let session = panelState.completedSession {
                completion(session)
            } else if let snapshot = coordinator.snapshot,
                      snapshot.status == .completed || snapshot.status == .interrupted {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Could not finish saving the session.")
                    Button("Retry saving") { actionError = nil; coordinator.retryFinalization() }
                    Spacer()
                    HStack { Spacer(); moreActions }
                }
                .padding(16)
            } else {
                controls
            }
        }
        .font(.system(size: 13, weight: .regular))
        .foregroundStyle(Color(white: 0.13))
        .buttonStyle(.plain)
        .frame(width: AppConstants.MenuBarSettings.panelWidth, height: AppConstants.MenuBarSettings.panelHeight)
        .background(Color(white: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.black.opacity(0.12), lineWidth: 1))
        .environment(\.colorScheme, .light)
        .confirmationDialog("Cancel this focus session?", isPresented: $confirmingStop) {
            Button("Cancel session", role: .destructive) {
                if coordinator.stopSession() == nil || coordinator.snapshot != nil {
                    actionError = "Could not save this session."
                } else {
                    actionError = nil
                }
            }
            Button("Keep focusing", role: .cancel) {}
        } message: {
            Text("Catches return to the sea if you focused for less than five minutes.")
        }
        .onAppear { minutes = min(60, max(1, minutes)) }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                if isRunning {
                    let duration = Double(coordinator.snapshot?.draft.plannedMinutes ?? 25) * 60
                    MenuBarRuler(progress: coordinator.remainingTime / duration)
                        .accessibilityLabel("Focus time remaining")
                        .accessibilityValue(QyubeFormat.countdown(coordinator.remainingTime))
                } else {
                    MenuBarRuler(progress: Double(minutes - 1) / 59)
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                            minutes = min(60, max(1, Int(1 + 59 * drag.location.x / rulerWidth)))
                        })
                        .accessibilityLabel("Focus duration")
                        .accessibilityValue("\(minutes) minutes")
                        .accessibilityAdjustableAction { direction in
                            switch direction {
                            case .increment: minutes = min(60, minutes + 1)
                            case .decrement: minutes = max(1, minutes - 1)
                            @unknown default: break
                            }
                        }
                }
            }
            .frame(height: 30)
            .padding(.top, 12)
            .padding(.bottom, 4)
            .padding(.horizontal, 10)

            HStack(spacing: 8) {
                if isRunning {
                    Button("cancel") { confirmingStop = true }.foregroundStyle(.secondary)
                    Button("restart") {
                        actionError = coordinator.restartSession() ? nil : "Could not restart this session."
                    }
                    Spacer(minLength: 0)
                    moreActions
                } else {
                    ForEach(Array([preset1, preset2, preset3].enumerated()), id: \.offset) { _, value in
                        let preset = min(60, max(1, value))
                        Button { minutes = preset } label: {
                            Text("\(preset)m")
                                .foregroundStyle(minutes == preset ? .primary : .secondary)
                                .frame(minWidth: 30)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
            if let actionError {
                Text(actionError)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal, 16)
            }
            HStack(alignment: .lastTextBaseline) {
                Button(isRunning ? (coordinator.isPaused ? "resume" : "pause") : "start") {
                    if isRunning {
                        let wasPaused = coordinator.isPaused
                        if wasPaused { coordinator.resumeSession() } else { coordinator.pauseSession() }
                        actionError = coordinator.isPaused == wasPaused && isRunning ? "Could not save the change." : nil
                    } else {
                        start(minutes: minutes)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(requestingPermission)
                Spacer(minLength: 0)
                if isRunning {
                    Text(QyubeFormat.countdown(coordinator.remainingTime))
                        .font(.system(size: 32, weight: .regular))
                        .monospacedDigit()
                        .accessibilityLabel("Time remaining")
                } else {
                    moreActions
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private var rulerWidth: CGFloat { AppConstants.MenuBarSettings.panelWidth - 20 }

    private var moreActions: some View {
        Menu {
            Button("Open qyube", action: onOpen)
            Button("Settings…", action: onSettings).keyboardShortcut(",", modifiers: .command)
            if isRunning { Button("Show floating timer", action: onShowTimer) }
            Button("Check for Updates…") { UpdaterManager.shared.checkForUpdates() }
                .disabled(!UpdaterManager.shared.canCheckForUpdates)
            Button("Contact Us") {
                if let url = URL(string: "mailto:support@qoma.app") { NSWorkspace.shared.open(url) }
            }
            Divider()
            Button("Quit") { NSApp.terminate(nil) }.keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(systemName: "ellipsis").font(.system(size: 16)).foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel("More actions")
    }

    private func start(minutes: Int) {
        guard !requestingPermission else { return }
        requestingPermission = true
        Task {
            defer { requestingPermission = false }
            let success = await onStart(minutes)
            actionError = success ? nil : "Could not start. Check focus permissions in Settings."
            if success { panelState.completedSession = nil }
        }
    }

    private func completion(_ session: FocusSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Focus complete").fontWeight(.semibold)
                Spacer()
                moreActions
            }
            Text("\(QyubeFormat.duration(session.actualActiveSeconds)) focused · \(panelState.completedCatchCount) catches")
                .font(.system(size: 11)).foregroundStyle(.secondary)
            if let actionError { Text(actionError).font(.system(size: 10)).foregroundStyle(.secondary) }
            Spacer(minLength: 0)
            HStack {
                Button("start again") { start(minutes: session.plannedMinutes) }
                    .disabled(requestingPermission)
                    .keyboardShortcut(.defaultAction)
                Spacer(minLength: 0)
                Button("Lihat hasil tangkapan") { onViewCatches(session) }
                    .font(.system(size: 11))
            }
        }
        .padding(16)
    }
}

private struct MenuBarRuler: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(0...59, id: \.self) { index in
                        Rectangle()
                            .fill(Color.gray.opacity(index % 5 == 0 ? 0.5 : 0.2))
                            .frame(width: 1, height: index % 5 == 0 ? 20 : 10)
                            .frame(maxWidth: .infinity)
                    }
                }
                Rectangle()
                    .fill(Color(red: 0.90, green: 0.25, blue: 0.19))
                    .frame(width: 2, height: 28)
                    .offset(x: min(1, max(0, progress)) * (geometry.size.width - 2))
            }
            .frame(height: geometry.size.height)
        }
        .accessibilityElement(children: .ignore)
    }
}
