import AppKit
import SwiftUI
import UniformTypeIdentifiers

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
          .font(.custom("GeistPixel-Regular", size: 13, relativeTo: .headline))
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
        Text("Changes apply immediately").font(.custom("GeistPixel-Regular", size: 12, relativeTo: .caption)).foregroundStyle(Color.qyubeAccent)
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
                Text("App").font(.custom("GeistPixel-Regular", size: 13, relativeTo: .callout)).foregroundStyle(Color.qyubeAccent)
                Image(systemName: selectedApps.contains(app.id) ? "checkmark.square.fill" : "square")
                  .font(.custom("GeistPixel-Regular", size: 17, relativeTo: .title3)).foregroundStyle(Color.qyubeAccent)
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
        Text(errorMessage).font(.custom("GeistPixel-Regular", size: 13, relativeTo: .callout)).foregroundStyle(.red).padding(.horizontal, 18).padding(.top, 8)
      }
      Button("Choose application…", systemImage: "plus", action: chooseApplication)
        .foregroundStyle(Color.qyubeAccent)
        .frame(maxWidth: .infinity).padding(12)
    }
    .font(.custom("GeistPixel-Regular", size: 13))
    .buttonStyle(.plain)
    .foregroundStyle(Color.qyubeMenuInk)
    .frame(width: 310, height: 357).background(Color.qyubeBackground)
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
