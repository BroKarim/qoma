import SwiftUI

struct MenuBarView: View {
    @ObservedObject var coordinator: SessionCoordinator
    @ObservedObject var panelState: MenuBarPanelState
    @ObservedObject var preferences: FocusPreferences
    let onStart: (Int) async -> Bool
    let onOpen: () -> Void
    let onSettings: () -> Void
    let onShowTimer: () -> Void
    let loadCatches: () -> [CatchEvent]

    @AppStorage(AppConstants.MenuBarSettings.selectedPresetMinutesKey)
    private var minutes = AppConstants.MenuBarSettings.defaultPresetMinutes
    @AppStorage(AppConstants.QuickPresets.preset1Key) private var preset1 = AppConstants.QuickPresets.defaultValues[0]
    @AppStorage(AppConstants.QuickPresets.preset2Key) private var preset2 = AppConstants.QuickPresets.defaultValues[1]
    @AppStorage(AppConstants.QuickPresets.preset3Key) private var preset3 = AppConstants.QuickPresets.defaultValues[2]
    @State private var actionError: String?
    @State private var requestingStart = false
    @State private var catches: [CatchEvent] = []

    private var isRunning: Bool { coordinator.isActive || coordinator.isPaused }
    private var hasSession: Bool { coordinator.snapshot != nil }
    private var isSessionPending: Bool { hasSession || coordinator.finalizationState != .idle }
    private var mode: FocusPolicyMode { hasSession ? coordinator.currentPolicy.mode : preferences.policy.mode }
    private var policy: SessionPolicy { hasSession ? coordinator.currentPolicy : preferences.policy }
    private var selectedApps: Set<String> { mode == .allowing ? policy.allowedApps : policy.blockedApps }
    private var isFinalizing: Bool { coordinator.finalizationState != .idle }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ruler
            if !isSessionPending { presets }
            modeSection
            if mode != .timerOnly { appSummary }
            catchesSection
            finalizationMessage
            footer
        }
        .font(.body)
        .foregroundStyle(Color.qyubeInk)
        .buttonStyle(.plain)
        .padding(16)
        .frame(width: AppConstants.MenuBarSettings.panelWidth)
        .background(Color.qyubeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.qyubeAccent.opacity(0.45)))
        .environment(\.colorScheme, .light)
        .background {
            GeometryReader { geometry in
                Color.clear.preference(key: MenuBarHeightKey.self, value: geometry.size.height)
            }
        }
        .onPreferenceChange(MenuBarHeightKey.self) { panelState.panelHeight = max(160, $0) }
        .onAppear { minutes = min(60, max(1, minutes)); reloadCatches() }
        .onReceive(NotificationCenter.default.publisher(for: .qyubeCollectionChanged)) { _ in reloadCatches() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in reloadCatches() }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in reloadCatches() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)) { _ in
            reloadCatches()
        }
        .onChange(of: coordinator.catchesRevision) { _, _ in reloadCatches() }
    }

    private var ruler: some View {
        let progress = isRunning
            ? coordinator.remainingTime / max(1, Double(coordinator.snapshot?.draft.plannedMinutes ?? 25) * 60)
            : Double(minutes - 1) / 59
        return MenuBarRuler(progress: progress)
            .frame(height: 30)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                guard !isSessionPending else { return }
                minutes = min(60, max(1, Int(1 + 59 * drag.location.x / rulerWidth)))
            })
            .accessibilityLabel(isRunning ? "Focus time remaining" : "Focus duration")
            .accessibilityValue(isRunning ? QyubeFormat.countdown(coordinator.remainingTime) : "\(minutes) minutes")
            .accessibilityAdjustableAction { direction in
                guard !isSessionPending else { return }
                switch direction {
                case .increment: minutes = min(60, minutes + 1)
                case .decrement: minutes = max(1, minutes - 1)
                @unknown default: break
                }
            }
    }

    private var presets: some View {
        HStack(spacing: 8) {
            ForEach(Array([preset1, preset2, preset3].enumerated()), id: \.offset) { _, value in
                let preset = min(60, max(1, value))
                Button("\(preset)m") { minutes = preset }
                    .foregroundStyle(minutes == preset ? Color.qyubeInk : .secondary)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(minutes == preset ? Color.qyubeSelection : .clear, in: Capsule())
                    .accessibilityAddTraits(minutes == preset ? .isSelected : [])
            }
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mode").font(.callout).foregroundStyle(.secondary)
            Group {
                if isSessionPending {
                    modeLabel(trailingSymbol: "lock.fill").help("Mode cannot be changed during a session")
                } else {
                    Menu {
                        Button("Timer only") { preferences.policy.mode = .timerOnly }
                        Button("Allowing") { preferences.policy.mode = .allowing }
                        Button("Blocking") { preferences.policy.mode = .blocking }
                    } label: { modeLabel(trailingSymbol: "chevron.down") }
                    .menuStyle(.borderlessButton).menuIndicator(.hidden).disabled(isFinalizing)
                }
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(Color.qyubeSelection.opacity(0.65), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.qyubeAccent.opacity(0.55)))
        }
    }

    private func modeLabel(trailingSymbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: mode == .timerOnly ? "timer" : "checkmark.shield").foregroundStyle(Color.qyubeAccent)
            Text(modeTitle)
            Spacer()
            Image(systemName: trailingSymbol).font(.caption).foregroundStyle(Color.qyubeAccent)
        }
        .contentShape(Rectangle())
        .frame(width: rulerWidth - 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Focus mode, \(modeTitle)")
    }

    private var appSummary: some View {
        HStack(spacing: 7) {
            ForEach(Array(selectedApps.sorted().prefix(5)), id: \.self) { bundleID in
                AppIcon(bundleID: bundleID).frame(width: 25, height: 25).help(appName(for: bundleID))
            }
            if selectedApps.count > 5 {
                Text("+\(selectedApps.count - 5)").font(.callout).foregroundStyle(.secondary)
            } else if selectedApps.isEmpty {
                Text(mode == .allowing ? "Choose at least one app" : "No apps blocked")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Edit apps", systemImage: "pencil") { panelState.isEditorPresented = true }
                .labelStyle(.iconOnly).foregroundStyle(Color.qyubeAccent)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color.qyubeAccent.opacity(0.55)))
                .disabled(isFinalizing)
                .popover(isPresented: $panelState.isEditorPresented, arrowEdge: .trailing) {
                    QyubeAppRuleEditor(mode: mode, selectedApps: selectedApps, onToggle: updateApp)
                }
        }
    }

    private var catchesSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Today’s catches").font(.callout).foregroundStyle(.secondary)
            if catches.isEmpty {
                Text("No catches today. Start a focus session.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 8) {
                        ForEach(catches) { event in
                            if let kind = CatalogDefinitions.kind(id: event.kindID) {
                                QyubeCatchArt(kindID: event.kindID, catalog: false)
                                    .frame(width: 36, height: 32)
                                    .help(catchDescription(kind: kind, event: event))
                                    .accessibilityElement()
                                    .accessibilityLabel(catchDescription(kind: kind, event: event))
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden).frame(height: 34)
            }
        }
    }

    @ViewBuilder private var finalizationMessage: some View {
        switch coordinator.finalizationState {
        case .idle:
            if let actionError { Text(actionError).font(.callout).foregroundStyle(.red) }
        case .saving:
            HStack(spacing: 7) { ProgressView().controlSize(.small); Text("Saving session…") }
                .font(.callout).foregroundStyle(.secondary)
        case .failed(let message):
            HStack {
                Text(message).font(.callout).foregroundStyle(.red)
                Spacer()
                Button("Retry saving") { coordinator.retryFinalization() }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            if isRunning {
                Button("restart") {
                    minutes = min(60, max(1, coordinator.snapshot?.draft.plannedMinutes ?? minutes))
                    actionError = coordinator.resetSession() ? nil : "Could not finish saving this session."
                }
                .foregroundStyle(.secondary).help("Reset and end session")
                Button(coordinator.isPaused ? "resume" : "pause") {
                    let wasPaused = coordinator.isPaused
                    if wasPaused { coordinator.resumeSession() } else { coordinator.pauseSession() }
                    actionError = coordinator.isPaused == wasPaused && isRunning ? "Could not save the change." : nil
                }
            } else {
                Button("start") { start() }.keyboardShortcut(.defaultAction)
                    .disabled(requestingStart || isFinalizing || (mode == .allowing && selectedApps.isEmpty))
            }
            Spacer()
            moreActions
        }
        .padding(.top, 10)
        .overlay(alignment: .top) { Rectangle().fill(Color.qyubeAccent.opacity(0.25)).frame(height: 1) }
        .disabled(isFinalizing)
    }

    private var moreActions: some View {
        Menu("More actions", systemImage: "ellipsis") {
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
        }
        .labelStyle(.iconOnly).menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
    }

    private var modeTitle: String {
        switch mode {
        case .timerOnly: "Timer only"
        case .allowing: "Allowing"
        case .blocking: "Blocking"
        }
    }

    private var rulerWidth: CGFloat { AppConstants.MenuBarSettings.panelWidth - 32 }

    private func start() {
        guard !requestingStart else { return }
        requestingStart = true
        Task {
            defer { requestingStart = false }
            actionError = await onStart(minutes) ? nil : "Could not start. Check the selected apps."
        }
    }

    private func updateApp(_ bundleID: String, selected: Bool) -> Bool {
        var apps = selectedApps
        if selected { apps.insert(bundleID) } else { apps.remove(bundleID) }
        guard mode != .allowing || !apps.isEmpty else { return false }
        if isRunning {
            var allowed = policy.allowedApps
            var blocked = policy.blockedApps
            if mode == .allowing { allowed = apps } else { blocked = apps }
            guard coordinator.updateAppRules(allowedApps: allowed, blockedApps: blocked) else {
                actionError = "Could not save app changes."
                return false
            }
        }
        preferences.updateApps(apps, for: mode)
        actionError = nil
        return true
    }

    private func appName(for bundleID: String) -> String {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)?
            .deletingPathExtension().lastPathComponent ?? bundleID
    }

    private func catchDescription(kind: CatalogDefinitions.Kind, event: CatchEvent) -> String {
        "\(kind.name), caught at \(event.depositedAt.formatted(date: .omitted, time: .shortened))"
    }

    private func reloadCatches() {
        catches = Array(DailyCatchSummary.events(on: .now, from: loadCatches())
            .filter { CatalogDefinitions.kind(id: $0.kindID)?.isFish == true }
            .reversed().prefix(20))
    }
}

private struct MenuBarHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = AppConstants.MenuBarSettings.panelHeight
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct MenuBarRuler: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(0...59, id: \.self) { index in
                        Rectangle().fill(Color.qyubeAccent.opacity(index % 5 == 0 ? 0.75 : 0.28))
                            .frame(width: 1, height: index % 5 == 0 ? 20 : 10).frame(maxWidth: .infinity)
                    }
                }
                Rectangle().fill(Color(red: 0.90, green: 0.25, blue: 0.19)).frame(width: 2, height: 28)
                    .offset(x: min(1, max(0, progress)) * (geometry.size.width - 2))
            }
            .frame(height: geometry.size.height)
        }
        .accessibilityElement(children: .ignore)
    }
}
