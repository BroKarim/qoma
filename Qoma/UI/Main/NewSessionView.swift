import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct NewSessionView: View {
  @ObservedObject var coordinator: SessionCoordinator
  @Binding var draft: SessionDraft
  let onStarted: () -> Void
  @State private var editingApps = false
  @State private var startFailed = false

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 19) {
          QyubePenguinArt().frame(height: 112).frame(maxWidth: .infinity)
          Text("New session").font(.system(size: 22, weight: .medium))
            .frame(maxWidth: .infinity)
          VStack(alignment: .leading, spacing: 8) {
            Text("What are you working on?").font(.system(size: 13))
            TextField("Task name (optional)", text: $draft.taskTitle)
              .textFieldStyle(.plain).padding(11)
              .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.qyubeLine))
          }
          VStack(alignment: .leading, spacing: 8) {
            Text("Mode").font(.system(size: 13))
            Menu {
              Button("Timer only") { draft.policy.mode = .timerOnly }
              Button("Allowing") { draft.policy.mode = .allowing }
              Button("Blocking") { draft.policy.mode = .blocking }
            } label: {
              HStack {
                Text(draft.policy.mode == .timerOnly ? "Timer only" : draft.policy.mode.rawValue.capitalized)
                Spacer()
                Image(systemName: "chevron.down").font(.system(size: 11))
              }.padding(11).frame(maxWidth: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.qyubeLine))
            }.menuStyle(.button).buttonStyle(.plain).menuIndicator(.hidden).accessibilityLabel("Focus mode")
            if draft.policy.mode != .timerOnly {
              HStack(spacing: 6) {
                ForEach(Array(apps.sorted().prefix(5)), id: \.self) { bundleID in
                  AppIcon(bundleID: bundleID).frame(width: 24, height: 24)
                }
                if apps.isEmpty {
                  Text("Choose apps").font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Edit") { editingApps = true }.buttonStyle(.plain)
              }.padding(.vertical, 5)
            }
          }
          VStack(alignment: .leading, spacing: 9) {
            HStack {
              Text("Duration")
              Spacer()
              Text("\(draft.plannedMinutes) min").monospacedDigit()
            }.font(.system(size: 13))
            DurationRuler(selection: $draft.plannedMinutes)
          }
          if startFailed {
            Text("This session could not start. Check your access and try again.")
              .font(.caption).foregroundStyle(.secondary)
          }
        }.padding(.horizontal, 22).padding(.bottom, 8)
      }
      .qyubeScrollIndicator()
      QyubePrimaryButton(title: "Start session") {
        guard coordinator.snapshot == nil else { return }
        if coordinator.startSession(draft: draft) != nil { onStarted() } else { startFailed = true }
      }
      .keyboardShortcut(.defaultAction)
      .disabled(coordinator.snapshot != nil || (draft.policy.mode == .allowing && apps.isEmpty))
      .padding(22)
    }
    .sheet(isPresented: $editingApps) {
      QyubeAppRuleEditor(
        mode: draft.policy.mode,
        selectedApps: apps,
        onToggle: { id, selected in
          setApp(id, selected: selected)
          return true
        })
    }
  }

  private var apps: Set<String> {
    draft.policy.mode == .allowing ? draft.policy.allowedApps : draft.policy.blockedApps
  }

  private func setApp(_ id: String, selected: Bool) {
    if draft.policy.mode == .allowing {
      if selected { draft.policy.allowedApps.insert(id) } else { draft.policy.allowedApps.remove(id) }
    } else {
      if selected { draft.policy.blockedApps.insert(id) } else { draft.policy.blockedApps.remove(id) }
    }
  }
}

struct DurationRuler: View {
  @Binding var selection: Int
  private let choices = [180] + Array(10...60)

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView(.horizontal) {
        HStack(alignment: .bottom, spacing: 0) {
          ForEach(choices, id: \.self) { minute in
            Button {
              selection = minute
            } label: {
              VStack(spacing: 6) {
                Capsule().fill(selection == minute ? Color.qyubeInk : Color.qyubeLine)
                  .frame(
                    width: selection == minute ? 3 : 1.5,
                    height: minute == 180 || minute.isMultiple(of: 5) ? 22 : 12)
                Text(minute == 180 || minute.isMultiple(of: 5) ? "\(minute)" : " ")
                  .font(.system(size: 10)).foregroundStyle(.secondary)
              }.frame(width: minute == 180 ? 38 : 20, height: 48, alignment: .bottom)
                .contentShape(Rectangle())
            }.buttonStyle(.plain).id(minute)
              .accessibilityLabel("\(minute) minutes")
              .accessibilityAddTraits(selection == minute ? .isSelected : [])
          }
        }
      }.qyubeHideNativeScrollers()
        .onAppear { proxy.scrollTo(selection == 10 ? 180 : selection, anchor: .leading) }
        .onChange(of: selection) { withAnimation { proxy.scrollTo(selection, anchor: .center) } }
    }
    .accessibilityElement(children: .ignore).accessibilityLabel("Session duration")
    .accessibilityValue("\(selection) minutes")
    .accessibilityAdjustableAction { direction in
      guard let index = choices.firstIndex(of: selection) else { return }
      if direction == .increment {
        selection = choices[min(choices.count - 1, index + 1)]
      } else if direction == .decrement {
        selection = choices[max(0, index - 1)]
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
    VStack(alignment: .leading, spacing: 14) {
      Text(mode == .allowing ? "Allowed apps" : "Blocked apps").font(.headline)
      Text("Changes apply immediately").font(.callout).foregroundStyle(.secondary)
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass").foregroundStyle(Color.qyubeAccent)
        TextField("Search apps", text: $search).textFieldStyle(.plain)
      }
      .padding(.horizontal, 10).frame(height: 34)
      .background(Color.qyubeSelection.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
      .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.qyubeAccent.opacity(0.55)))
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 4) {
          ForEach(filteredApps) { app in
            Toggle(
              isOn: Binding(
                get: { selectedApps.contains(app.id) },
                set: { setApp(app.id, selected: $0) })
            ) {
              HStack {
                AppIcon(bundleID: app.id).frame(width: 24, height: 24)
                Text(app.name)
              }
              .padding(.vertical, 6).padding(.horizontal, 8)
            }
            .toggleStyle(.checkbox)
            .background(
              selectedApps.contains(app.id) ? Color.qyubeSelection.opacity(0.55) : .clear,
              in: RoundedRectangle(cornerRadius: 7))
          }
          if loading {
            ProgressView().frame(maxWidth: .infinity).padding()
          } else if filteredApps.isEmpty {
            Text("No matching applications.").foregroundStyle(.secondary).padding()
          }
        }
      }
      .scrollIndicators(.hidden)
      if let errorMessage {
        Text(errorMessage).font(.callout).foregroundStyle(.red)
      }
      Divider()
      HStack {
        Button("Choose application…", systemImage: "plus", action: chooseApplication)
          .buttonStyle(.plain).foregroundStyle(Color.qyubeAccent)
        Spacer()
        Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
          .buttonStyle(.borderedProminent).tint(Color.qyubeAccent)
      }
    }
    .padding(18).frame(width: 310, height: 410).background(Color.qyubeBackground)
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
