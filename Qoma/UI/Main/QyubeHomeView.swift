import Combine
import SwiftUI

@MainActor
final class QyubeNavigation: ObservableObject {
    enum Page: String, CaseIterable, Identifiable {
        case analytics, catalog, settings, about

        var id: Self {
            self
        }

        var title: String {
            rawValue.capitalized
        }

        var symbol: String {
            switch self {
            case .analytics: "chart.bar.xaxis"
            case .catalog: "archivebox"
            case .settings: "gearshape"
            case .about: "info.circle"
            }
        }
    }

    @Published var page: Page = .analytics
    @Published var selectedDay = Calendar.current.startOfDay(for: Date())
    @Published var catchRequest: UUID?
    @Published private(set) var history: [FocusSession] = []
    @Published private(set) var catches: [CatchEvent] = []

    func refresh() {
        self.history = SessionRepository.shared.loadHistory(accountID: "local")
            .sorted { $0.startedAt > $1.startedAt }
        self.catches = CatchRepository.shared.listBanked(accountID: "local")
            .sorted { $0.depositedAt > $1.depositedAt }
    }

    func showCatches(for session: FocusSession) {
        self.refresh()
        self.selectedDay = Self.resultDay(for: session, catches: self.catches)
        self.catchRequest = UUID()
        self.page = .analytics
    }

    static func resultDay(for session: FocusSession, catches: [CatchEvent], calendar: Calendar = .current) -> Date {
        let lastCatch = catches.filter { $0.sessionID == session.id && $0.isBanked }
            .map(\.depositedAt).max()
        return calendar.startOfDay(for: lastCatch ?? session.endedAt)
    }
}

struct QyubeHomeView: View {
    @ObservedObject var navigation: QyubeNavigation

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 760
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 52)
                    if !compact {
                        Text("qyube")
                            .font(.system(size: 32, design: .serif))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        Text("A CALMER\nFOCUS AHEAD")
                            .font(.system(size: 9, design: .serif)).tracking(2.5).lineSpacing(5)
                            .foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 18).padding(.bottom, 32)
                    }
                    VStack(spacing: 5) {
                        ForEach(QyubeNavigation.Page.allCases) { page in
                            Button {
                                self.navigation.page = page
                                self.navigation.catchRequest = nil
                                self.navigation.refresh()
                            } label: {
                                SettingsNavigationRow(
                                    title: compact ? "" : page.title,
                                    symbol: page.symbol,
                                    isSelected: self.navigation.page == page)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(page.title)
                            .accessibilityAddTraits(self.navigation.page == page ? .isSelected : [])
                        }
                    }
                    .padding(.horizontal, compact ? 6 : 10)
                    Spacer()
                    if !compact {
                        SettingsSidebarFooter()
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                }
                .frame(width: compact ? 52 : 220)
                .frame(maxHeight: .infinity)
                .background(Color.qyubeSidebar)
                Rectangle().fill(Color.qyubeLine).frame(width: 1)
                self.detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.qyubeBackground)
            }
            .animation(.easeInOut(duration: 0.18), value: compact)
        }
        .frame(minWidth: 640, minHeight: 580)
        .background(Color.qyubeBackground)
        .ignoresSafeArea(.container, edges: .top)
        .environment(\.colorScheme, .light)
        .tint(.qyubeAccent)
        .onAppear { self.navigation.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            self.navigation.refresh()
        }
    }

    @ViewBuilder private var detail: some View {
        switch self.navigation.page {
        case .analytics:
            AnalyticsDashboardView(
                selectedDay: self.$navigation.selectedDay,
                catchRequest: self.navigation.catchRequest)
        case .catalog:
            CatalogView(catches: self.navigation.catches)
        case .settings:
            QyubeJournalSettingsView()
        case .about:
            QyubeAboutSettingsPane()
        }
    }
}

extension Color {
    static let qyubeBackground = Color(red: 0.985, green: 0.981, blue: 0.971)
    static let qyubeSidebar = Color(red: 0.951, green: 0.953, blue: 0.943)
    static let qyubeCardBackground = Color.white
    static let qyubeInk = Color(white: 0.13)
    static let qyubeLine = Color(white: 0.88)
    static let qyubeSelection = Color(red: 0.86, green: 0.89, blue: 0.85)
    static let qyubeAccent = Color(red: 0.35, green: 0.46, blue: 0.38)
}
