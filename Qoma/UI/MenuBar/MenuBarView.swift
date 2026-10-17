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
        VStack(spacing: 0) {
            QyubeInkHeader(title: "qyube") { moreActions }
            VStack(alignment: .leading, spacing: 15) {
                QyubeMenuBarPenguin()
                    .frame(height: 128).frame(maxWidth: .infinity)
                durationSection
                modeSection
                catchesSection
                finalizationMessage
            }
            .padding(18)
            footer
        }
        .font(.body)
        .foregroundStyle(Color.qyubeMenuInk)
        .buttonStyle(.plain)
        .frame(width: AppConstants.MenuBarSettings.panelWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color.qyubeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(QyubeInkBorder().stroke(Color.qyubeMenuInk, lineWidth: 1.3).allowsHitTesting(false))
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

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionTitle("Duration")
            Menu {
                ForEach(Array(Set([10, 15, 20, 25, 30, 45, 60, minutes])).sorted(), id: \.self) { value in
                    Button("\(value) minutes") { minutes = value }
                }
            } label: {
                HStack {
                    Text("\(hasSession ? coordinator.snapshot?.draft.plannedMinutes ?? minutes : minutes) minutes")
                    Spacer()
                    Image(systemName: isSessionPending ? "lock" : "chevron.down").font(.callout)
                }
                .padding(.horizontal, 14).frame(height: 38)
                .contentShape(Rectangle())
            }
            .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden)
            .frame(maxWidth: .infinity)
            .disabled(isSessionPending || requestingStart)
            .accessibilityLabel("Focus duration")
            .overlay(QyubeInkBorder().stroke(Color.qyubeMenuInk, lineWidth: 1))
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionTitle("Mode")
            VStack(spacing: 0) {
                Group {
                    if isSessionPending {
                        modeLabel(trailingSymbol: "lock").help("Mode cannot be changed during a session")
                    } else {
                        Menu {
                            Button("Timer only") { preferences.policy.mode = .timerOnly }
                            Button("Allowing") { preferences.policy.mode = .allowing }
                            Button("Blocking") { preferences.policy.mode = .blocking }
                        } label: { modeLabel(trailingSymbol: "chevron.down") }
                        .menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).disabled(requestingStart)
                    }
                }
                .padding(.horizontal, 14).frame(height: 40)
                if mode != .timerOnly {
                    Rectangle().fill(Color.qyubeMenuInk.opacity(0.6)).frame(height: 1).padding(.leading, 14)
                    appSummary.padding(.horizontal, 14).padding(.vertical, 9)
                }
            }
            .overlay(QyubeInkBorder().stroke(Color.qyubeMenuInk, lineWidth: 1))
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased()).font(.caption.weight(.medium)).tracking(1.5)
            .foregroundStyle(Color.qyubeAccent)
    }

    private func modeLabel(trailingSymbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: mode == .timerOnly ? "timer" : mode == .allowing ? "checkmark.shield" : "shield.slash")
            Text(modeTitle)
            Spacer()
            Image(systemName: trailingSymbol).font(.callout)
        }
        .contentShape(Rectangle())
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
                .overlay(alignment: .leading) {
                    Rectangle().fill(Color.qyubeAccent.opacity(0.3)).frame(width: 1).padding(.vertical, 3)
                }
                .disabled(isFinalizing)
                .popover(isPresented: $panelState.isEditorPresented, arrowEdge: .trailing) {
                    QyubeAppRuleEditor(mode: mode, selectedApps: selectedApps, onToggle: updateApp)
                }
        }
    }

    private var catchesSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionTitle("Today’s catches")
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
                                    .frame(width: 43, height: 36)
                                    .help(catchDescription(kind: kind, event: event))
                                    .accessibilityElement()
                                    .accessibilityLabel(catchDescription(kind: kind, event: event))
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden).frame(height: 38)
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
        HStack(spacing: 0) {
            if isRunning {
                Button(action: togglePause) {
                    Text(coordinator.isPaused ? "RESUME" : "PAUSE")
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(Color.qyubeBackground).contentShape(Rectangle())
                }
                Button(action: stopSession) {
                    Label("Stop session", systemImage: "stop.fill").labelStyle(.iconOnly)
                        .frame(width: AppConstants.MenuBarSettings.panelWidth / 5, height: 48)
                        .foregroundStyle(.white).background(Color.qyubeMenuInk)
                }
                .help("End this session and reset the timer")
            } else {
                Button(action: start) {
                    Text(requestingStart ? "STARTING…" : "START")
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .foregroundStyle(.white).background(Color.qyubeMenuInk)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(requestingStart || isSessionPending || (mode == .allowing && selectedApps.isEmpty))
            }
        }
        .font(.headline).tracking(1.3)
        .overlay(alignment: .top) { Rectangle().fill(Color.qyubeMenuInk).frame(height: 1) }
        .disabled(isFinalizing)
    }

    private func togglePause() {
        let wasPaused = coordinator.isPaused
        if wasPaused { coordinator.resumeSession() } else { coordinator.pauseSession() }
        actionError = coordinator.isPaused == wasPaused && isRunning ? "Could not save the change." : nil
    }

    private func stopSession() {
        minutes = min(60, max(1, coordinator.snapshot?.draft.plannedMinutes ?? minutes))
        actionError = coordinator.resetSession() ? nil : "Could not finish saving this session."
    }

    private var moreActions: some View {
        Menu("More actions", systemImage: "gearshape") {
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
