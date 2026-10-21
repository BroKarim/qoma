import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct NewSessionView: View {
    @ObservedObject var coordinator: SessionCoordinator
    @Binding var draft: SessionDraft
    let sourceSession: FocusSession?
    let catches: [CatchEvent]
    let onBack: () -> Void
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

                    Text(self.sourceSession == nil ? "NEW SESSION" : "SESSION DETAIL")
                        .font(.caption.weight(.medium))
                        .tracking(1.5)
                        .foregroundStyle(Color.qyubeAccent)
                    QyubeMenuBarPenguin()
                        .frame(height: 76)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)

                    if let sourceSession {
                        HStack(spacing: 6) {
                            Text(sourceSession.status == .completed ? "Completed" : "Interrupted")
                                .fontWeight(.semibold)
                            Text("·")
                            Text("\(QyubeFormat.duration(sourceSession.actualActiveSeconds)) actual")
                            Text("·")
                            Text("\(sourceSession.plannedMinutes)m planned")
                        }
                        .font(.caption)
                        .foregroundStyle(Color.qyubeAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    }

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
                                Image(systemName: "chevron.down").font(.callout)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                            .contentShape(Rectangle())
                        }
                        .menuStyle(.button)
                        .buttonStyle(.plain)
                        .menuIndicator(.hidden)
                        .accessibilityLabel("Focus duration")
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
                                    Image(systemName: "chevron.down").font(.callout)
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 40)
                                .contentShape(Rectangle())
                            }
                            .menuStyle(.button)
                            .buttonStyle(.plain)
                            .menuIndicator(.hidden)
                            .accessibilityLabel("Focus mode, \(self.modeTitle)")

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
                        Text("Choose at least one app to start.")
                            .font(.caption)
                            .foregroundStyle(Color.qyubeInterrupted)
                    }
                    if self.draft.taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Enter a session name to start.")
                            .font(.caption)
                            .foregroundStyle(Color.qyubeInterrupted)
                    }
                    if self.coordinator.snapshot != nil {
                        Text("Finish the current session before starting another.")
                            .font(.caption)
                            .foregroundStyle(Color.qyubeInterrupted)
                    }
                    if self.startFailed {
                        Text("This session could not start. Check your access and try again.")
                            .font(.caption)
                            .foregroundStyle(Color.qyubeInterrupted)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .qyubeHideNativeScrollers()
            }
            .scrollIndicators(.hidden)

            Button("START", action: self.start)
                .font(.headline)
                .tracking(1.2)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .foregroundStyle(.white)
                .background(Color.qyubeMenuInk)
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
                .disabled(!self.canStart)
                .opacity(self.canStart ? 1 : 0.55)
                .overlay(alignment: .top) { QyubeInkDivider().frame(height: 3) }
        }
        .foregroundStyle(Color.qyubeMenuInk)
        .background(Color.qyubeBackground)
        .sheet(isPresented: self.$editingApps) {
            QyubeAppRuleEditor(
                mode: self.draft.policy.mode,
                selectedApps: self.apps,
                onToggle: { id, selected in
                    self.setApp(id, selected: selected)
                    return true
                })
        }
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

private struct AppChoice: Identifiable, Sendable {
  let id: String
  let name: String
}

struct QyubeAppRuleEditor: View {
  let mode: FocusPolicyMode
  let selectedApps: Set<String>
  let onToggle: (String, Bool) -> Bool
  @Environment(\.dismiss) private var dismiss
  @State private var installedApps: [AppChoice] = []
  @State private var search = ""
  @State private var errorMessage: String?
  @State private var loading = true

  private var filteredApps: [AppChoice] {
    guard !search.isEmpty else { return installedApps }
    return installedApps.filter { $0.name.localizedStandardContains(search) }
  }

  var body: some View {
    VStack(spacing: 0) {
      QyubeInkHeader(title: "list") {
        Text(mode == .allowing ? "Allow List" : "Block List")
      }
      VStack(alignment: .leading, spacing: 16) {
        Text(mode == .allowing ? "What apps do you need?" : "What apps are blocked?")
          .font(.headline)
        HStack(spacing: 9) {
          Image(systemName: "magnifyingglass").foregroundStyle(Color.qyubeAccent)
          TextField("Search apps…", text: $search).textFieldStyle(.plain)
            .accessibilityLabel("Search applications")
          if !search.isEmpty {
            Button("Clear search", systemImage: "xmark.circle.fill") { search = "" }
              .labelStyle(.iconOnly).foregroundStyle(Color.qyubeAccent)
          }
        }
        .padding(.horizontal, 12).frame(height: 42)
        .overlay(QyubeInkBorder().stroke(Color.qyubeMenuInk, lineWidth: 1))
        Text("Changes apply immediately").font(.caption).foregroundStyle(Color.qyubeAccent)
      }
      .padding(18)
      QyubeInkDivider().frame(height: 3)
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(filteredApps) { app in
            Button { setApp(app.id, selected: !selectedApps.contains(app.id)) } label: {
              HStack(spacing: 12) {
                AppIcon(bundleID: app.id).frame(width: 27, height: 27)
                Text(app.name).lineLimit(1)
                Spacer(minLength: 4)
                Text("App").font(.callout).foregroundStyle(Color.qyubeAccent)
                Image(systemName: selectedApps.contains(app.id) ? "checkmark.square.fill" : "square")
                  .font(.title3).foregroundStyle(Color.qyubeAccent)
              }
              .padding(.horizontal, 18).frame(height: 51)
              .frame(maxWidth: .infinity).contentShape(Rectangle())
              .background(selectedApps.contains(app.id) ? Color.qyubeSelection.opacity(0.55) : .clear)
            }
            .accessibilityLabel(app.name)
            .accessibilityValue(selectedApps.contains(app.id) ? "Selected" : "Not selected")
            .accessibilityHint("Toggle application in this list")
            .overlay(alignment: .bottom) {
              Rectangle().fill(Color.qyubeAccent.opacity(0.45)).frame(height: 1)
            }
          }
          if loading {
            ProgressView().frame(maxWidth: .infinity).padding()
          } else if filteredApps.isEmpty {
            Text("No matching applications.").foregroundStyle(.secondary).padding(18)
          }
        }
        .qyubeHideNativeScrollers()
      }
      .scrollIndicators(.hidden)
      if let errorMessage {
        Text(errorMessage).font(.callout).foregroundStyle(.red).padding(.horizontal, 18).padding(.top, 8)
      }
      Button("Choose application…", systemImage: "plus", action: chooseApplication)
        .foregroundStyle(Color.qyubeAccent)
        .frame(maxWidth: .infinity).padding(12)
      Button { dismiss() } label: {
        Text("DONE").font(.headline).tracking(1.3)
          .frame(maxWidth: .infinity).frame(height: 48)
          .foregroundStyle(.white).background(Color.qyubeMenuInk)
      }
      .keyboardShortcut(.defaultAction)
    }
    .buttonStyle(.plain)
    .foregroundStyle(Color.qyubeMenuInk)
    .frame(width: 310, height: 510).background(Color.qyubeBackground)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(QyubeInkBorder().stroke(Color.qyubeMenuInk, lineWidth: 1.3)
      .padding(2).allowsHitTesting(false))
    .environment(\.colorScheme, .light)
    .task { await loadApps() }
  }

  private func loadApps() async {
    let selectedApps = selectedApps
    let mainBundleID = Bundle.main.bundleIdentifier
    let choices = await Task.detached {
      Self.discoverApplications(selectedApps: selectedApps, excluding: mainBundleID)
    }.value
    installedApps = choices
    loading = false
  }

  nonisolated private static func discoverApplications(
    selectedApps: Set<String>,
    excluding mainBundleID: String?
  ) -> [AppChoice] {
    var choices: [String: AppChoice] = [:]
    let roots = [
      URL(fileURLWithPath: "/Applications"),
      URL(fileURLWithPath: "/System/Applications"),
      FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications"),
    ]
    for root in roots {
      guard let enumerator = FileManager.default.enumerator(
        at: root,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
      ) else { continue }
      for case let url as URL in enumerator where url.pathExtension == "app" {
        guard let bundle = Bundle(url: url),
              let id = bundle.bundleIdentifier,
              id != mainBundleID else { continue }
        choices[id] = AppChoice(id: id, name: url.deletingPathExtension().lastPathComponent)
      }
    }
    for id in selectedApps where choices[id] == nil {
      choices[id] = AppChoice(id: id, name: id)
    }
    return choices.values.sorted {
      if selectedApps.contains($0.id) != selectedApps.contains($1.id) {
        return selectedApps.contains($0.id)
      }
      return $0.name.localizedStandardCompare($1.name) == .orderedAscending
    }
  }

  private func setApp(_ id: String, selected: Bool) {
    errorMessage = onToggle(id, selected) ? nil : "Keep at least one allowed app."
  }

  private func chooseApplication() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.application]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    guard panel.runModal() == .OK, let url = panel.url,
          let bundle = Bundle(url: url), let id = bundle.bundleIdentifier,
          id != Bundle.main.bundleIdentifier else { return }
    if !installedApps.contains(where: { $0.id == id }) {
      installedApps.append(AppChoice(id: id, name: url.deletingPathExtension().lastPathComponent))
    }
    setApp(id, selected: true)
  }
}
