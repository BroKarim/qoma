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
      Rectangle().fill(Color.qyubeMenuInk).frame(height: 1)
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
      }
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
    .frame(width: 330, height: 490).background(Color.qyubeBackground)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(QyubeInkBorder().stroke(Color.qyubeMenuInk, lineWidth: 1.3).allowsHitTesting(false))
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
