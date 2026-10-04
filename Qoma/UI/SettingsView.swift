import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, appearance, about

    var id: Self { self }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintpalette"
        case .about: "info.circle"
        }
    }
}

/// Native preferences window; Insight and Catalog belong to Home, not Settings.
struct SettingsView: View {
    @State private var selectedTab: SettingsTab? = .general
    @State private var history: [SettingsTab] = [.general]
    @State private var historyIndex = 0
    @State private var navigatingHistory = false

    init(initialTab: SettingsTab? = nil) {
        _selectedTab = State(initialValue: initialTab ?? .general)
        _history = State(initialValue: [initialTab ?? .general])
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List {
                ForEach(SettingsTab.allCases) { tab in
                    Button { selectedTab = tab } label: {
                        Label(tab.title, systemImage: tab.symbol)
                            .foregroundStyle(Color.qyubeInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                    .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                    .listRowBackground(selectedTab == tab ? Color.qyubeSelection : Color.clear)
                }
            }
            .listStyle(.sidebar)
            .accentColor(.qyubeInk)
            .scrollEdgeEffectStyleSoftIfAvailable()
            .navigationTitle("Settings")
            .navigationSplitViewColumnWidth(min: 185, ideal: 200, max: 220)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            Group {
                switch selectedTab ?? .general {
                case .general: QyubeGeneralSettingsPane()
                case .appearance: QyubeAppearanceSettingsPane()
                case .about: QyubeAboutSettingsPane()
                }
            }
            .navigationTitle((selectedTab ?? .general).title)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationTitle("Settings")
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 700, minHeight: 520)
        .environment(\.colorScheme, .light)
        .tint(.qyubeInk)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button { navigate(by: -1) } label: { Image(systemName: "chevron.left") }
                    .disabled(historyIndex == 0)
                    .accessibilityLabel("Previous settings page")
                Button { navigate(by: 1) } label: { Image(systemName: "chevron.right") }
                    .disabled(historyIndex >= history.count - 1)
                    .accessibilityLabel("Next settings page")
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            guard !navigatingHistory, let newValue else { return }
            guard history[historyIndex] != newValue else { return }
            history = Array(history.prefix(historyIndex + 1)) + [newValue]
            historyIndex = history.count - 1
        }
    }

    private func navigate(by offset: Int) {
        let destination = historyIndex + offset
        guard history.indices.contains(destination) else { return }
        navigatingHistory = true
        historyIndex = destination
        selectedTab = history[destination]
        DispatchQueue.main.async { navigatingHistory = false }
    }
}

private extension View {
    @ViewBuilder
    func scrollEdgeEffectStyleSoftIfAvailable() -> some View {
        if #available(macOS 26.0, *) {
            scrollEdgeEffectStyle(.soft, for: .all)
        } else {
            self
        }
    }
}
