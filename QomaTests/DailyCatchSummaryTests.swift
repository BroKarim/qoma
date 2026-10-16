import Foundation
import Testing
@testable import Qoma

struct DailyCatchSummaryTests {
    private func event(_ date: Date, id: UUID = UUID(), banked: Bool = true, kind: String = "anchovy") -> CatchEvent {
        CatchEvent(
            id: id,
            sessionID: UUID(),
            accountID: "local",
            kindID: kind,
            depositedAt: date,
            bankedAt: banked ? date.addingTimeInterval(600) : nil)
    }

    @Test func dailyLedgerUsesDepositDayAndExcludesDuplicatesAndProvisional() throws {
        let day = Calendar.current.startOfDay(for: Date())
        let tomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: day))
        let late = self.event(tomorrow.addingTimeInterval(-1), kind: "trout")
        let early = self.event(day)
        let events = DailyCatchSummary.events(on: day, from: [
            late, self.event(tomorrow), self.event(day.addingTimeInterval(-1)), early, early,
            self.event(day.addingTimeInterval(10), banked: false),
        ])
        #expect(events.map(\.id) == [early.id, late.id])
        let groups = DailyCatchSummary.groups(for: events)
        #expect(groups.reduce(0) { $0 + $1.events.count } == 2)
        #expect(groups.map(\.kindID) == ["anchovy", "trout"])
    }

    @Test func emptyDayStaysEmptyAndUnknownKindsSurvive() {
        let day = Calendar.current.startOfDay(for: Date())
        #expect(DailyCatchSummary.events(on: day, from: []).isEmpty)
        let groups = DailyCatchSummary.groups(for: [self.event(day, kind: "legacy-unknown")])
        #expect(groups.first?.kindID == "legacy-unknown")
    }

    @Test func dailyLedgerUsesCalendarDayAcrossDST() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 8)))
        let interval = try #require(calendar.dateInterval(of: .day, for: day))
        #expect(interval.duration == 23 * 3600)
        let result = DailyCatchSummary.events(
            on: day,
            from: [self.event(interval.end.addingTimeInterval(-1)), self.event(interval.end)],
            calendar: calendar)
        #expect(result.count == 1)
    }

    @Test func weightsAlwaysUseKilogramsWithoutInventingMissingValues() {
        #expect(CatchWeightFormat.kilograms(0.01) == "0.01 kg")
        #expect(CatchWeightFormat.kilograms(1.234) == "1.23 kg")
        #expect(CatchWeightFormat.kilograms(0.002) == "0.01 kg")
        #expect(CatchWeightFormat.kilograms(nil) == "— kg")
        #expect(CatchWeightFormat.kilograms(.nan) == "— kg")
    }

    @MainActor @Test func resultLinkChoosesLastBankedCatchDayOrSessionEnd() throws {
        let start = Calendar.current.startOfDay(for: Date())
        let end = try #require(Calendar.current.date(byAdding: .day, value: 1, to: start))
        let draft = SessionDraft(plannedMinutes: 25, policy: .timerOnly)
        let session = FocusSession(
            accountID: "local",
            startedAt: start,
            endedAt: end,
            plannedMinutes: 25,
            actualActiveSeconds: 1500,
            status: .completed,
            draftSnapshot: draft,
            taskTitle: "")
        let caught = CatchEvent(
            sessionID: session.id,
            accountID: "local",
            kindID: "anchovy",
            depositedAt: start.addingTimeInterval(600),
            bankedAt: end)
        #expect(QyubeNavigation.resultDay(for: session, catches: [caught]) == start)
        #expect(QyubeNavigation.resultDay(for: session, catches: []) == end)
        #expect(QyubeNavigation.Page.allCases == [.analytics, .catalog, .settings, .about])
    }
}
