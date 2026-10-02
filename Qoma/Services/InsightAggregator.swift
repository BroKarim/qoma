import Foundation

/// Aggregates focus sessions and catches into Day/Week/Month/Year views.
/// Does not use tags or daily focus goals.
struct InsightAggregator {
    let history: [FocusSession]
    let catches: [CatchEvent]

    struct DaySummary: Equatable {
        let date: Date
        let focusSeconds: TimeInterval
        let completedSessions: Int
        let interruptedSessions: Int
        let catchCount: Int
    }

    struct PeriodSummary: Equatable {
        let period: String
        let focusSeconds: TimeInterval
        let completedSessions: Int
        let interruptedSessions: Int
        let catchCount: Int
        let topTasks: [TopTask]
    }

    struct TopTask: Equatable {
        let title: String
        let seconds: TimeInterval
    }

    func daySummaries(calendar: Calendar = .current) -> [DaySummary] {
        let grouped = Dictionary(grouping: history) { session -> Date in
            calendar.startOfDay(for: session.startedAt)
        }

        return grouped.keys.sorted().map { date in
            let sessions = grouped[date] ?? []
            let focusSeconds = sessions.reduce(0) { $0 + $1.actualActiveSeconds }
            let completed = sessions.filter { $0.status == .completed }.count
            let interrupted = sessions.filter { $0.status == .interrupted }.count
            let catchCount = catches.count { calendar.isDate($0.depositedAt, inSameDayAs: date) }
            return DaySummary(
                date: date,
                focusSeconds: focusSeconds,
                completedSessions: completed,
                interruptedSessions: interrupted,
                catchCount: catchCount
            )
        }
    }

    func summary(for component: Calendar.Component, value: Int, calendar: Calendar = .current) -> PeriodSummary? {
        let now = Date()
        let currentPeriodStart: Date?
        switch component {
        case .day:
            currentPeriodStart = calendar.startOfDay(for: now)
        case .weekOfYear:
            currentPeriodStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start
        case .month:
            currentPeriodStart = calendar.dateInterval(of: .month, for: now)?.start
        case .year:
            currentPeriodStart = calendar.dateInterval(of: .year, for: now)?.start
        default:
            return nil
        }

        guard let start = currentPeriodStart,
              let periodStart = calendar.date(byAdding: component, value: value, to: start) else { return nil }

        var periodEnd: Date?
        switch component {
        case .day:
            periodEnd = calendar.date(byAdding: .day, value: 1, to: periodStart)
        case .weekOfYear:
            periodEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: periodStart)
        case .month:
            periodEnd = calendar.date(byAdding: .month, value: 1, to: periodStart)
        case .year:
            periodEnd = calendar.date(byAdding: .year, value: 1, to: periodStart)
        default:
            return nil
        }

        guard let end = periodEnd else { return nil }
        let sessions = history.filter { $0.startedAt >= periodStart && $0.startedAt < end }
        let periodCatches = catches.filter { $0.depositedAt >= periodStart && $0.depositedAt < end }
        return makePeriodSummary(period: periodLabel(for: component, value: value, start: periodStart, calendar: calendar), sessions: sessions, catches: periodCatches)
    }

    private func makePeriodSummary(period: String, sessions: [FocusSession], catches: [CatchEvent]) -> PeriodSummary {
        let focusSeconds = sessions.reduce(0) { $0 + $1.actualActiveSeconds }
        let completed = sessions.filter { $0.status == .completed }.count
        let interrupted = sessions.filter { $0.status == .interrupted }.count
        let taskTotals = Dictionary(grouping: sessions, by: { $0.taskTitle.isEmpty ? "Focus session" : $0.taskTitle })
            .map { TopTask(title: $0.key, seconds: $0.value.reduce(0) { $0 + $1.actualActiveSeconds }) }
            .sorted { $0.seconds > $1.seconds }
            .prefix(5)
        return PeriodSummary(
            period: period,
            focusSeconds: focusSeconds,
            completedSessions: completed,
            interruptedSessions: interrupted,
            catchCount: catches.count,
            topTasks: Array(taskTotals)
        )
    }

    private func periodLabel(for component: Calendar.Component, value: Int, start: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        switch component {
        case .day:
            formatter.dateStyle = .medium
            return formatter.string(from: start)
        case .weekOfYear:
            formatter.dateFormat = "MMM d"
            guard let end = calendar.date(byAdding: .day, value: 6, to: start) else { return "Week" }
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: start)
        case .year:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: start)
        default:
            return "Period"
        }
    }
}
