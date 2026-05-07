import Foundation

final class AnalyticsEngine {
    static let shared = AnalyticsEngine()

    private init() {}

    // MARK: - Summary

    func buildSummary(from sessions: [FocusSessionRecord], appEvents: [AppActivityEvent], webVisits: [WebsiteVisitRecord]) -> AnalyticsSummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -(AppConstants.AnalyticsSettings.weeklySummaryDays - 1), to: today)!

        let todaySessions = sessions.filter { calendar.startOfDay(for: $0.startedAt) == today }
        let weekSessions = sessions.filter { $0.startedAt >= weekStart }

        let todayFocus = todaySessions.reduce(0) { $0 + $1.actualFocusSeconds }
        let weekFocus = weekSessions.reduce(0) { $0 + $1.actualFocusSeconds }

        let streak = calculateStreak(from: sessions)
        let (bestDay, bestDaySeconds) = calculateBestDay(from: sessions)

        let totalAppSeconds = appEvents.reduce(0) { $0 + $1.durationSeconds }
        let appGroups = Dictionary(grouping: appEvents, by: { $0.appName })
        let topApps = appGroups
            .map { name, events in
                AnalyticsBreakdownItem(name: name, seconds: events.reduce(0) { $0 + $1.durationSeconds }, icon: nil)
            }
            .sorted { $0.seconds > $1.seconds }
            .prefix(10)
            .map { item in
                var copy = item
                copy.percentage = totalAppSeconds > 0 ? (item.seconds / totalAppSeconds) * 100 : 0
                return copy
            }

        let totalWebSeconds = webVisits.reduce(0) { $0 + $1.durationSeconds }
        let domainGroups = Dictionary(grouping: webVisits, by: { $0.domain })
        let topDomains = domainGroups
            .map { domain, visits in
                AnalyticsBreakdownItem(name: domain, seconds: visits.reduce(0) { $0 + $1.durationSeconds }, icon: nil)
            }
            .sorted { $0.seconds > $1.seconds }
            .prefix(10)
            .map { item in
                var copy = item
                copy.percentage = totalWebSeconds > 0 ? (item.seconds / totalWebSeconds) * 100 : 0
                return copy
            }

        return AnalyticsSummary(
            todayFocusSeconds: todayFocus,
            weekFocusSeconds: weekFocus,
            streakDays: streak,
            bestDay: bestDay,
            bestDaySeconds: bestDaySeconds,
            topApps: Array(topApps),
            topDomains: Array(topDomains)
        )
    }

    // MARK: - Heatmap

    func buildHeatmapCells(from sessions: [FocusSessionRecord], days: Int = AppConstants.AnalyticsSettings.heatmapDays) -> [AnalyticsHeatmapCell] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today)!

        var dayTotals: [Date: Double] = [:]
        for session in sessions where session.startedAt >= startDate {
            let day = calendar.startOfDay(for: session.startedAt)
            dayTotals[day, default: 0] += session.actualFocusSeconds
        }

        var cells: [AnalyticsHeatmapCell] = []
        var currentDate = startDate
        while currentDate <= today {
            let seconds = dayTotals[currentDate] ?? 0
            let level = intensityLevel(for: seconds)
            cells.append(AnalyticsHeatmapCell(date: currentDate, focusSeconds: seconds, intensityLevel: level))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return cells
    }

    // MARK: - Daily Snapshots

    func buildDailySnapshots(from sessions: [FocusSessionRecord], appEvents: [AppActivityEvent], webVisits: [WebsiteVisitRecord], days: Int = AppConstants.AnalyticsSettings.defaultDashboardRangeDays) -> [DailyAnalyticsSnapshot] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today)!

        var daySessions: [Date: [FocusSessionRecord]] = [:]
        for session in sessions where session.startedAt >= startDate {
            let day = calendar.startOfDay(for: session.startedAt)
            daySessions[day, default: []].append(session)
        }

        var dayAppEvents: [Date: [AppActivityEvent]] = [:]
        for event in appEvents where event.startedAt >= startDate {
            let day = calendar.startOfDay(for: event.startedAt)
            dayAppEvents[day, default: []].append(event)
        }

        var dayWebVisits: [Date: [WebsiteVisitRecord]] = [:]
        for visit in webVisits where visit.startedAt >= startDate {
            let day = calendar.startOfDay(for: visit.startedAt)
            dayWebVisits[day, default: []].append(visit)
        }

        var snapshots: [DailyAnalyticsSnapshot] = []
        var currentDate = startDate
        while currentDate <= today {
            let sessions = daySessions[currentDate] ?? []
            let focusSeconds = sessions.reduce(0) { $0 + $1.actualFocusSeconds }

            let apps = (dayAppEvents[currentDate] ?? [])
            let appGroups = Dictionary(grouping: apps, by: { $0.appName })
            let topApps = appGroups
                .map { name, events in
                    DailyAnalyticsSnapshot.TopItem(name: name, seconds: events.reduce(0) { $0 + $1.durationSeconds })
                }
                .sorted { $0.seconds > $1.seconds }
                .prefix(5)

            let visits = (dayWebVisits[currentDate] ?? [])
            let domainGroups = Dictionary(grouping: visits, by: { $0.domain })
            let topDomains = domainGroups
                .map { domain, v in
                    DailyAnalyticsSnapshot.TopItem(name: domain, seconds: v.reduce(0) { $0 + $1.durationSeconds })
                }
                .sorted { $0.seconds > $1.seconds }
                .prefix(5)

            snapshots.append(DailyAnalyticsSnapshot(
                date: currentDate,
                focusSeconds: focusSeconds,
                sessionCount: sessions.count,
                topApps: Array(topApps),
                topDomains: Array(topDomains),
                heatmapScore: intensityLevel(for: focusSeconds)
            ))

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return snapshots
    }

    // MARK: - Timeline

    func buildTimeline(for date: Date, appEvents: [AppActivityEvent], webVisits: [WebsiteVisitRecord]) -> [AnalyticsTimelineEntry] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let dayApps = appEvents
            .filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
            .sorted { $0.startedAt < $1.startedAt }

        let dayWeb = webVisits
            .filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
            .sorted { $0.startedAt < $1.startedAt }

        var entries: [AnalyticsTimelineEntry] = []

        for event in dayApps {
            let ended = event.endedAt ?? event.startedAt
            entries.append(AnalyticsTimelineEntry(
                startedAt: event.startedAt,
                endedAt: ended,
                kind: .app,
                name: event.appName,
                detail: event.windowTitle,
                seconds: event.durationSeconds
            ))
        }

        for visit in dayWeb {
            let ended = visit.endedAt ?? visit.startedAt
            entries.append(AnalyticsTimelineEntry(
                startedAt: visit.startedAt,
                endedAt: ended,
                kind: .website,
                name: visit.domain,
                detail: visit.pageTitle,
                seconds: visit.durationSeconds
            ))
        }

        return entries.sorted { $0.startedAt < $1.startedAt }
    }

    // MARK: - Helpers

    private func calculateStreak(from sessions: [FocusSessionRecord]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var uniqueDays = Set(sessions.filter { $0.actualFocusSeconds > 0 }.map { calendar.startOfDay(for: $0.startedAt) })

        var streak = 0
        var currentDay = today

        while uniqueDays.contains(currentDay) {
            streak += 1
            currentDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
        }

        if streak == 0 && uniqueDays.contains(calendar.date(byAdding: .day, value: -1, to: today)!) {
            currentDay = calendar.date(byAdding: .day, value: -1, to: today)!
            while uniqueDays.contains(currentDay) {
                streak += 1
                currentDay = calendar.date(byAdding: .day, value: -1, to: currentDay)!
            }
        }

        return streak
    }

    private func calculateBestDay(from sessions: [FocusSessionRecord]) -> (Date?, Double) {
        let calendar = Calendar.current
        var dayTotals: [Date: Double] = [:]
        for session in sessions where session.actualFocusSeconds > 0 {
            let day = calendar.startOfDay(for: session.startedAt)
            dayTotals[day, default: 0] += session.actualFocusSeconds
        }
        guard let bestEntry = dayTotals.max(by: { $0.value < $1.value }) else {
            return (nil, 0)
        }
        return (bestEntry.key, bestEntry.value)
    }

    private func intensityLevel(for seconds: Double) -> Int {
        let minutes = seconds / 60.0
        if minutes == 0 { return 0 }
        if minutes < 15 { return 1 }
        if minutes < 30 { return 2 }
        if minutes < 60 { return 3 }
        if minutes < 120 { return 4 }
        return 5
    }
}
