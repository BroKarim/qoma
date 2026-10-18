import Foundation
import OSLog

protocol SessionRepositoryProtocol: Sendable {
    func loadActive(accountID: String) -> ActiveSessionSnapshot?
    func saveActive(_ snapshot: ActiveSessionSnapshot) -> Bool
    func deleteActive(accountID: String) -> Bool
    func finalizeOnce(_ session: FocusSession) -> Bool
    func loadHistory(accountID: String) -> [FocusSession]
}

/// SQLite-backed active session and history repository.
final class SessionRepository: SessionRepositoryProtocol, @unchecked Sendable {
    static let shared = SessionRepository()

    private let database: QomaDatabase?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storageDirectory: URL?
    private let historyDirectoryURL: URL?
    private let shouldMigrateLegacyJSON: Bool

    init(storageDirectory: URL? = nil, historyDirectoryURL: URL? = nil, database: QomaDatabase? = nil) {
        self.storageDirectory = storageDirectory
        self.historyDirectoryURL = historyDirectoryURL
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

    func loadActive(accountID: String) -> ActiveSessionSnapshot? {
        migrateLegacyActiveIfNeeded(accountID: accountID)
        guard let database else { return nil }
        let rows: [[String: QomaDatabase.Value]]
        do {
            rows = try database.query(
                "SELECT payload FROM sessions WHERE account_id = ? AND record_type = 'active' ORDER BY started_at DESC LIMIT 1",
                [.text(accountID)]
            )
        } catch {
            Logger.store.error("Read active session failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
        guard let row = rows.first, case .blob(let data)? = row["payload"] else { return nil }
        do { return try decoder.decode(ActiveSessionSnapshot.self, from: data) }
        catch {
            Logger.store.error("Decode active session failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func saveActive(_ snapshot: ActiveSessionSnapshot) -> Bool {
        guard let database, let data = try? encoder.encode(snapshot) else { return false }
        do {
            try database.execute("""
                INSERT INTO sessions(id, account_id, started_at, ended_at, record_type, payload)
                VALUES(?, ?, ?, ?, 'active', ?)
                ON CONFLICT(id) DO UPDATE SET account_id = excluded.account_id,
                    started_at = excluded.started_at, ended_at = excluded.ended_at,
                    record_type = 'active', payload = excluded.payload
                WHERE sessions.record_type = 'active'
                """, [
                    .text(snapshot.id.uuidString), .text(snapshot.accountID),
                    .real(snapshot.startedAt.timeIntervalSince1970),
                    snapshot.endedAt.map { .real($0.timeIntervalSince1970) } ?? .null, .blob(data)
                ])
            return true
        } catch {
            Logger.store.error("Save active session failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func deleteActive(accountID: String) -> Bool {
        do {
            try database?.execute("DELETE FROM sessions WHERE account_id = ? AND record_type = 'active'", [.text(accountID)])
            return database != nil
        } catch {
            Logger.store.error("Delete active session failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func loadHistory(accountID: String) -> [FocusSession] {
        migrateLegacyHistoryIfNeeded(accountID: accountID)
        guard let database else { return [] }
        let rows: [[String: QomaDatabase.Value]]
        do {
            rows = try database.query(
                "SELECT payload FROM sessions WHERE account_id = ? AND record_type = 'history' ORDER BY started_at",
                [.text(accountID)]
            )
        } catch {
            Logger.store.error("Read session history failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
        return rows.compactMap { row in
            guard case .blob(let data)? = row["payload"] else { return nil }
            return try? decoder.decode(FocusSession.self, from: data)
        }
    }

    func importHistory(_ sessions: [FocusSession]) -> Bool {
        guard let database else { return false }
        do {
            try database.transaction {
                for session in sessions {
                    try database.execute("""
                        INSERT OR IGNORE INTO sessions(id, account_id, started_at, ended_at, record_type, payload)
                        VALUES(?, ?, ?, ?, 'history', ?)
                        """, [
                            .text(session.id.uuidString), .text(session.accountID),
                            .real(session.startedAt.timeIntervalSince1970),
                            .real(session.endedAt.timeIntervalSince1970), .blob(try encoder.encode(session))
                        ])
                }
            }
            return true
        } catch {
            Logger.store.error("Import session history failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func finalizeOnce(_ session: FocusSession) -> Bool {
        guard let database, let data = try? encoder.encode(session) else { return false }
        do {
            try database.execute("""
                INSERT INTO sessions(id, account_id, started_at, ended_at, record_type, payload)
                VALUES(?, ?, ?, ?, 'history', ?)
                ON CONFLICT(id) DO UPDATE SET account_id = excluded.account_id,
                    started_at = excluded.started_at, ended_at = excluded.ended_at,
                    record_type = 'history', payload = excluded.payload
                WHERE sessions.record_type = 'active'
                """, [
                    .text(session.id.uuidString), .text(session.accountID),
                    .real(session.startedAt.timeIntervalSince1970), .real(session.endedAt.timeIntervalSince1970), .blob(data)
                ])
            return true
        } catch {
            Logger.store.error("Finalize session failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func migrateLegacyActiveIfNeeded(accountID: String) {
        guard shouldMigrateLegacyJSON else { return }
        let key = "legacy.active.\(accountID)"
        guard let database, (try? database.hasMigration(key)) == false,
              let data = try? Data(contentsOf: activeFileURL(accountID: accountID)) else { return }
        guard let snapshot = try? decoder.decode(ActiveSessionSnapshot.self, from: data),
              saveActive(snapshot) else { return }
        try? database.markMigration(key)
    }

    private func migrateLegacyHistoryIfNeeded(accountID: String) {
        guard shouldMigrateLegacyJSON else { return }
        let key = "legacy.history.\(accountID)"
        guard let database, (try? database.hasMigration(key)) == false else { return }
        let url = historyFileURL(accountID: accountID)
        if let data = try? Data(contentsOf: url) {
            guard let sessions = try? decoder.decode([FocusSession].self, from: data), importHistory(sessions) else { return }
        }
        try? database.markMigration(key)
    }

    private func activeFileURL(accountID: String) -> URL {
        directoryURL().appendingPathComponent("active-\(sanitized(accountID)).json")
    }

    private func historyFileURL(accountID: String) -> URL {
        (historyDirectoryURL ?? directoryURL()).appendingPathComponent("history-\(sanitized(accountID)).json")
    }

    private func directoryURL() -> URL {
        storageDirectory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Qoma/Sessions")
    }

    private func sanitized(_ accountID: String) -> String {
        accountID.map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
    }
}
