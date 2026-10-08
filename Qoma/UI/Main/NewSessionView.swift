import AppKit
import SwiftUI

struct NewSessionView: View {
  @ObservedObject var coordinator: SessionCoordinator
  @Binding var draft: SessionDraft
  let onStarted: () -> Void
  @State private var editingApps = false
  @State private var startFailed = false
  @State private var permissionFailed = false
  @State private var requestingPermission = false

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
          if permissionFailed {
            Text("Browser access is needed to apply domain rules. Allow qyube in System Settings → Privacy & Security → Automation, then try again.")
              .font(.caption).foregroundStyle(.secondary)
          }
        }.padding(.horizontal, 22).padding(.bottom, 8)
      }
      QyubePrimaryButton(title: "Start session") {
        guard coordinator.snapshot == nil else { return }
        Task {
          requestingPermission = true
          defer { requestingPermission = false }
          let permission = await PermissionManager.shared.requestPermissionIfNeeded(
            for: draft.policy, browserBundleID: draft.domainBrowserBundleID)
          guard permission == .granted else {
            permissionFailed = true
            return
          }
          permissionFailed = false
          if coordinator.startSession(draft: draft) != nil { onStarted() } else { startFailed = true }
        }
      }.keyboardShortcut(.defaultAction).disabled(coordinator.snapshot != nil || requestingPermission).padding(22)
    }
    .sheet(isPresented: $editingApps) {
      QyubeAppRuleEditor(policy: $draft.policy, selectedDomainBrowser: $draft.domainBrowserBundleID)
    }
  }

  private var apps: Set<String> {
    draft.policy.mode == .allowing ? draft.policy.allowedApps : draft.policy.blockedApps
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
      }.scrollIndicators(.never)
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

struct QyubeAppRuleEditor: View {
  @Binding var policy: SessionPolicy
  @Binding var selectedDomainBrowser: String
  @Environment(\.dismiss) private var dismiss
  @State private var domain = ""
  @State private var installedApps: [AppChoice] = []
  @State private var search = ""

  private struct AppChoice: Identifiable {
    let id: String
    let name: String
  }
  private var selectedApps: Set<String> {
    policy.mode == .allowing ? policy.allowedApps : policy.blockedApps
  }
  private var selectedDomains: Set<String> {
    policy.mode == .allowing ? policy.allowedDomains : policy.blockedDomains
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(policy.mode == .allowing ? "Allowed apps" : "Distracting apps").font(.headline)
        Spacer()
        Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
      }
      Text("Selecting a browser applies to every website inside it.")
        .font(.caption).foregroundStyle(.secondary)
      TextField("Search apps", text: $search).textFieldStyle(.roundedBorder)
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 12) {
          ForEach(
            installedApps.filter {
              search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
            }
          ) { app in
            Toggle(
              isOn: Binding(
                get: { selectedApps.contains(app.id) }, set: { setApp(app.id, selected: $0) })
            ) {
              HStack {
                AppIcon(bundleID: app.id).frame(width: 22, height: 22)
                Text(app.name)
              }
            }.toggleStyle(.checkbox)
          }
        }
      }
      DisclosureGroup("Websites (advanced)") {
        VStack(alignment: .leading, spacing: 8) {
          Picker("Browser for website rules", selection: $selectedDomainBrowser) {
            Text("Safari").tag("com.apple.Safari")
            Text("Google Chrome").tag("com.google.Chrome")
          }.pickerStyle(.segmented)
          Text("Website rules read the active domain in the selected browser; app rules still work in other browsers.")
            .font(.caption).foregroundStyle(.secondary)
          HStack {
            TextField("example.com", text: $domain).textFieldStyle(.roundedBorder)
            Button("Add", action: addDomain).disabled(
              domain.trimmingCharacters(in: .whitespaces).isEmpty)
          }
          ForEach(selectedDomains.sorted(), id: \.self) { host in
            HStack {
              Text(host).font(.caption)
              Spacer()
              Button {
                removeDomain(host)
              } label: {
                Image(systemName: "minus.circle")
              }
              .buttonStyle(.plain).accessibilityLabel("Remove \(host)")
            }
          }
        }.padding(.top, 10)
      }
    }.padding(22).frame(width: 310, height: 440).background(.white)
      .task { loadApps() }
  }

  private func loadApps() {
    var choices: [String: AppChoice] = [:]
    let roots = [
      URL(fileURLWithPath: "/Applications"), URL(fileURLWithPath: "/System/Applications"),
      FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
    ]
    for root in roots {
      guard
        let enumerator = FileManager.default.enumerator(
          at: root, includingPropertiesForKeys: nil,
          options: [.skipsHiddenFiles, .skipsPackageDescendants])
      else { continue }
      for case let url as URL in enumerator where url.pathExtension == "app" {
        guard let bundle = Bundle(url: url), let id = bundle.bundleIdentifier else { continue }
        choices[id] = AppChoice(id: id, name: url.deletingPathExtension().lastPathComponent)
      }
    }
    for id in selectedApps where choices[id] == nil { choices[id] = AppChoice(id: id, name: id) }
    installedApps = choices.values.sorted {
      $0.name.localizedStandardCompare($1.name) == .orderedAscending
    }
  }
  private func setApp(_ id: String, selected: Bool) {
    if policy.mode == .allowing {
      if selected { policy.allowedApps.insert(id) } else { policy.allowedApps.remove(id) }
    } else {
      if selected { policy.blockedApps.insert(id) } else { policy.blockedApps.remove(id) }
    }
  }
  private func addDomain() {
    let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines)
    let host =
      URL(string: trimmed.contains("://") ? trimmed : "https://\(trimmed)")?.host ?? trimmed
    let normalized = FocusPolicyEvaluator.normalizeDomain(host)
    guard !normalized.isEmpty else { return }
    if policy.mode == .allowing {
      policy.allowedDomains.insert(normalized)
    } else {
      policy.blockedDomains.insert(normalized)
    }
    domain = ""
  }
  private func removeDomain(_ host: String) {
    if policy.mode == .allowing {
      policy.allowedDomains.remove(host)
    } else {
      policy.blockedDomains.remove(host)
    }
  }
}
