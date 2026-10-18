import Foundation
import Testing
@testable import Qoma

struct QomaDatabaseTests {
    @Test func migratesLegacyCatchFilesIdempotentlyAndKeepsSources() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let accountID = "local"
        let sessionID = UUID()
        let first = CatchEvent(sessionID: sessionID, accountID: accountID, kindID: "perch", depositedAt: .now,
                               bankedAt: .now)
        let second = CatchEvent(sessionID: sessionID, accountID: accountID, kindID: "shell", depositedAt: .now)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bankedURL = directory.appendingPathComponent("banked-local.json")
        let eventURL = directory.appendingPathComponent("banked-event-local-\(first.id.uuidString).json")
        let provisionalURL = directory.appendingPathComponent("provisional-local-\(sessionID.uuidString).json")
        try encoder.encode([first]).write(to: bankedURL)
        try encoder.encode(first).write(to: eventURL)
        try encoder.encode([second]).write(to: provisionalURL)

        let repository = CatchRepository(storageDirectory: directory)
        #expect(repository.listBanked(accountID: accountID).count == 1)
        #expect(repository.listProvisional(sessionID: sessionID, accountID: accountID).map(\.id) == [second.id])
        #expect(CatchRepository(storageDirectory: directory).listBanked(accountID: accountID).count == 1)
        #expect(FileManager.default.fileExists(atPath: bankedURL.path))
        #expect(FileManager.default.fileExists(atPath: eventURL.path))
    }

    @Test func failedCatchMigrationCanRetryWithoutWritingItsMarker() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let source = directory.appendingPathComponent("banked-local.json")
        try Data("incomplete".utf8).write(to: source)
        let repository = CatchRepository(storageDirectory: directory)
        #expect(repository.listBanked(accountID: "local").isEmpty)

        let event = CatchEvent(sessionID: UUID(), accountID: "local", kindID: "perch",
                               depositedAt: .now, bankedAt: .now)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode([event]).write(to: source)
        #expect(CatchRepository(storageDirectory: directory).listBanked(accountID: "local").map(\.id) == [event.id])
    }

    @Test func migratesLegacyActiveSessionAndLeavesJSONBackup() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let snapshot = ActiveSessionSnapshot(
            accountID: "local", startedAt: .now, deadline: .now.addingTimeInterval(600),
            draft: SessionDraft(plannedMinutes: 10)
        )
        let source = directory.appendingPathComponent("active-local.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try encoder.encode(snapshot).write(to: source)
        let repository = SessionRepository(storageDirectory: directory)
        #expect(repository.loadActive(accountID: "local")?.id == snapshot.id)
        #expect(SessionRepository(storageDirectory: directory).loadActive(accountID: "local")?.id == snapshot.id)
        #expect(FileManager.default.fileExists(atPath: source.path))
    }

    @Test func migratesLegacyAnalyticsJSONWithoutRemovingSources() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let session = FocusSessionRecord(plannedMinutes: 10, actualFocusSeconds: 600, sessionMode: .quickSession)
        let activity = AppActivityEvent(sessionID: session.id, appBundleID: "com.apple.Terminal", appName: "Terminal")
        let visit = WebsiteVisitRecord(sessionID: session.id, browserBundleID: "com.apple.Safari",
                                       browserName: "Safari", domain: "example.com")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let sessionURL = directory.appendingPathComponent(AppConstants.AnalyticsSettings.focusSessionsFile)
        let activityURL = directory.appendingPathComponent(AppConstants.AnalyticsSettings.appActivityFile)
        let visitURL = directory.appendingPathComponent(AppConstants.AnalyticsSettings.websiteVisitsFile)
        try encoder.encode([session]).write(to: sessionURL)
        try encoder.encode([activity]).write(to: activityURL)
        try encoder.encode([visit]).write(to: visitURL)

        let store = AnalyticsStore(storageDirectory: directory)
        #expect(store.loadFocusSessions().map(\.id) == [session.id])
        #expect(store.loadAppActivityEvents().map(\.id) == [activity.id])
        #expect(store.loadWebsiteVisits().map(\.id) == [visit.id])
        #expect(FileManager.default.fileExists(atPath: sessionURL.path))
    }

    @Test func queriesLargeCatchLedgerByAccountAndKind() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = CatchRepository(storageDirectory: directory)
        let now = Date.now
        for index in 0..<5_000 {
            let event = CatchEvent(
                sessionID: UUID(), accountID: index.isMultiple(of: 2) ? "a" : "b",
                kindID: index.isMultiple(of: 3) ? "perch" : "shell", depositedAt: now, bankedAt: now
            )
            #expect(repository.saveProvisional(event))
        }
        #expect(repository.listBanked(accountID: "a").count == 2_500)
        #expect(repository.countByKind(accountID: "a").values.reduce(0, +) == 2_500)
        #expect(repository.listBanked(accountID: "b").count == 2_500)
    }

    @Test func databaseFailureIsReportedAndDoesNotPretendWritesSucceeded() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try Data("not a directory".utf8).write(to: root)
        let database = try? QomaDatabase(url: root.appendingPathComponent("qoma.sqlite3"))
        #expect(database.map { _ in false } ?? true)
        let repository = CatchRepository(storageDirectory: root)
        let event = CatchEvent(sessionID: UUID(), accountID: "local", kindID: "perch", depositedAt: .now)
        #expect(repository.saveProvisional(event) == false)
    }

    @Test func failedTransactionRollsBackEveryRecord() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try QomaDatabase(url: directory.appendingPathComponent("qoma.sqlite3"))
        try database.execute("CREATE TABLE transaction_probe(value INTEGER NOT NULL)")
        do {
            try database.transaction {
                try database.execute("INSERT INTO transaction_probe(value) VALUES(?)", [.integer(1)])
                throw QomaDatabase.error("simulated interruption before commit")
            }
        } catch {}
        #expect(try database.query("SELECT value FROM transaction_probe").isEmpty)
    }

    @Test func committedStateSurvivesDatabaseReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("qoma.sqlite3")
        let accountID = "local"
        let snapshot = ActiveSessionSnapshot(
            accountID: accountID, startedAt: .now, deadline: .now.addingTimeInterval(600),
            draft: SessionDraft(plannedMinutes: 10)
        )
        let session = FocusSession(
            id: UUID(), accountID: accountID, startedAt: snapshot.startedAt, endedAt: .now,
            plannedMinutes: 10, actualActiveSeconds: 42, status: .interrupted,
            draftSnapshot: snapshot.draft, taskTitle: snapshot.draft.displayTitle
        )
        let event = CatchEvent(sessionID: snapshot.id, accountID: accountID, kindID: "perch",
                               depositedAt: .now, bankedAt: .now)
        do {
            let database = try QomaDatabase(url: url)
            #expect(SessionRepository(database: database).saveActive(snapshot))
            #expect(SessionRepository(database: database).finalizeOnce(session))
            #expect(CatchRepository(database: database).saveProvisional(event))
        }
        let reopened = try QomaDatabase(url: url)
        #expect(SessionRepository(database: reopened).loadActive(accountID: accountID)?.id == snapshot.id)
        #expect(SessionRepository(database: reopened).loadHistory(accountID: accountID).map(\.id) == [session.id])
        #expect(CatchRepository(database: reopened).listBanked(accountID: accountID).map(\.id) == [event.id])
    }
}
