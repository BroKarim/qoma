import SwiftUI

// MARK: - Tab Enum

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case appearance
    case analytics
    case extensions

    var id: Self { self }

    var title: String {
        switch self {
        case .general: "General"
        case .appearance: "Appearance"
        case .analytics: "Analytics"
        case .extensions: "Extensions"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "swatchpalette"
        case .analytics: "chart.bar.xaxis"
        case .extensions: "puzzlepiece.extension"
        }
    }
}


// MARK: - Settings View

struct SettingsView: View {
    @State private var selectedTab: SettingsTab?

    init(initialTab: SettingsTab? = nil) {
        _selectedTab = State(initialValue: initialTab ?? .general)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)
            
            detail
        }
        .frame(minWidth: 860, minHeight: 580)
        // Gunakan satu warna background yang sama untuk seluruh view
        .background(Color.qomaBackground.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .top)
    }

    private var sidebar: some View {
        VStack(spacing: 0) {

            Color.clear
                .frame(height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.qoma(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Nav items — pakai VStack biasa, bukan List
            VStack(spacing: 2) {
                ForEach(SettingsTab.allCases) { tab in
                    SettingsSidebarRow(tab: tab, isSelected: selectedTab == tab)
                        .onTapGesture {
                            selectedTab = tab
                        }
                }
            }
            .padding(.horizontal, 10)

            Spacer()
        }
        .frame(width: 220)
        .frame(maxHeight: .infinity)

        .background(Color.qomaBackground)
    }

    // MARK: Detail Panel
    private var detail: some View {
        Group {
            switch selectedTab {
            case .general:
                GeneralSettingsPane()
            case .appearance:
                AppearanceSettingsPane()
            case .analytics:
                AnalyticsDashboardView()
            case .extensions:
                ExtensionsSettingsPane()
            case nil:
                Color.qomaBackground
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.qomaBackground)
        .ignoresSafeArea(.container, edges: .top)
    }
}

// MARK: - Sidebar Row
// Tidak ada lagi List selection, highlight hanya dari background custom ini

private struct SettingsSidebarRow: View {
    let tab: SettingsTab
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: tab.systemImage)
                .font(.qoma(size: 14, weight: .medium))
                .frame(width: 20)
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.55))

            Text(tab.title)
                .font(.qoma(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.65))

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.white.opacity(0.10) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.12) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        // Animasi ringan agar tidak ada lag persepsi saat ganti tab
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

