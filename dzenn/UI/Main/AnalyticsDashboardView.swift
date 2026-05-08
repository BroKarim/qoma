import AppKit
import SwiftUI

struct AnalyticsDashboardView: View {
    private let usePreviewData: Bool

    @StateObject private var permissionsManager = AnalyticsPermissionsManager()
    @State private var dashboardState: DashboardState = .loading

    init(usePreviewData: Bool = false) {
        self.usePreviewData = usePreviewData
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsPageHeader(
                    title: "Analytics",
                    subtitle: "Track your focus patterns, active apps, and session momentum.")

                self.content
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            self.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            self.loadData()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch self.dashboardState {
        case .loading:
            SettingsSurfaceCard {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Loading analytics...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .empty(let emptyState):
            self.emptyStateView(emptyState)
        case .loaded(let data):
            self.summaryCardsView(summary: data.summary)
            AnalyticsHeatmapView(cells: data.heatmapCells)
            AnalyticsTimelineView(entries: data.timelineEntries)
            AnalyticsBreakdownView(
                todayApps: data.breakdown.todayApps,
                todayDomains: data.breakdown.todayDomains,
                weekApps: data.breakdown.weekApps,
                weekDomains: data.breakdown.weekDomains)
        }
    }

    @ViewBuilder
    private func emptyStateView(_ emptyState: DashboardEmptyState) -> some View {
        switch emptyState {
        case .permissionsRequired:
            AnalyticsEmptyStateView(
                icon: "lock.shield",
                message: "Accessibility permission needed",
                subtitle: "Grant access so Dzenn can track focused apps and build real analytics.",
                actionTitle: "Open System Settings",
                action: {
                    self.permissionsManager.openSystemSettings()
                })
        case .noData:
            AnalyticsEmptyStateView()
        }
    }

    @ViewBuilder
    private func summaryCardsView(summary: AnalyticsSummary) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            SummaryCard(
                title: "Today",
                value: self.formatDuration(summary.todayFocusSeconds),
                icon: "sun.max.fill",
                color: .yellow)
            SummaryCard(
                title: "This Week",
                value: self.formatDuration(summary.weekFocusSeconds),
                icon: "calendar",
                color: .blue)
            SummaryCard(
                title: "Streak",
                value: "\(summary.streakDays) days",
                icon: "flame.fill",
                color: .orange)
        }

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            if let topApp = summary.topApps.first {
                SummaryCard(
                    title: "Top App",
                    value: topApp.name,
                    icon: "macwindow.fill",
                    color: .purple,
                    subtitle: topApp.displayDuration)
            }
            if let topDomain = summary.topDomains.first {
                SummaryCard(
                    title: "Top Website",
                    value: topDomain.name,
                    icon: "network",
                    color: .green,
                    subtitle: topDomain.displayDuration)
            }
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        if seconds < 60 {
            return "0m"
        }

        let mins = Int(seconds / 60)
        if mins >= 60 {
            let hours = mins / 60
            let remaining = mins % 60
            return "\(hours)h \(remaining)m"
        }
        return "\(mins)m"
    }

    private func loadData() {
        if self.usePreviewData {
            self.dashboardState = .loaded(self.makePreviewData())
            return
        }

        self.permissionsManager.refreshStatus()

        let sessions = AnalyticsStore.shared.loadFocusSessions()
        let appEvents = AnalyticsStore.shared.loadAppActivityEvents()
        let webVisits = AnalyticsStore.shared.loadWebsiteVisits()
        let engine = AnalyticsEngine.shared

        let data = AnalyticsDashboardData(
            summary: engine.buildSummary(from: sessions, appEvents: appEvents, webVisits: webVisits),
            heatmapCells: engine.buildHeatmapCells(from: sessions),
            timelineEntries: engine.buildTimeline(for: Date(), appEvents: appEvents, webVisits: webVisits),
            breakdown: self.makeBreakdownData(engine: engine, appEvents: appEvents, webVisits: webVisits))

        if data.hasVisibleData {
            self.dashboardState = .loaded(data)
        } else if !self.permissionsManager.canTrackApps {
            self.dashboardState = .empty(.permissionsRequired)
        } else {
            self.dashboardState = .empty(.noData)
        }
    }

    private func makePreviewData() -> AnalyticsDashboardData {
        let summary = AnalyticsPreviewFactory.makePopulatedSummary()
        return AnalyticsDashboardData(
            summary: summary,
            heatmapCells: AnalyticsPreviewFactory.makeHeatmapCells(),
            timelineEntries: AnalyticsPreviewFactory.makeTimelineEntries(),
            breakdown: AnalyticsBreakdownData(
                todayApps: AnalyticsPreviewFactory.makeBreakdownItems(),
                todayDomains: summary.topDomains,
                weekApps: summary.topApps,
                weekDomains: summary.topDomains))
    }

    private func makeBreakdownData(
        engine: AnalyticsEngine,
        appEvents: [AppActivityEvent],
        webVisits: [WebsiteVisitRecord]) -> AnalyticsBreakdownData
    {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
        let weekStart = calendar.date(
            byAdding: .day,
            value: -(AppConstants.AnalyticsSettings.weeklySummaryDays - 1),
            to: todayStart) ?? todayStart

        return AnalyticsBreakdownData(
            todayApps: engine.buildTopApps(
                from: appEvents,
                startDate: todayStart,
                endDate: tomorrow,
                limit: 5),
            todayDomains: engine.buildTopDomains(
                from: webVisits,
                startDate: todayStart,
                endDate: tomorrow,
                limit: 5),
            weekApps: engine.buildTopApps(
                from: appEvents,
                startDate: weekStart,
                endDate: tomorrow,
                limit: 5),
            weekDomains: engine.buildTopDomains(
                from: webVisits,
                startDate: weekStart,
                endDate: tomorrow,
                limit: 5))
    }
}

private enum DashboardState {
    case loading
    case empty(DashboardEmptyState)
    case loaded(AnalyticsDashboardData)
}

private enum DashboardEmptyState {
    case permissionsRequired
    case noData
}

private struct AnalyticsDashboardData {
    let summary: AnalyticsSummary
    let heatmapCells: [AnalyticsHeatmapCell]
    let timelineEntries: [AnalyticsTimelineEntry]
    let breakdown: AnalyticsBreakdownData

    var hasVisibleData: Bool {
        self.summary.hasData
            || self.heatmapCells.contains(where: { $0.focusSeconds > 0 })
            || !self.timelineEntries.isEmpty
            || !self.breakdown.isEmpty
    }
}

private struct AnalyticsBreakdownData {
    let todayApps: [AnalyticsBreakdownItem]
    let todayDomains: [AnalyticsBreakdownItem]
    let weekApps: [AnalyticsBreakdownItem]
    let weekDomains: [AnalyticsBreakdownItem]

    var isEmpty: Bool {
        self.todayApps.isEmpty
            && self.todayDomains.isEmpty
            && self.weekApps.isEmpty
            && self.weekDomains.isEmpty
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: self.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(self.color)
                Text(self.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            Text(self.value)
                .font(.title2)
                .fontWeight(.bold)
            if let subtitle = self.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
