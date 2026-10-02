import Foundation
import Testing
@testable import Qoma

struct InsightAggregatorTests {
    private let calendar = Calendar.current

    private func makeSession(
        taskTitle: String = "Test task",
        startedAt: Date,
        plannedMinutes: Int = 25,
        actualSeconds: TimeInterval,
        status: SessionStatus
    ) -> FocusSession {
        FocusSession(
            id: UUID(),
            accountID: "local",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(actualSeconds),
            plannedMinutes: plannedMinutes,
            actualActiveSeconds: actualSeconds,
            status: status,
            draftSnapshot: SessionDraft(taskTitle: taskTitle, plannedMinutes: plannedMinutes, policy: .timerOnly),
            taskTitle: taskTitle
        )
    }

    @Test
    func daySummariesAggregateByCalendarDay() {
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let sessions = [
            makeSession(startedAt: today.addingTimeInterval(3600), actualSeconds: 1200, status: .completed),
            makeSession(startedAt: today.addingTimeInterval(7200), actualSeconds: 600, status: .interrupted),
            makeSession(startedAt: yesterday.addingTimeInterval(3600), actualSeconds: 900, status: .completed),
        ]
        let aggregator = InsightAggregator(history: sessions, catches: [])
        let days = aggregator.daySummaries(calendar: calendar)

        #expect(days.count == 2)
        let todaySummary = days.first { calendar.isDate($0.date, inSameDayAs: today) }
        #expect(todaySummary?.focusSeconds == 1800)
        #expect(todaySummary?.completedSessions == 1)
        #expect(todaySummary?.interruptedSessions == 1)
    }

    @Test
    func periodSummaryAggregatesCurrentWeek() {
        let today = calendar.startOfDay(for: Date())
        let sessions = [
            makeSession(taskTitle: "Task A", startedAt: today.addingTimeInterval(3600), actualSeconds: 1200, status: .completed),
            makeSession(taskTitle: "Task B", startedAt: today.addingTimeInterval(7200), actualSeconds: 600, status: .completed),
        ]
        let aggregator = InsightAggregator(history: sessions, catches: [])
        let summary = aggregator.summary(for: .weekOfYear, value: 0, calendar: calendar)

        #expect(summary != nil)
        #expect(summary?.focusSeconds == 1800)
        #expect(summary?.completedSessions == 2)
        #expect(summary?.topTasks.count == 2)
        #expect(summary?.topTasks.first?.title == "Task A")
    }

    @Test
    func periodSummaryOutsideRangeReturnsZero() {
        let today = calendar.startOfDay(for: Date())
        let lastYear = calendar.date(byAdding: .year, value: -1, to: today)!
        let sessions = [
            makeSession(startedAt: lastYear, actualSeconds: 1200, status: .completed)
        ]
        let aggregator = InsightAggregator(history: sessions, catches: [])
        let summary = aggregator.summary(for: .weekOfYear, value: 0, calendar: calendar)

        #expect(summary?.focusSeconds == 0)
        #expect(summary?.completedSessions == 0)
    }
}
