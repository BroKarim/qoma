import AppKit
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

    var accountID = "signed-out"

    func refresh() {
        self.history = SessionRepository.shared.loadHistory(accountID: accountID)
            .sorted { $0.startedAt > $1.startedAt }
        self.catches = CatchRepository.shared.listBanked(accountID: accountID)
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
    @ObservedObject var access: AccessCoordinator
    let onSessionStarted: () -> Void
    let onBackToSession: () -> Void
    let onQuit: () -> Void

    @AppStorage(AppConstants.AnalyticsSettings.analyticsConsentDecidedKey)
    private var analyticsConsentDecided = false
    @AppStorage(AppConstants.MenuBarSettings.selectedPresetMinutesKey)
    private var selectedPresetMinutes = AppConstants.MenuBarSettings.defaultPresetMinutes
    @State private var isAnalyticsConsentPresented = false
    @State private var isLocalImportPresented = false
    @State private var importError: String?
    @State private var isSessionFormPresented = false
    @State private var isEditingActiveSession = false
    @State private var shouldRestoreSessionFormAfterSettings = false
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
                onToday: {
                    self.navigation.page = nil
                    self.isSessionFormPresented = self.shouldRestoreSessionFormAfterSettings
                    self.shouldRestoreSessionFormAfterSettings = false
                },
                onAnalytics: {
                    self.shouldRestoreSessionFormAfterSettings = false
                    self.isSessionFormPresented = false
                    self.navigation.page = .analytics
                },
                onCatalog: {
                    self.shouldRestoreSessionFormAfterSettings = false
                    self.isSessionFormPresented = false
                    self.navigation.page = .catalog
                },
                onSettings: {
                    self.shouldRestoreSessionFormAfterSettings =
                        self.isSessionFormPresented || self.shouldRestoreSessionFormAfterSettings
                    self.isSessionFormPresented = false
                    self.navigation.page = .settings
                },
                onQuit: self.onQuit)
            if case .trialing(let expiresAt) = access.state {
                Text("Free trial · \(max(1, Int(ceil(expiresAt.timeIntervalSinceNow / 86_400)))) days left")
                    .font(.system(size: 10, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14).padding(.vertical, 5)
                    .background(Color.qyubeSelection)
            }
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
            self.shouldRestoreSessionFormAfterSettings = false
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
            if self.access.accountID != nil && !self.analyticsConsentDecided { self.isAnalyticsConsentPresented = true }
            if self.access.accountID != nil { self.isLocalImportPresented = LocalAccountMigrator.hasLocalData() }
        }
        .onChange(of: access.accountID) { _, id in
            if id != nil && !analyticsConsentDecided { isAnalyticsConsentPresented = true }
            if id != nil { isLocalImportPresented = LocalAccountMigrator.hasLocalData() }
        }
        .alert("Import your earlier Qyube data?", isPresented: $isLocalImportPresented) {
            Button("Import") {
                guard let id = access.accountID else { return }
                do {
                    if try LocalAccountMigrator.importToAccount(id) {
                        sessionCoordinator.restore()
                        navigation.refresh()
                    }
                } catch { importError = error.localizedDescription }
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text("Sessions and catches from before sign-in will be linked to this account. A database backup is kept on this Mac.")
        }
        .alert("Import could not finish", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK") { importError = nil }
        } message: { Text(importError ?? "Your earlier data is still safe on this Mac.") }
    }

    @ViewBuilder private var detail: some View {
        if self.access.accountID == nil {
            accessGate(title: "Welcome to Qyube", detail: "Sign in to begin your free seven-day trial. No payment card is needed.", action: "Sign in") {
                Task { await self.access.beginLogin() }
            }
        } else if !self.access.canStartSession(), self.navigation.page == nil {
            accessGate(title: "Keep focusing", detail: "Your access needs renewal. Your past sessions and catches are still here.", action: "View plans") {
                NSWorkspace.shared.open(URL(string: "https://qyube.brokarim.com/pricing")!)
            }
        } else if self.isSessionFormPresented {
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
                    self.shouldRestoreSessionFormAfterSettings = false
                },
                onSaved: {
                    self.isSessionFormPresented = false
                    self.isEditingActiveSession = false
                    self.shouldRestoreSessionFormAfterSettings = false
                    self.navigation.refresh()
                },
                onStarted: {
                    self.isSessionFormPresented = false
                    self.isEditingActiveSession = false
                    self.shouldRestoreSessionFormAfterSettings = false
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
                onEditActiveSession: { self.navigation.editActiveSessionRequest = UUID() },
                onSelectSession: self.openSession)
        }
        }
    }

    private func accessGate(title: String, detail: String, action: String, onAction: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Image("CompanionPoseCompleted")
                .resizable().scaledToFit().frame(height: 145)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            Text(title).font(.system(size: 25, design: .serif))
            Text(detail).font(.system(size: 12)).foregroundStyle(.secondary)
            if let message = access.message { Text(message).font(.system(size: 11)).foregroundStyle(.red) }
            Button(action, action: onAction)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity).padding(13)
                .background(Color.qyubeMenuInk).foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            if access.accountID != nil {
                Button("Refresh access") { Task { await access.refreshAccess() } }
                    .buttonStyle(.plain).underline()
            }
            Spacer()
        }
        .padding(22)
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
