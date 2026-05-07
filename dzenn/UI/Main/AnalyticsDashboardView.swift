import SwiftUI

struct AnalyticsDashboardView: View {
    @State private var summary: AnalyticsSummary?
    @State private var heatmapCells: [AnalyticsHeatmapCell] = []
    @State private var timelineEntries: [AnalyticsTimelineEntry] = []
    @State private var usePreviewData = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsPageHeader(title: "Analytics", subtitle: "Track your focus patterns and activity.")

                if let summary = summary, summary.hasData {
                    summaryCardsView(summary: summary)
                    AnalyticsHeatmapView(cells: heatmapCells)
                    AnalyticsTimelineView(entries: timelineEntries)
                    AnalyticsBreakdownView(apps: summary.topApps, domains: summary.topDomains)
                } else {
                    AnalyticsEmptyStateView()
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            loadData()
        }
    }

    @ViewBuilder
    private func summaryCardsView(summary: AnalyticsSummary) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            SummaryCard(
                title: "Today",
                value: formatDuration(summary.todayFocusSeconds),
                icon: "sun.max.fill",
                color: .yellow
            )
            SummaryCard(
                title: "This Week",
                value: formatDuration(summary.weekFocusSeconds),
                icon: "calendar",
                color: .blue
            )
            SummaryCard(
                title: "Streak",
                value: "\(summary.streakDays) days",
                icon: "flame.fill",
                color: .orange
            )
        }

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            if let topApp = summary.topApps.first {
                SummaryCard(
                    title: "Top App",
                    value: topApp.name,
                    icon: "macwindow.fill",
                    color: .purple,
                    subtitle: topApp.displayDuration
                )
            }
            if let topDomain = summary.topDomains.first {
                SummaryCard(
                    title: "Top Website",
                    value: topDomain.name,
                    icon: "network",
                    color: .green,
                    subtitle: topDomain.displayDuration
                )
            }
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds / 60)
        if mins >= 60 {
            let hours = mins / 60
            let remaining = mins % 60
            return "\(hours)h \(remaining)m"
        }
        return "\(mins)m"
    }

    private func loadData() {
        if usePreviewData {
            summary = AnalyticsPreviewFactory.makePopulatedSummary()
            heatmapCells = AnalyticsPreviewFactory.makeHeatmapCells()
            timelineEntries = AnalyticsPreviewFactory.makeTimelineEntries()
        } else {
            let sessions = AnalyticsStore.shared.loadFocusSessions()
            let appEvents = AnalyticsStore.shared.loadAppActivityEvents()
            let webVisits = AnalyticsStore.shared.loadWebsiteVisits()
            summary = AnalyticsEngine.shared.buildSummary(from: sessions, appEvents: appEvents, webVisits: webVisits)
            heatmapCells = AnalyticsEngine.shared.buildHeatmapCells(from: sessions)
        }
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
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            if let subtitle = subtitle {
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
