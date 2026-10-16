import AppKit
import SwiftUI

struct AnalyticsDashboardView: View {
    @Binding var selectedDay: Date
    var catchRequest: UUID?
    @State private var sessions: [FocusSessionRecord] = []
    @State private var apps: [AppActivityEvent] = []
    @State private var websites: [WebsiteVisitRecord] = []
    @State private var catches: [CatchEvent] = []
    @State private var expandedHistory = false

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
                    self.overview
                    AnalyticsHeatmapView(cells: self.heatmapCells, selectedDate: self.$selectedDay)
                    self.breakdown
                    // bagian daily-catch
                    self.dailyCatches.id("daily-catches")
                }
                .padding(28)
                .padding(.top, 12)
            }
            .qyubeScrollIndicator()
            .onAppear {
                self.loadData()
                if self.catchRequest != nil { proxy.scrollTo("daily-catches", anchor: .top) }
            }
            .onChange(of: self.catchRequest) { _, _ in
                self.loadData()
                proxy.scrollTo("daily-catches", anchor: .top)
            }
        }
        .onChange(of: self.selectedDay) { _, _ in self.expandedHistory = false }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            self.loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .qyubeCollectionChanged)) { _ in self.loadData() }
    }

    private var overview: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 0) { self.stats }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) { self.stats }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var stats: some View {
        self.stat("Total focus", value: QyubeFormat.duration(self.daySessions.reduce(0) { $0 + $1.actualFocusSeconds }), symbol: "leaf", color: .qyubeAccent)
        Divider()
        self.stat("Sessions", value: "\(self.daySessions.count)", symbol: "chart.bar", color: .qyubeAccent)
        Divider()
        self.stat("Completed", value: "\(self.daySessions.filter(\.completed).count)", symbol: "checkmark.circle", color: .qyubeAccent)
        Divider()
        self.stat("Interrupted", value: "\(self.daySessions.count(where: { !$0.completed }))", symbol: "xmark.circle", color: Color(red: 0.67, green: 0.40, blue: 0.36))
    }

    private func stat(_ title: String, value: String, symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol).font(.system(size: 12)).foregroundStyle(color)
            Text(value).font(.system(size: 34, design: .serif)).minimumScaleFactor(0.7).lineLimit(1)
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
        return SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    SettingsSectionHeading(title: "Daily Catches", subtitle: "Little finds from this day’s focus.")
                    Spacer()
                    Text("\(events.count)").font(.system(size: 32, design: .serif))
                        .accessibilityLabel("\(events.count) catches on the selected day")
                }
                Divider()
                if events.isEmpty {
                    Label(
                        "No catches on this day. A quiet spot, ready for your next focus.",
                        systemImage: "water.waves")
                        .foregroundStyle(.secondary).padding(.vertical, 20)
                } else {
                    ForEach(DailyCatchSummary.groups(for: events)) { group in
                        self.catchRow(group)
                        Divider()
                    }
                    DisclosureGroup("Catch history · \(events.count) finds", isExpanded: self.$expandedHistory) {
                        LazyVStack(spacing: 0) {
                            ForEach(events) { event in
                                HStack(spacing: 16) {
                                    Text(event.depositedAt, format: .dateTime.hour().minute())
                                        .monospacedDigit().foregroundStyle(.secondary).frame(
                                            width: 70,
                                            alignment: .leading)
                                    Circle().fill(Color.qyubeAccent).frame(width: 6, height: 6)
                                    Text(CatalogDefinitions.kind(id: event.kindID)?.name ?? "Unknown find")
                                    Spacer()
                                    Image(systemName: "checkmark").foregroundStyle(Color.qyubeAccent)
                                }
                                .font(.system(size: 12)).padding(.vertical, 10)
                            }
                        }.padding(.top, 12)
                    }
                    .font(.system(size: 13))
                }
            }
        }
    }

    private func catchRow(_ group: DailyCatchSummary) -> some View {
        let kind = CatalogDefinitions.kind(id: group.kindID)
        return HStack(spacing: 18) {
            QyubeCatchArt(kindID: group.kindID).frame(width: 96, height: 66)
            VStack(alignment: .leading, spacing: 5) {
                Text(kind?.name ?? "Unknown find").font(.system(size: 19, design: .serif))
                    .foregroundStyle(kind?.rarity.color ?? .qyubeInk)
                Text(kind?.rarity.rawValue.capitalized ?? "Uncatalogued").font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let first = group.events.first, let last = group.events.last {
                VStack(alignment: .trailing, spacing: 5) {
                    Text("×\(group.events.count)").font(.system(size: 22, design: .serif))
                    Text(
                        first.depositedAt.formatted(.dateTime.hour().minute()) + " – "
                            + last.depositedAt.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
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
