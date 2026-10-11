import SwiftUI
import Combine

@MainActor
final class QyubeNavigation: ObservableObject {
    enum Page: String, CaseIterable, Identifiable {
        case analytics, insight, catalog, calendar, settings

        var id: Self { self }
        var title: String { rawValue.capitalized }
        var symbol: String {
            switch self {
            case .analytics: "chart.bar.xaxis"
            case .insight: "chart.xyaxis.line"
            case .catalog: "archivebox"
            case .calendar: "calendar"
            case .settings: "gearshape"
            }
        }
    }

    @Published var page: Page = .analytics
    @Published var selectedResult: FocusSession?
    @Published private(set) var history: [FocusSession] = []
    @Published private(set) var catches: [CatchEvent] = []

    func refresh() {
        history = SessionRepository.shared.loadHistory(accountID: "local")
            .sorted { $0.startedAt > $1.startedAt }
        catches = CatchRepository.shared.listBanked(accountID: "local")
            .sorted { $0.depositedAt > $1.depositedAt }
    }

    func showCatches(for session: FocusSession) {
        refresh()
        selectedResult = session
        page = .insight
    }
}

struct QyubeHomeView: View {
    @ObservedObject var navigation: QyubeNavigation
    @State private var settingsTab: SettingsTab = .general

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                Color.clear.frame(height: 52)
                Text("qyube")
                    .font(.qoma(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                VStack(spacing: 2) {
                    ForEach(QyubeNavigation.Page.allCases) { page in
                        Button {
                            navigation.page = page
                            if page != .insight { navigation.selectedResult = nil }
                            navigation.refresh()
                        } label: {
                            SettingsNavigationRow(
                                title: page.title, symbol: page.symbol,
                                isSelected: navigation.page == page
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(navigation.page == page ? .isSelected : [])
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
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.qyubeBackground)
        }
        .frame(minWidth: 860, minHeight: 580)
        .background(Color.qyubeBackground)
        .ignoresSafeArea(.container, edges: .top)
        .environment(\.colorScheme, .light)
        .tint(.qyubeInk)
        .onAppear { navigation.refresh() }
    }

    @ViewBuilder private var detail: some View {
        switch navigation.page {
        case .analytics:
            AnalyticsDashboardView()
        case .insight:
            InsightView(
                history: navigation.history,
                catches: navigation.catches,
                initialSession: navigation.selectedResult
            )
            .id(navigation.selectedResult?.id)
        case .catalog:
            CatalogView(catches: navigation.catches)
        case .calendar:
            AnalyticsDashboardView(calendarOnly: true)
        case .settings:
            VStack(alignment: .leading) {
                Picker("Settings", selection: $settingsTab) {
                    ForEach(SettingsTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(20)
                Group {
                    switch settingsTab {
                    case .general: QyubeGeneralSettingsPane()
                    case .appearance: AppearanceSettingsPane()
                    case .about: QyubeAboutSettingsPane()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}

extension Color {
    static let qyubeBackground = Color.white
    static let qyubeSidebar = Color(white: 0.98)
    static let qyubeCardBackground = Color.white
    static let qyubeInk = Color(white: 0.13)
    static let qyubeLine = Color(white: 0.88)
    static let qyubeSelection = Color(white: 0.95)
    static let qyubeAccent = Color(red: 0.76, green: 0.42, blue: 0.32)
}
