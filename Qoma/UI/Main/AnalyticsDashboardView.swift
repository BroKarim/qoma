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
        sessions.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: selectedDay) }
            .sorted { $0.startedAt == $1.startedAt ? $0.id.uuidString < $1.id.uuidString : $0.startedAt > $1.startedAt }
    }

    private var focusByDay: [Date: Double] {
        sessions.reduce(into: [:]) { totals, session in
            totals[Calendar.current.startOfDay(for: session.startedAt), default: 0] += session.actualFocusSeconds
        }
    }

    private var topApps: [AnalyticsBreakdownItem] {
        let interval = Calendar.current.dateInterval(of: .day, for: selectedDay)
        return AnalyticsEngine.shared.buildTopApps(
            from: apps, startDate: interval?.start, endDate: interval?.end, limit: 5)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("YOUR FOCUS JOURNAL")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(Color.qyubeAccent)
                        HStack(alignment: .firstTextBaseline) {
                            Text("Analytics")
                                .font(.system(size: 25, design: .serif))
                            Spacer()
                            Image(systemName: "book.closed")
                                .font(.system(size: 18, weight: .light))
                                .foregroundStyle(Color.qyubeAccent)
                                .accessibilityHidden(true)
                        }
                    }

                    AnalyticsMonthCalendar(selectedDay: $selectedDay, focusByDay: focusByDay)

                    VStack(alignment: .leading, spacing: 7) {
                        Text(selectedDay.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            .font(.system(size: 14, weight: .medium, design: .serif))
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(QyubeFormat.duration(daySessions.reduce(0) { $0 + $1.actualFocusSeconds }))
                                .font(.system(size: 26, weight: .medium, design: .rounded))
                                .monospacedDigit()
                            Text("of focus")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .qyubeInkSurface(fill: .qyubeSelection.opacity(0.6), stroke: .qyubeAccent.opacity(0.2))
                    .accessibilityElement(children: .combine)

                    AnalyticsSessionList(sessions: daySessions)
                    QyubeInkDivider().frame(height: 1)
                    AnalyticsJournalApps(apps: topApps)
                    QyubeInkDivider().frame(height: 1)
                    AnalyticsCatchGrid(events: DailyCatchSummary.events(on: selectedDay, from: catches))
                        .id("daily-catches")
                }
                .foregroundStyle(Color.qyubeMenuInk)
                .padding(13)
                .qyubeHideNativeScrollers()
            }
            .scrollIndicators(.hidden)
            .onAppear {
                loadData()
                if catchRequest != nil { proxy.scrollTo("daily-catches", anchor: .top) }
            }
            .onChange(of: catchRequest) { _, _ in
                loadData()
                proxy.scrollTo("daily-catches", anchor: .top)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .qyubeCollectionChanged)) { _ in loadData() }
    }

    private func loadData() {
        var byID = Dictionary(
            AnalyticsStore.shared.loadFocusSessions().map { ($0.id, $0) },
            uniquingKeysWith: { _, newer in newer })
        for session in SessionRepository.shared.loadHistory(accountID: AccessCoordinator.shared.accountID ?? "signed-out") {
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
        self.catches = CatchRepository.shared.listBanked(accountID: AccessCoordinator.shared.accountID ?? "signed-out")
    }
}

extension Notification.Name {
    static let qyubeCollectionChanged = Notification.Name("qyube.collectionChanged")
}
