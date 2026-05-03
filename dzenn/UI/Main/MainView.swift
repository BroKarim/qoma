import SwiftUI

struct MainView: View {
    @State private var selection: SidebarItem? = .general
    private let columnBottomPadding: CGFloat = 6
    private let outerSidePadding: CGFloat = 6
    private let columnTopPadding: CGFloat = 6
    private let titlebarInset: CGFloat = 36

    var body: some View {
        HStack(spacing: 2) {
            self.sidebarSection
                .padding(.leading, self.outerSidePadding)
                .padding(.top, self.columnTopPadding)
                .padding(.bottom, self.columnBottomPadding)

            self.detailSection
                .padding(.trailing, self.outerSidePadding)
                .padding(.top, self.columnTopPadding)
                .padding(.bottom, self.columnBottomPadding)
        }
        .frame(minWidth: 860, minHeight: 580)
        .background(self.mainBackground.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .top)
    }

    private var sidebarSection: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: self.titlebarInset)

            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Tune focus flow and floating window.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                .padding(.bottom, 10)

                ForEach(SidebarItem.allCases) { item in
                    SidebarRow(item: item, isSelected: self.selection == item)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                self.selection = item
                            }
                        }
                }
                Spacer()
            }
            .padding(10)
        }
        .frame(width: 220)
        .frame(maxHeight: .infinity)
        .background(self.sidebarBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private var detailSection: some View {
        Group {
            switch self.selection ?? .general {
            case .general:
                GeneralSettingsView()
            case .appearance:
                FloatingAppSettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(self.mainBackground)
    }

    private var mainBackground: Color {
        .dzennBackground
    }

    private var sidebarBackground: Color {
        .dzennSidebarBackground
    }
}

private struct SidebarRow: View {
    let item: SidebarItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: self.item.systemImage)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 20)
                .foregroundColor(self.isSelected ? .white : Color.white.opacity(0.68))

            Text(self.item.title)
                .font(.system(size: 13, weight: self.isSelected ? .semibold : .regular))
                .foregroundColor(self.isSelected ? .white : Color.white.opacity(0.72))

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(self.isSelected ? Color.white.opacity(0.1) : Color.clear))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(self.isSelected ? Color.white.opacity(0.12) : Color.clear, lineWidth: 1))
        .cornerRadius(8)
        .contentShape(Rectangle())
    }
}

private enum SidebarItem: String, CaseIterable, Identifiable {
    case general, appearance
    var id: String {
        rawValue
    }

    var title: String {
        self == .general ? "General" : "Appearance"
    }

    var systemImage: String {
        self == .general ? "gearshape" : "swatchpalette"
    }
}

private struct GeneralSettingsView: View {
    var body: some View {
        DurationSelectorView()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SettingsPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(self.title)
                .font(.system(size: 28, weight: .semibold))

            Text(self.subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsSectionHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(self.title)
                .font(.system(size: 16, weight: .semibold))

            Text(self.subtitle)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsSurfaceCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            self.content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.035)))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content)
    {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        HStack(alignment: self.subtitle == nil ? .center : .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.system(size: 13.5, weight: .medium))

                if let subtitle = self.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 16)

            self.content()
        }
    }
}

struct SettingsBadge: View {
    let title: String

    var body: some View {
        Text(self.title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.06)))
    }
}
