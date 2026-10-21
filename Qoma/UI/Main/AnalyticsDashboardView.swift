import AppKit
import SwiftUI

struct AnalyticsDashboardView: View {
    @Binding var selectedDay: Date
    var catchRequest: UUID?
    @State private var sessions: [FocusSessionRecord] = []
    @State private var apps: [AppActivityEvent] = []
    @State private var websites: [WebsiteVisitRecord] = []
    @State private var catches: [CatchEvent] = []

    private var daySessions: [FocusSessionRecord] {
        self.sessions.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: self.selectedDay) }
    }

    private var dayCatches: [CatchEvent] {
        DailyCatchSummary.events(on: self.selectedDay, from: self.catches)
    }

    private var heatmapCells: [AnalyticsHeatmapCell] {
        AnalyticsEngine.shared.buildHeatmapCells(from: self.sessions)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top) {
                        JournalPageHeader(
                            eyebrow: "YOUR FOCUS JOURNAL",
                            title: "Analytics",
                            subtitle: self.selectedDay.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        Spacer(minLength: 12)
                        Image("JournalArcticPenguin").resizable().scaledToFit()
                            .frame(width: 220, height: 147).accessibilityHidden(true)
                    }
                    VStack(spacing: 0) {
                        self.overview
                            .padding(20)
                            .background(Color.qyubeSelection.opacity(0.42))
                        Rectangle().fill(Color.qyubeLine).frame(height: 0.7)
                        AnalyticsHeatmapView(cells: self.heatmapCells, selectedDate: self.$selectedDay)
                            .padding(20)
                    }
                    .background(Color.qyubeCardBackground.opacity(0.58))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.qyubeLine, lineWidth: 0.7))
                    self.breakdown
                    // bagian daily-catch
                    self.dailyCatches.id("daily-catches")
                }
                .padding(28)
                .padding(.top, 12)
                .qyubeHideNativeScrollers()
            }
            .scrollIndicators(.hidden)
            .onAppear {
                self.loadData()
                if self.catchRequest != nil { proxy.scrollTo("daily-catches", anchor: .top) }
            }
            .onChange(of: self.catchRequest) { _, _ in
                self.loadData()
                proxy.scrollTo("daily-catches", anchor: .top)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            self.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .qyubeCollectionChanged)) { _ in self.loadData() }
    }

    private var overview: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 0) { self.stats(showDividers: true) }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                self.stats(showDividers: false)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private func stats(showDividers: Bool) -> some View {
        self.stat(
            "Total focus",
            value: QyubeFormat.duration(self.daySessions.reduce(0) { $0 + $1.actualFocusSeconds }),
            symbol: "clock",
            color: .qyubeAccent)
        if showDividers { Rectangle().fill(Color.qyubeLine).frame(width: 0.7, height: 58) }
        self.stat("Sessions", value: "\(self.daySessions.count)", symbol: "chart.bar.fill", color: .qyubeAccent)
        if showDividers { Rectangle().fill(Color.qyubeLine).frame(width: 0.7, height: 58) }
        self.stat(
            "Completed",
            value: "\(self.daySessions.filter(\.completed).count)",
            symbol: "checkmark",
            color: .qyubeAccent)
        if showDividers { Rectangle().fill(Color.qyubeLine).frame(width: 0.7, height: 58) }
        self.stat(
            "Interrupted",
            value: "\(self.daySessions.count(where: { !$0.completed }))",
            symbol: "xmark",
            color: .qyubeInterrupted)
    }

    private func stat(_ title: String, value: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, design: .serif)).fixedSize()
                Text(value).font(.system(size: 34, design: .serif)).minimumScaleFactor(0.7).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
    }

    private var breakdown: some View {
        let interval = Calendar.current.dateInterval(of: .day, for: self.selectedDay)
        return AnalyticsBreakdownView(
            date: self.selectedDay,
            apps: AnalyticsEngine.shared.buildTopApps(
                from: self.apps,
                startDate: interval?.start,
                endDate: interval?.end,
                limit: 5),
            domains: AnalyticsEngine.shared.buildTopDomains(
                from: self.websites, startDate: interval?.start, endDate: interval?.end, limit: 5))
    }

    private var dailyCatches: some View {
        let events = self.dayCatches
        let groups = DailyCatchSummary.groups(for: events)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
        return SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    SettingsSectionHeading(title: "Daily Catches", subtitle: "Little finds from this day’s focus.")
                    Spacer()
                    Text("\(events.count) catches · \(groups.count) types")
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(
                            "\(events.count) catches across \(groups.count) types on the selected day")
                }
                QyubeInkDivider()
                if events.isEmpty {
                    Label(
                        "No catches on this day. A quiet spot, ready for your next focus.",
                        systemImage: "water.waves")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 160)
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 20) {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(groups) { group in
                                        FishCatchCardView(summary: group)
                                    }
                                }
                                .qyubeHideNativeScrollers()
                            }
                            .scrollIndicators(.hidden)
                            .frame(minWidth: 540, maxWidth: .infinity, minHeight: 340, maxHeight: 340)

                            CatchTimelineView(events: events)
                                .frame(minWidth: 250, idealWidth: 290, maxWidth: 340)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(groups) { group in
                                        FishCatchCardView(summary: group)
                                    }
                                }
                                .qyubeHideNativeScrollers()
                            }
                            .scrollIndicators(.hidden)
                            .frame(height: 340)

                            CatchTimelineView(events: events)
                        }
                    }
                }
            }
        }
    }

    private func loadData() {
        var byID = Dictionary(
            AnalyticsStore.shared.loadFocusSessions().map { ($0.id, $0) },
            uniquingKeysWith: { _, newer in newer })
        for session in SessionRepository.shared.loadHistory(accountID: "local") {
            byID[session.id] = FocusSessionRecord(
                id: session.id,
                startedAt: session.startedAt,
                endedAt: session.endedAt,
                plannedMinutes: session.plannedMinutes,
                actualFocusSeconds: session.actualActiveSeconds,
                sessionMode: .quickSession,
                taskTitle: session.taskTitle,
                completed: session.status == .completed,
                interruptedReason: session.interruptedReason)
        }
        self.sessions = Array(byID.values)
        self.apps = AnalyticsStore.shared.loadAppActivityEvents()
        self.websites = AnalyticsStore.shared.loadWebsiteVisits()
        self.catches = CatchRepository.shared.listBanked(accountID: "local")
    }
}

extension Notification.Name {
    static let qyubeCollectionChanged = Notification.Name("qyube.collectionChanged")
}
