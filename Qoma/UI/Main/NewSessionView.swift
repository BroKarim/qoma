import AppKit
import SwiftUI

struct NewSessionView: View {
    @ObservedObject var coordinator: SessionCoordinator
    @Binding var draft: SessionDraft
    let sourceSession: FocusSession?
    let isEditingActiveSession: Bool
    let catches: [CatchEvent]
    let onBack: () -> Void
    let onSaved: () -> Void
    let onStarted: () -> Void

    @AppStorage(AppConstants.MenuBarSettings.selectedPresetMinutesKey)
    private var selectedPresetMinutes = AppConstants.MenuBarSettings.defaultPresetMinutes
    @State private var editingApps = false
    @State private var startFailed = false

    private var apps: Set<String> {
        self.draft.policy.mode == .allowing ? self.draft.policy.allowedApps : self.draft.policy.blockedApps
    }

    private var canStart: Bool {
        !self.draft.taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && self.coordinator.snapshot == nil
            && (self.draft.policy.mode != .allowing || !self.apps.isEmpty)
    }

    private var canSaveActiveSession: Bool {
        !self.draft.taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (self.draft.policy.mode != .allowing || !self.apps.isEmpty)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Button(action: self.onBack) {
                        Label("Today", systemImage: "chevron.left")
                            .font(.callout.weight(.medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.qyubeAccent)

                    GeometryReader { geometry in
                        Image("SessionInlet")
                            .resizable().interpolation(.none)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .scaleEffect(1.08)
                            .clipped()
                    }
                        .frame(height: 130)
                        .accessibilityHidden(true)
                        .padding(.bottom, -7)

                    VStack(alignment: .leading, spacing: 7) {
                        self.sectionTitle("Session name")
                        TextField("What are you working on?", text: self.$draft.taskTitle)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                            .qyubeInkSurface(fill: .white.opacity(0.72), stroke: .qyubeMenuInk)
                            .accessibilityLabel("Session name")
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        self.sectionTitle("Duration")
                        Menu {
                            ForEach(self.durationChoices, id: \.self) { value in
                                Button("\(value) minutes") { self.draft.plannedMinutes = value }
                            }
                        } label: {
                            HStack {
                                Text("\(self.draft.plannedMinutes) minutes")
                                Spacer()
                                Image(systemName: self.isEditingActiveSession ? "lock.fill" : "chevron.down")
                                    .font(.callout)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                            .contentShape(Rectangle())
                        }
                        .menuStyle(.button)
                        .buttonStyle(.plain)
                        .menuIndicator(.hidden)
                        .disabled(self.isEditingActiveSession)
                        .accessibilityLabel(self.isEditingActiveSession
                                             ? "Focus duration, \(self.draft.plannedMinutes) minutes, locked"
                                             : "Focus duration")
                        .qyubeInkSurface(fill: .white.opacity(0.72), stroke: .qyubeMenuInk)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        self.sectionTitle("Mode")
                        VStack(spacing: 0) {
                            Menu {
                                Button("Timer only") { self.draft.policy.mode = .timerOnly }
                                Button("Allowing") { self.draft.policy.mode = .allowing }
                                Button("Blocking") { self.draft.policy.mode = .blocking }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: self.modeSymbol)
                                    Text(self.modeTitle)
                                    Spacer()
                                    Image(systemName: self.isEditingActiveSession ? "lock.fill" : "chevron.down")
                                        .font(.callout)
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 40)
                                .contentShape(Rectangle())
                            }
                            .menuStyle(.button)
                            .buttonStyle(.plain)
                            .menuIndicator(.hidden)
                            .accessibilityLabel(self.isEditingActiveSession
                                                ? "Focus mode, \(self.modeTitle), locked"
                                                : "Focus mode, \(self.modeTitle)")
                            .disabled(self.isEditingActiveSession)

                            if self.draft.policy.mode != .timerOnly {
                                QyubeInkDivider().frame(height: 3).padding(.leading, 14)
                                HStack(spacing: 7) {
                                    ForEach(Array(self.apps.sorted().prefix(5)), id: \.self) { bundleID in
                                        AppIcon(bundleID: bundleID).frame(width: 24, height: 24)
                                    }
                                    if self.apps.count > 5 {
                                        Text("+\(self.apps.count - 5)").font(.caption)
                                    } else if self.apps.isEmpty {
                                        Text(self.draft.policy.mode == .allowing
                                             ? "Choose at least one app" : "No apps blocked")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 2)
                                    Button("Edit apps", systemImage: "pencil") { self.editingApps = true }
                                        .labelStyle(.iconOnly)
                                        .foregroundStyle(Color.qyubeAccent)
                                        .popover(isPresented: self.$editingApps) {
                                            QyubeAppRuleEditor(mode: self.draft.policy.mode, selectedApps: self.apps, onToggle: { id, selected in
                                                let previous = self.draft.policy
                                                self.setApp(id, selected: selected)
                                                if self.isEditingActiveSession {
                                                    guard self.draft.policy.mode != .allowing || !self.apps.isEmpty,
                                                          self.coordinator.updateActiveSession(taskTitle: self.coordinator.currentTaskTitle, allowedApps: self.draft.policy.allowedApps, blockedApps: self.draft.policy.blockedApps) else {
                                                        self.draft.policy = previous
                                                        return false
                                                    }
                                                }
                                                return true
                                            })
                                        }
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 44)
                            }
                        }
                        .qyubeInkSurface(fill: .white.opacity(0.72), stroke: .qyubeMenuInk)
                    }

                    if self.sourceSession != nil {
                        VStack(alignment: .leading, spacing: 7) {
                            self.sectionTitle("Session catches")
                            if self.catches.isEmpty {
                                Text("No catches from this session.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            } else {
                                ScrollView(.horizontal) {
                                    HStack(spacing: 8) {
                                        ForEach(self.catches) { event in
                                            QyubeCatchArt(kindID: event.kindID)
                                                .frame(width: 43, height: 36)
                                                .accessibilityElement(children: .ignore)
                                                .accessibilityLabel(
                                                    CatalogDefinitions.kind(id: event.kindID)?.name ?? "Catch")
                                        }
                                    }
                                    .qyubeHideNativeScrollers()
                                }
                                .scrollIndicators(.hidden)
                                .frame(height: 40)
                            }
                        }
                    }

                    if self.draft.policy.mode == .allowing && self.apps.isEmpty {
                        Text(self.isEditingActiveSession
                             ? "Choose at least one app before saving."
                             : "Choose at least one app to start.")
                            .font(.caption)
                            .foregroundStyle(Color.qyubeInterrupted)
                    }
                    if self.draft.taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(self.isEditingActiveSession
                             ? "Enter a session name before saving."
                             : "Enter a session name to start.")
                            .font(.caption)
                            .foregroundStyle(Color.qyubeInterrupted)
                    }
                    if self.coordinator.snapshot != nil && !self.isEditingActiveSession {
                        Text("Finish the current session before starting another.")
                            .font(.caption)
                            .foregroundStyle(Color.qyubeInterrupted)
                    }
                    if self.startFailed {
                        Text(self.isEditingActiveSession
                             ? "Changes could not be saved. Check your access and try again."
                             : "This session could not start. Check your access and try again.")
                            .font(.caption)
                            .foregroundStyle(Color.qyubeInterrupted)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .qyubeHideNativeScrollers()
            }
            .scrollIndicators(.hidden)

            Button(self.isEditingActiveSession ? "SAVE CHANGES" : "START", action: self.isEditingActiveSession
                   ? self.saveActiveSession : self.start)
                .font(.headline)
                .tracking(1.2)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .foregroundStyle(.white)
                .background(Color.qyubeMenuInk)
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .disabled(self.isEditingActiveSession ? !self.canSaveActiveSession : !self.canStart)
                .opacity((self.isEditingActiveSession ? self.canSaveActiveSession : self.canStart) ? 1 : 0.55)
                .overlay(alignment: .top) { QyubeInkDivider().frame(height: 3) }
        }
        .foregroundStyle(Color.qyubeMenuInk)
        .background(Color.qyubeBackground)
    }

    private var modeTitle: String {
        switch self.draft.policy.mode {
        case .timerOnly: "Timer only"
        case .allowing: "Allowing"
        case .blocking: "Blocking"
        }
    }

    private var durationChoices: [Int] {
        Array(Set([10, 15, 20, 25, 30, 45, 60, self.draft.plannedMinutes])).sorted()
    }

    private var modeSymbol: String {
        switch self.draft.policy.mode {
        case .timerOnly: "timer"
        case .allowing: "checkmark.shield"
        case .blocking: "shield.slash"
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.medium))
            .tracking(1.5)
            .foregroundStyle(Color.qyubeAccent)
    }

    private func start() {
        guard self.canStart else { return }
        self.draft.taskTitle = self.draft.taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.coordinator.startSession(draft: self.draft) != nil {
            self.selectedPresetMinutes = self.draft.plannedMinutes
            var preferredPolicy = self.draft.policy
            preferredPolicy.allowedDomains = []
            preferredPolicy.blockedDomains = []
            FocusPreferences.shared.policy = preferredPolicy
            self.onStarted()
        } else {
            self.startFailed = true
        }
    }

    private func saveActiveSession() {
        guard self.canSaveActiveSession else { return }
        guard self.coordinator.updateActiveSession(
            taskTitle: self.draft.taskTitle,
            allowedApps: self.draft.policy.allowedApps,
            blockedApps: self.draft.policy.blockedApps) else {
            self.startFailed = true
            return
        }
        self.onSaved()
    }

    private func setApp(_ id: String, selected: Bool) {
        if self.draft.policy.mode == .allowing {
            if selected { self.draft.policy.allowedApps.insert(id) } else {
                self.draft.policy.allowedApps.remove(id)
            }
        } else {
            if selected { self.draft.policy.blockedApps.insert(id) } else {
                self.draft.policy.blockedApps.remove(id)
            }
        }
    }
}

struct AppIcon: View {
  let bundleID: String
  var body: some View {
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
      Image(nsImage: NSWorkspace.shared.icon(forFile: url.path)).resizable().scaledToFit()
        .accessibilityLabel(url.deletingPathExtension().lastPathComponent)
    } else {
      Image(systemName: "app.dashed").resizable().scaledToFit().accessibilityLabel(bundleID)
    }
  }
}
