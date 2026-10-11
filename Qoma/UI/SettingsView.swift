import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, appearance, about
    var id: Self { self }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "swatchpalette"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab

    init(initialTab: SettingsTab? = nil) {
        _selectedTab = State(initialValue: initialTab ?? .general)
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                Color.clear.frame(height: 52)
                Text("Settings")
                    .font(.qoma(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                VStack(spacing: 2) {
                    ForEach(SettingsTab.allCases) { tab in
                        Button { selectedTab = tab } label: {
                            SettingsNavigationRow(title: tab.title, symbol: tab.symbol, isSelected: selectedTab == tab)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 10)
                Spacer()
                SettingsSidebarFooter()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .frame(width: 220)
            .frame(maxHeight: .infinity)
            .background(Color.qyubeSidebar)
            Rectangle().fill(Color.qyubeLine).frame(width: 1)
            Group {
                switch selectedTab {
                case .general: GeneralSettingsPane()
                case .appearance: AppearanceSettingsPane()
                case .about: QyubeAboutSettingsPane()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 860, minHeight: 580)
        .background(Color.qyubeBackground)
        .ignoresSafeArea(.container, edges: .top)
        .environment(\.colorScheme, .light)
        .tint(.qyubeInk)
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let symbol: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.qoma(size: 14, weight: .medium))
                .frame(width: 20)
            Text(title)
                .font(.qoma(size: 13, weight: isSelected ? .semibold : .regular))
                .lineLimit(1)
            Spacer()
        }
        .foregroundStyle(isSelected ? Color.qyubeInk : Color.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 8).fill(isSelected ? Color.qyubeSelection : .clear))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.qyubeLine : .clear, lineWidth: 1))
        .contentShape(Rectangle())
    }
}

struct SettingsSidebarFooter: View {
    var body: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        Text("Version \(version) (\(build))")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
