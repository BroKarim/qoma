import XCTest
@testable import dzenn

final class AnalyticsEngineTests: XCTestCase {
    var engine: AnalyticsEngine!
    var testSessions: [FocusSessionRecord]!
    var testAppEvents: [AppActivityEvent]!
    var testWebVisits: [WebsiteVisitRecord]!

    override func setUp() {
        super.setUp()
        engine = AnalyticsEngine.shared
        testSessions = makeTestSessions()
        testAppEvents = makeTestAppEvents()
        testWebVisits = makeTestWebVisits()
    }

    func testBuildSummary() {
        let summary = engine.buildSummary(from: testSessions, appEvents: testAppEvents, webVisits: testWebVisits)

        XCTAssertGreaterThan(summary.todayFocusSeconds, 0)
        XCTAssertGreaterThan(summary.weekFocusSeconds, 0)
        XCTAssertGreaterThanOrEqualTo(summary.streakDays, 0)
        XCTAssertFalse(summary.topApps.isEmpty)
    }

    func testBuildHeatmapCells() {
        let cells = engine.buildHeatmapCells(from: testSessions)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        XCTAssertGreaterThan(cells.count, 0)
        XCTAssertEqual(cells.count % 7, 0, "Heatmap should have complete weeks")
        XCTAssertTrue(cells.allSatisfy { $0.intensityLevel >= 0 && $0.intensityLevel <= 5 })
        XCTAssertEqual(cells.first(where: { calendar.isDate($0.date, inSameDayAs: today) })?.sessionCount, 2)
        XCTAssertEqual(cells.first(where: { calendar.isDate($0.date, inSameDayAs: yesterday) })?.sessionCount, 1)
    }

    func testBuildTopApps() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let topApps = engine.buildTopApps(from: testAppEvents, startDate: today, endDate: tomorrow, limit: 5)

        XCTAssertFalse(topApps.isEmpty)
        XCTAssertTrue(topApps.count <= 5)
        for i in 0..<topApps.count - 1 {
            XCTAssertGreaterThanOrEqual(topApps[i].seconds, topApps[i + 1].seconds)
        }
    }

    func testBuildTopDomains() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let topDomains = engine.buildTopDomains(from: testWebVisits, startDate: today, endDate: tomorrow, limit: 5)

        XCTAssertFalse(topDomains.isEmpty)
        XCTAssertTrue(topDomains.count <= 5)
    }

    func testStreakCalculation() {
        let summary = engine.buildSummary(from: testSessions, appEvents: testAppEvents, webVisits: testWebVisits)
        XCTAssertGreaterThanOrEqual(summary.streakDays, 0)
    }

    private func makeTestSessions() -> [FocusSessionRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        return [
            FocusSessionRecord(
                startedAt: calendar.date(byAdding: .hour, value: 9, to: today)!,
                endedAt: calendar.date(byAdding: .hour, value: 10, to: today)!,
                plannedMinutes: 60,
                actualFocusSeconds: 3600,
                sessionMode: .quickSession,
                taskTitle: "Test session 1",
                completed: true),
            FocusSessionRecord(
                startedAt: calendar.date(byAdding: .hour, value: 14, to: today)!,
                endedAt: calendar.date(byAdding: .hour, value: 15, to: today)!,
                plannedMinutes: 60,
                actualFocusSeconds: 3000,
                sessionMode: .quickSession,
                taskTitle: "Test session 2",
                completed: false),
            FocusSessionRecord(
                startedAt: calendar.date(byAdding: .hour, value: 10, to: yesterday)!,
                endedAt: calendar.date(byAdding: .hour, value: 11, to: yesterday)!,
                plannedMinutes: 60,
                actualFocusSeconds: 3600,
                sessionMode: .quickSession,
                taskTitle: "Yesterday session",
                completed: true),
        ]
    }

    private func makeTestAppEvents() -> [AppActivityEvent] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessionID = UUID()

        return [
            AppActivityEvent(
                sessionID: sessionID,
                appBundleID: "com.apple.dt.Xcode",
                appName: "Xcode",
                startedAt: calendar.date(byAdding: .hour, value: 9, to: today)!,
                endedAt: calendar.date(byAdding: .minute, value: 40, to: calendar.date(byAdding: .hour, value: 9, to: today)!)!,
                durationSeconds: 2400),
            AppActivityEvent(
                sessionID: sessionID,
                appBundleID: "com.apple.Safari",
                appName: "Safari",
                startedAt: calendar.date(byAdding: .hour, value: 9, to: today)!.addingTimeInterval(2400),
                endedAt: calendar.date(byAdding: .hour, value: 10, to: today)!,
                durationSeconds: 1200),
        ]
    }

    private func makeTestWebVisits() -> [WebsiteVisitRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sessionID = UUID()

        return [
            WebsiteVisitRecord(
                sessionID: sessionID,
                browserBundleID: "com.apple.Safari",
                browserName: "Safari",
                domain: "github.com",
                startedAt: calendar.date(byAdding: .hour, value: 9, to: today)!,
                endedAt: calendar.date(byAdding: .minute, value: 30, to: calendar.date(byAdding: .hour, value: 9, to: today)!)!,
                durationSeconds: 1800),
            WebsiteVisitRecord(
                sessionID: sessionID,
                browserBundleID: "com.apple.Safari",
                browserName: "Safari",
                domain: "developer.apple.com",
                startedAt: calendar.date(byAdding: .hour, value: 9, to: today)!.addingTimeInterval(1800),
                endedAt: calendar.date(byAdding: .hour, value: 10, to: today)!,
                durationSeconds: 1800),
        ]
    }
}
