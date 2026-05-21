import XCTest
@testable import dzenn

final class AnalyticsStoreTests: XCTestCase {
    var store: AnalyticsStore!
    let testFileURL = AppConstants.AnalyticsSettings.analyticsDirectoryURL

    override func setUp() {
        super.setUp()
        store = AnalyticsStore.shared
        cleanupTestFiles()
    }

    override func tearDown() {
        cleanupTestFiles()
        UserDefaults.standard.removeObject(forKey: AppConstants.AnalyticsSettings.analyticsEnabledKey)
        super.tearDown()
    }

    func testAnalyticsEnabledDefaultsToTrue() {
        UserDefaults.standard.removeObject(forKey: AppConstants.AnalyticsSettings.analyticsEnabledKey)

        XCTAssertTrue(AppConstants.AnalyticsSettings.isAnalyticsEnabled)
    }

    func testFocusSessionRoundTrip() {
        let session = FocusSessionRecord(
            plannedMinutes: 25,
            actualFocusSeconds: 1500,
            sessionMode: .quickSession,
            taskTitle: "Test task",
            completed: true)

        store.appendFocusSession(session)

        let loaded = store.loadFocusSessions()
        XCTAssertTrue(loaded.contains(where: { $0.id == session.id }))
    }

    func testAppActivityEventRoundTrip() {
        let event = AppActivityEvent(
            sessionID: UUID(),
            appBundleID: "com.apple.dt.Xcode",
            appName: "Xcode",
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(1800),
            durationSeconds: 1800)

        store.appendAppActivityEvents([event])

        let loaded = store.loadAppActivityEvents()
        XCTAssertTrue(loaded.contains(where: { $0.id == event.id }))
    }

    func testWebsiteVisitRoundTrip() {
        let visit = WebsiteVisitRecord(
            sessionID: UUID(),
            browserBundleID: "com.apple.Safari",
            browserName: "Safari",
            domain: "github.com",
            startedAt: Date(),
            endedAt: Date().addingTimeInterval(900),
            durationSeconds: 900)

        store.appendWebsiteVisits([visit])

        let loaded = store.loadWebsiteVisits()
        XCTAssertTrue(loaded.contains(where: { $0.id == visit.id }))
    }

    func testPruneOldData() {
        let oldSession = FocusSessionRecord(
            startedAt: Date().addingTimeInterval(-86400 * 200),
            endedAt: Date().addingTimeInterval(-86400 * 199),
            plannedMinutes: 25,
            actualFocusSeconds: 1500,
            sessionMode: .quickSession,
            completed: true)

        store.appendFocusSession(oldSession)
        store.pruneOldData()

        let loaded = store.loadFocusSessions()
        XCTAssertFalse(loaded.contains(where: { $0.id == oldSession.id }))
    }

    func testMultipleSessionsAppend() {
        let sessions = (1...5).map { _ in
            FocusSessionRecord(plannedMinutes: 25, sessionMode: .quickSession)
        }

        sessions.forEach { store.appendFocusSession($0) }

        let loaded = store.loadFocusSessions()
        XCTAssertGreaterThanOrEqual(loaded.count, 5)
    }

    private func cleanupTestFiles() {
        let files = [
            AppConstants.AnalyticsSettings.focusSessionsFile,
            AppConstants.AnalyticsSettings.appActivityFile,
            AppConstants.AnalyticsSettings.websiteVisitsFile
        ]

        files.forEach {
            let url = testFileURL.appendingPathComponent($0)
            try? FileManager.default.removeItem(at: url)
        }
    }
}
