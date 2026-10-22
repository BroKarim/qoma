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
    @Published var sessionToReview: FocusSession?
    @Published var breakRemaining: TimeInterval?
    @Published var todayRequest: UUID?
    @Published var editActiveSessionRequest: UUID?
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
    @AppStorage(AppConstants.MenuBarSettings.selectedPresetMinutesKey)
    private var selectedPresetMinutes = AppConstants.MenuBarSettings.defaultPresetMinutes
    @State private var isAnalyticsConsentPresented = false
    @State private var isSessionFormPresented = false
    @State private var isEditingActiveSession = false
    @State private var selectedSession: FocusSession?
    @State private var sessionDraft = SessionDraft(plannedMinutes: 25, policy: .timerOnly)

    private var activeSession: ActiveSessionSnapshot? {
        guard let snapshot = self.sessionCoordinator.snapshot,
              snapshot.status == .active || snapshot.status == .paused else { return nil }
        return snapshot
    }

    var body: some View {
        VStack(spacing: 0) {
            QyubeCompactHeader(
                onToday: { self.isSessionFormPresented = false; self.navigation.page = nil },
                onAnalytics: { self.isSessionFormPresented = false; self.navigation.page = .analytics },
                onCatalog: { self.isSessionFormPresented = false; self.navigation.page = .catalog },
                onSettings: { self.isSessionFormPresented = false; self.navigation.page = .settings })
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
        .frame(width: 310, height: 510)
        .environment(\.colorScheme, .light)
        .tint(.qyubeAccent)
        .onAppear { self.navigation.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            self.navigation.refresh()
        }
        .onReceive(self.navigation.$sessionToReview.compactMap { $0 }) { session in
            self.openSession(session)
            self.navigation.sessionToReview = nil
        }
        .onReceive(self.navigation.$todayRequest.compactMap { $0 }) { _ in
            self.isSessionFormPresented = false
            self.isEditingActiveSession = false
            self.navigation.page = nil
            self.navigation.todayRequest = nil
        }
        .onReceive(self.navigation.$editActiveSessionRequest.compactMap { $0 }) { _ in
            guard let snapshot = self.activeSession else { return }
            self.sessionDraft = snapshot.draft
            self.selectedSession = nil
            self.isEditingActiveSession = true
            self.isSessionFormPresented = true
            self.navigation.page = nil
            self.navigation.editActiveSessionRequest = nil
        }
        .onReceive(self.navigation.$page.dropFirst()) { page in
            if page != nil { self.isSessionFormPresented = false }
        }
        .sheet(isPresented: self.$isAnalyticsConsentPresented) {
            AnalyticsConsentSheet { _ in self.analyticsConsentDecided = true }
        }
        .onAppear {
            if !self.analyticsConsentDecided { self.isAnalyticsConsentPresented = true }
        }
    }

    @ViewBuilder private var detail: some View {
        if self.isSessionFormPresented {
            NewSessionView(
                coordinator: self.sessionCoordinator,
                draft: self.$sessionDraft,
                sourceSession: self.selectedSession,
                isEditingActiveSession: self.isEditingActiveSession,
                catches: self.navigation.catches.filter { $0.sessionID == self.selectedSession?.id },
                breakRemaining: self.navigation.breakRemaining,
                onBack: {
                    self.isSessionFormPresented = false
                    self.isEditingActiveSession = false
                },
                onSaved: {
                    self.isSessionFormPresented = false
                    self.isEditingActiveSession = false
                    self.navigation.refresh()
                },
                onStarted: {
                    self.isSessionFormPresented = false
                    self.isEditingActiveSession = false
                    self.selectedSession = nil
                    self.navigation.page = nil
                    self.onSessionStarted()
                })
        } else { switch self.navigation.page {
        case .analytics:
            AnalyticsDashboardView(
                selectedDay: self.$navigation.selectedDay,
                catchRequest: self.navigation.catchRequest)
        case .catalog:
            CatalogView().environmentObject(self.navigation)
        case .settings:
            QyubeJournalSettingsView()
        case .about:
            QyubeAboutSettingsPane()
        case nil:
            TodayView(
                sessions: self.navigation.history,
                activeSession: self.activeSession,
                remainingTime: self.sessionCoordinator.remainingTime,
                breakRemaining: self.navigation.breakRemaining,
                onCreateSession: self.createSession,
                onBackToSession: self.onBackToSession,
                onSelectSession: self.openSession)
        }
        }
    }

    private func createSession() {
        self.isEditingActiveSession = false
        self.sessionDraft = FocusPreferences.shared.draft(minutes: self.selectedPresetMinutes)
        self.sessionDraft.taskTitle = ""
        self.selectedSession = nil
        self.isSessionFormPresented = true
    }

    private func openSession(_ session: FocusSession) {
        self.isEditingActiveSession = false
        self.sessionDraft = session.draftSnapshot
        if self.sessionDraft.taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.sessionDraft.taskTitle = session.taskTitle.isEmpty ? "Focus session" : session.taskTitle
        }
        self.selectedSession = session
        self.isSessionFormPresented = true
    }
}
