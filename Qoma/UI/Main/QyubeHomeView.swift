import Combine
import SwiftUI

@MainActor
final class QyubeNavigation: ObservableObject {
    enum Page: String, CaseIterable, Identifiable {
        case analytics, catalog, settings, about

        var id: Self { self }

        var title: String { self.rawValue.capitalized }

        var symbol: String {
            switch self {
            case .analytics: "chart.bar.xaxis"
            case .catalog: "archivebox"
            case .settings: "gearshape"
            case .about: "info.circle"
            }
        }
    }

    @Published var page: Page?
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
    @ObservedObject var sessionCoordinator: SessionCoordinator
    let onSessionStarted: () -> Void
    let onBackToSession: () -> Void

    @AppStorage(AppConstants.AnalyticsSettings.analyticsConsentDecidedKey)
    private var analyticsConsentDecided = false
    @State private var isAnalyticsConsentPresented = false
    @State private var isNewSessionPresented = false
    @State private var sessionDraft = SessionDraft(plannedMinutes: 25, policy: .timerOnly)

    private var activeSession: ActiveSessionSnapshot? {
        guard let snapshot = self.sessionCoordinator.snapshot,
              snapshot.status == .active || snapshot.status == .paused else { return nil }
        return snapshot
    }

    var body: some View {
        VStack(spacing: 0) {
            QyubeCompactHeader(
                onToday: { self.navigation.page = nil },
                onAnalytics: { self.navigation.page = .analytics },
                onCatalog: { self.navigation.page = .catalog },
                onSettings: { self.navigation.page = .settings })
            self.detail
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.qyubeBackground)
        }
        .background(Color.qyubeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            QyubeInkBorder().stroke(Color.qyubeMenuInk, lineWidth: 1.3)
                .padding(2).allowsHitTesting(false)
        }
        .frame(width: 310, height: 700)
        .environment(\.colorScheme, .light)
        .tint(.qyubeAccent)
        .onAppear { self.navigation.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            self.navigation.refresh()
        }
        .sheet(isPresented: self.$isAnalyticsConsentPresented) {
            AnalyticsConsentSheet { _ in self.analyticsConsentDecided = true }
        }
        .sheet(isPresented: self.$isNewSessionPresented) {
            NewSessionView(
                coordinator: self.sessionCoordinator,
                draft: self.$sessionDraft,
                onStarted: {
                    self.isNewSessionPresented = false
                    self.onSessionStarted()
                })
                .frame(minWidth: 360, minHeight: 520)
        }
        .onAppear {
            if !self.analyticsConsentDecided { self.isAnalyticsConsentPresented = true }
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
        case nil:
            TodayView(
                sessions: self.navigation.history,
                activeSession: self.activeSession,
                remainingTime: self.sessionCoordinator.remainingTime,
                onCreateSession: self.createSession,
                onBackToSession: self.onBackToSession)
        }
    }

    private func createSession() {
        self.sessionDraft = FocusPreferences.shared.draft(minutes: 25)
        self.isNewSessionPresented = true
    }
}
