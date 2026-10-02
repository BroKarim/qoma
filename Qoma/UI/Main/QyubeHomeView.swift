import SwiftUI

/// Main app shell for qyube: narrow sidebar, central illustration, New Session card.
struct QyubeHomeView: View {
    enum Tab: String, CaseIterable {
        case focus
        case catalog
        case insight
        case settings
    }

    @State private var selectedTab: Tab = .focus
    @ObservedObject private var access: AccessCoordinator
    @StateObject private var sessionCoordinator: SessionCoordinator

    init(access: AccessCoordinator = .shared, sessionCoordinator: SessionCoordinator? = nil) {
        self.access = access
        _sessionCoordinator = StateObject(wrappedValue: sessionCoordinator ?? SessionCoordinator())
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 72)
            centralArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            rightCard
                .frame(width: 320)
                .padding(.trailing, 24)
        }
        .frame(minWidth: 900, minHeight: 560)
        .background(Color.qyubeBackground)
        .onAppear {
            sessionCoordinator.restore()
        }
    }

    private var sidebar: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 24)

            ForEach(Tab.allCases, id: \.self) { tab in
                SidebarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color.qyubeCardBackground)
    }

    private var centralArea: some View {
        ZStack {
            Image("CompanionPoseFishing", bundle: .main)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 420)
                .opacity(0.92)
        }
    }

    private var rightCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch selectedTab {
            case .focus:
                NewSessionView(coordinator: sessionCoordinator)
            case .catalog:
                CatalogView()
            case .insight:
                InsightView()
            case .settings:
                SettingsPlaceholderView()
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.qyubeCardBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 24, x: 0, y: 8)
        )
    }
}

private struct SidebarButton: View {
    let tab: QyubeHomeView.Tab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .medium))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? .qyubeAccent : .secondary)
            .frame(width: 56, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.qyubeAccent.opacity(0.10) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch tab {
        case .focus: return "timer"
        case .catalog: return "fish.fill"
        case .insight: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }

    private var title: String {
        switch tab {
        case .focus: return "Focus"
        case .catalog: return "Catalog"
        case .insight: return "Insight"
        case .settings: return "Settings"
        }
    }
}

extension Color {
    static let qyubeBackground = Color(nsColor: NSColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1))
    static let qyubeCardBackground = Color.white
    static let qyubeAccent = Color(nsColor: NSColor(red: 0.76, green: 0.42, blue: 0.32, alpha: 1))
}
