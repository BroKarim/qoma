import Foundation
import OSLog

final class AnalyticsStore {
    static let shared = AnalyticsStore()

    private let database: QomaDatabase?
    private let storageDirectory: URL?
    private let shouldMigrateLegacyJSON: Bool
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let accountID = "local"

    init(storageDirectory: URL? = nil, database: QomaDatabase? = nil) {
        self.storageDirectory = storageDirectory
        shouldMigrateLegacyJSON = storageDirectory != nil || database == nil
        if let database {
            self.database = database
        } else if let storageDirectory {
            self.database = try? QomaDatabase(url: storageDirectory.appendingPathComponent("qoma.sqlite3"))
        } else {
            self.database = QomaDatabase.shared
        }
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadFocusSessions() -> [FocusSessionRecord] {
        migrateLegacyAnalyticsJSON()
        return query("SELECT payload FROM analytics_sessions WHERE account_id = ? ORDER BY started_at", [.text(accountID)])
    }

    func readFocusSessionsForMigration() throws -> [FocusSessionRecord]? {
        let url = fileURL(for: AppConstants.AnalyticsSettings.focusSessionsFile)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do { return try decoder.decode([FocusSessionRecord].self, from: Data(contentsOf: url)) }
        catch {
            Logger.store.error("Read legacy focus sessions failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func loadAppActivityEvents() -> [AppActivityEvent] {
        migrateLegacyAnalyticsJSON()
        return query("SELECT payload FROM app_activity WHERE account_id = ? ORDER BY started_at", [.text(accountID)])
    }

    @discardableResult
    func appendAppActivityEvents(_ events: [AppActivityEvent]) -> Bool {
        batch { try insert(events) }
    }

    func loadWebsiteVisits() -> [WebsiteVisitRecord] {
        migrateLegacyAnalyticsJSON()
        return query("SELECT payload FROM website_visits WHERE account_id = ? ORDER BY started_at", [.text(accountID)])
    }

    @discardableResult
    func appendWebsiteVisits(_ records: [WebsiteVisitRecord]) -> Bool {
        batch { try insert(records) }
    }

    @discardableResult
    func deleteActivity(sessionID: UUID) -> Bool {
        guard let database else { return false }
        do {
            try database.transaction {
                try database.execute("DELETE FROM app_activity WHERE account_id = ? AND session_id = ?",
                                     [.text(accountID), .text(sessionID.uuidString)])
                try database.execute("DELETE FROM website_visits WHERE account_id = ? AND session_id = ?",
                                     [.text(accountID), .text(sessionID.uuidString)])
            }
            return true
        } catch { log(error, action: "Remove activity after consent withdrawal"); return false }
    }

    @discardableResult
    func pruneOldData(now: Date = Date()) -> Bool {
        migrateLegacyAnalyticsJSON()
        guard let database else { return false }
        let cutoff = Calendar.current.date(
            byAdding: .day, value: -AppConstants.AnalyticsSettings.retentionDays, to: now
        )?.timeIntervalSince1970 ?? now.timeIntervalSince1970
        do {
            try database.transaction {
                for table in ["analytics_sessions", "app_activity", "website_visits"] {
                    try database.execute("DELETE FROM \(table) WHERE account_id = ? AND started_at < ?",
                                         [.text(accountID), .real(cutoff)])
                }
            }
            return true
        } catch {
            Logger.store.error("Prune analytics failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func migrateLegacyAnalyticsJSON() {
        guard shouldMigrateLegacyJSON else { return }
        guard let database, (try? database.hasMigration("analytics-json-v1")) == false else { return }
        do {
            try database.transaction {
                try importJSON(FocusSessionRecord.self, file: AppConstants.AnalyticsSettings.focusSessionsFile) { records in
                    for record in records { try insert(record) }
                }
                try importJSON(AppActivityEvent.self, file: AppConstants.AnalyticsSettings.appActivityFile) { events in
                    try insert(events)
                }
                try importJSON(WebsiteVisitRecord.self, file: AppConstants.AnalyticsSettings.websiteVisitsFile) { visits in
                    try insert(visits)
                }
                try database.markMigration("analytics-json-v1")
            }
        } catch {
            Logger.store.error("Migrate analytics JSON failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func importJSON<T: Decodable>(_ type: T.Type, file: String, importRecords: ([T]) throws -> Void) throws {
        let url = fileURL(for: file)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let records = try decoder.decode([T].self, from: Data(contentsOf: url))
        try importRecords(records)
    }

    private func insert(_ record: FocusSessionRecord) throws {
        try execute("""
            INSERT INTO analytics_sessions(id, account_id, started_at, payload) VALUES(?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET account_id = excluded.account_id,
                started_at = excluded.started_at, payload = excluded.payload
            """, [.text(record.id.uuidString), .text(accountID), .real(record.startedAt.timeIntervalSince1970),
                  .blob(try encoder.encode(record))])
    }

    private func insert(_ events: [AppActivityEvent]) throws {
        for event in events {
            try execute("""
                INSERT INTO app_activity(id, account_id, session_id, started_at, payload) VALUES(?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET payload = excluded.payload
                """, [.text(event.id.uuidString), .text(accountID), .text(event.sessionID.uuidString),
                      .real(event.startedAt.timeIntervalSince1970), .blob(try encoder.encode(event))])
        }
    }

    private func insert(_ visits: [WebsiteVisitRecord]) throws {
        for visit in visits {
            try execute("""
                INSERT INTO website_visits(id, account_id, session_id, started_at, payload) VALUES(?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET payload = excluded.payload
                """, [.text(visit.id.uuidString), .text(accountID), .text(visit.sessionID.uuidString),
                      .real(visit.startedAt.timeIntervalSince1970), .blob(try encoder.encode(visit))])
        }
    }

    private func batch(_ work: () throws -> Void) -> Bool {
        guard let database else { return false }
        migrateLegacyAnalyticsJSON()
        do { try database.transaction(work); return true }
        catch { log(error, action: "Save analytics batch"); return false }
    }

    private func query<T: Decodable>(_ sql: String, _ values: [QomaDatabase.Value]) -> [T] {
        guard let database else { return [] }
        do {
            let rows = try database.query(sql, values)
            return rows.compactMap { row in
            guard case .blob(let data)? = row["payload"] else { return nil }
            return try? decoder.decode(T.self, from: data)
            }
        } catch { log(error, action: "Read analytics records"); return [] }
    }

    private func execute(_ sql: String, _ values: [QomaDatabase.Value]) throws {
        guard let database else { throw QomaDatabase.error("Database unavailable") }
        try database.execute(sql, values)
    }

    private func fileURL(for filename: String) -> URL {
        (storageDirectory ?? AppConstants.AnalyticsSettings.analyticsDirectoryURL).appendingPathComponent(filename)
    }

    private func log(_ error: Error, action: String) {
        Logger.store.error("\(action, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
    }
}
