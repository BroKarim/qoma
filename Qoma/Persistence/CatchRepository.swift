import Foundation
import OSLog

protocol CatchRepositoryProtocol: Sendable {
    func saveProvisional(_ event: CatchEvent) -> Bool
    func bank(_ eventID: UUID, sessionID: UUID, accountID: String, at: Date) -> Bool
    func bankProvisional(sessionID: UUID, accountID: String, at: Date) -> Bool
    func listBanked(accountID: String) -> [CatchEvent]
    func listProvisional(sessionID: UUID, accountID: String) -> [CatchEvent]
    func countByKind(accountID: String) -> [String: Int]
    func accountProgress(
        accountID: String,
        provisionalSessionID: UUID?
    ) -> (progress: CatchAccountProgress, pity: CatchPityState)
    func saveCatchCycle(_ cycle: CatchCycleState, accountID: String) -> Bool
    func deleteProvisional(sessionID: UUID, accountID: String) -> Bool
}

extension CatchRepositoryProtocol {
    func accountProgress(accountID: String) -> (progress: CatchAccountProgress, pity: CatchPityState) {
        accountProgress(accountID: accountID, provisionalSessionID: nil)
    }
}

/// SQLite-backed catch ledger. Rows are indexed by account, session, date, and kind.
final class CatchRepository: CatchRepositoryProtocol, @unchecked Sendable {
    static let shared = CatchRepository()

    private let database: QomaDatabase?
    private let storageDirectory: URL?
    private let shouldMigrateLegacyJSON: Bool
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(storageDirectory: URL? = nil, database: QomaDatabase? = nil) {
        self.storageDirectory = storageDirectory
        shouldMigrateLegacyJSON = storageDirectory != nil || database == nil
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        if let database {
            self.database = database
        } else if let storageDirectory {
            self.database = try? QomaDatabase(url: storageDirectory.appendingPathComponent("qoma.sqlite3"))
        } else {
            self.database = QomaDatabase.shared
        }
    }

    func saveProvisional(_ event: CatchEvent) -> Bool {
        guard migrateLegacyJSON(accountID: event.accountID) else { return false }
        return save(CatchEvent(
            id: event.id,
            sessionID: event.sessionID,
            accountID: event.accountID,
            kindID: event.kindID,
            depositedAt: event.depositedAt
        ))
    }

    func bank(_ eventID: UUID, sessionID: UUID, accountID: String, at: Date) -> Bool {
        guard migrateLegacyJSON(accountID: accountID), let database else { return false }
        do {
            try database.transaction {
                _ = loadProgress(accountID: accountID, database: database)
                let rows = try database.query(
                    "SELECT payload, banked_at FROM catches WHERE id = ? AND account_id = ? AND session_id = ?",
                    [.text(eventID.uuidString), .text(accountID), .text(sessionID.uuidString)]
                )
                guard let row = rows.first else { throw QomaDatabase.error("Catch to bank was not found") }
                if case .real? = row["banked_at"] { return }
                guard let event = decode(CatchEvent.self, from: row["payload"]) else {
                    throw QomaDatabase.error("Catch to bank could not be decoded")
                }
                let banked = CatchEvent(
                    id: event.id,
                    sessionID: event.sessionID,
                    accountID: event.accountID,
                    kindID: event.kindID,
                    depositedAt: event.depositedAt,
                    bankedAt: at
                )
                try database.execute(
                    "UPDATE catches SET banked_at = ?, payload = ? WHERE id = ? AND banked_at IS NULL",
                    [.real(at.timeIntervalSince1970), .blob(try encoder.encode(banked)), .text(eventID.uuidString)]
                )
                try advanceBankedPity(event, accountID: accountID, database: database)
            }
            return true
        } catch {
            Logger.store.error("Bank catch failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func bankProvisional(sessionID: UUID, accountID: String, at: Date) -> Bool {
        guard let database, migrateLegacyJSON(accountID: accountID) else { return false }
        do {
            try database.transaction {
                _ = loadProgress(accountID: accountID, database: database)
                let rows = try database.query(
                    "SELECT payload FROM catches WHERE account_id = ? AND session_id = ? "
                        + "AND banked_at IS NULL ORDER BY deposited_at, id",
                    [.text(accountID), .text(sessionID.uuidString)]
                )
                let events = rows.compactMap { decode(CatchEvent.self, from: $0["payload"]) }
                guard events.count == rows.count else {
                    throw QomaDatabase.error("A provisional catch row could not be decoded")
                }
                for event in events {
                    let banked = CatchEvent(
                        id: event.id,
                        sessionID: event.sessionID,
                        accountID: event.accountID,
                        kindID: event.kindID,
                        depositedAt: event.depositedAt,
                        bankedAt: at
                    )
                    try database.execute(
                        "UPDATE catches SET banked_at = ?, payload = ? WHERE id = ? AND banked_at IS NULL",
                        [
                            .real(at.timeIntervalSince1970), .blob(try encoder.encode(banked)),
                            .text(event.id.uuidString)
                        ]
                    )
                    try advanceBankedPity(event, accountID: accountID, database: database)
                }
            }
            return true
        } catch {
            Logger.store.error("Bank provisional catches failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func listBanked(accountID: String) -> [CatchEvent] {
        guard migrateLegacyJSON(accountID: accountID) else { return [] }
        return list(
            "SELECT payload FROM catches WHERE account_id = ? AND banked_at IS NOT NULL ORDER BY deposited_at, id",
            [.text(accountID)]
        )
    }

    func listProvisional(sessionID: UUID, accountID: String) -> [CatchEvent] {
        guard migrateLegacyJSON(accountID: accountID) else { return [] }
        return list(
            "SELECT payload FROM catches WHERE account_id = ? AND session_id = ? "
                + "AND banked_at IS NULL ORDER BY deposited_at, id",
            [.text(accountID), .text(sessionID.uuidString)]
        )
    }

    func countByKind(accountID: String) -> [String: Int] {
        guard migrateLegacyJSON(accountID: accountID), let database else { return [:] }
        let rows: [[String: QomaDatabase.Value]]
        do {
            rows = try database.query(
                "SELECT kind_id, COUNT(*) AS total FROM catches WHERE account_id = ? "
                    + "AND banked_at IS NOT NULL GROUP BY kind_id",
                [.text(accountID)]
            )
        } catch {
            Logger.store.error("Count catches failed: \(error.localizedDescription, privacy: .public)")
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: rows.compactMap { row in
            guard case .text(let kind)? = row["kind_id"], case .integer(let total)? = row["total"] else { return nil }
            return (kind, Int(total))
        })
    }

    func accountProgress(
        accountID: String,
        provisionalSessionID: UUID? = nil
    ) -> (progress: CatchAccountProgress, pity: CatchPityState) {
        guard migrateLegacyJSON(accountID: accountID), let database else {
            return (CatchAccountProgress(), CatchPityState())
        }
        let progress = loadProgress(accountID: accountID, database: database)
        var predictedPity = progress.pity
        if let provisionalSessionID {
            for event in listProvisional(sessionID: provisionalSessionID, accountID: accountID) {
                CatchRarityRules.record(event.kindID, into: &predictedPity)
            }
        }
        return (progress, predictedPity)
    }

    func saveCatchCycle(_ cycle: CatchCycleState, accountID: String) -> Bool {
        guard migrateLegacyJSON(accountID: accountID), let database else { return false }
        do {
            try database.transaction {
                var progress = loadProgress(accountID: accountID, database: database)
                progress.cycle = cycle
                try saveProgress(progress, accountID: accountID, database: database)
            }
            return true
        } catch {
            Logger.store.error("Save catch progress failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func deleteProvisional(sessionID: UUID, accountID: String) -> Bool {
        guard migrateLegacyJSON(accountID: accountID) else { return false }
        do {
            try database?.execute("DELETE FROM catches WHERE account_id = ? AND session_id = ? AND banked_at IS NULL",
                                  [.text(accountID), .text(sessionID.uuidString)])
            return database != nil
        } catch {
            Logger.store.error("Delete provisional catches failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func save(_ event: CatchEvent) -> Bool {
        guard let database, let data = try? encoder.encode(event) else { return false }
        do {
            try database.execute("""
                INSERT OR IGNORE INTO catches(id, account_id, session_id, kind_id, deposited_at, banked_at, payload)
                VALUES(?, ?, ?, ?, ?, ?, ?)
                """, [
                    .text(event.id.uuidString), .text(event.accountID), .text(event.sessionID.uuidString),
                    .text(event.kindID), .real(event.depositedAt.timeIntervalSince1970),
                    event.bankedAt.map { .real($0.timeIntervalSince1970) } ?? .null, .blob(data)
                ])
            return true
        } catch {
            Logger.store.error("Save catch failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func loadProgress(accountID: String, database: QomaDatabase) -> CatchAccountProgress {
        if let row = try? database.query(
            "SELECT payload FROM catch_progress WHERE account_id = ?", [.text(accountID)]
        ).first, let value = row["payload"], let saved = decode(CatchAccountProgress.self, from: value) {
            return saved
        }
        var progress = CatchAccountProgress()
        let events = list(
            "SELECT payload FROM catches WHERE account_id = ? AND banked_at IS NOT NULL ORDER BY deposited_at, id",
            [.text(accountID)]
        )
        for event in events { CatchRarityRules.record(event.kindID, into: &progress.pity) }
        try? saveProgress(progress, accountID: accountID, database: database)
        return progress
    }

    private func saveProgress(
        _ progress: CatchAccountProgress,
        accountID: String,
        database: QomaDatabase
    ) throws {
        try database.execute(
            "INSERT INTO catch_progress(account_id, payload) VALUES(?, ?) "
                + "ON CONFLICT(account_id) DO UPDATE SET payload = excluded.payload",
            [.text(accountID), .blob(try encoder.encode(progress))]
        )
    }

    private func advanceBankedPity(_ event: CatchEvent, accountID: String, database: QomaDatabase) throws {
        var progress = loadProgress(accountID: accountID, database: database)
        CatchRarityRules.record(event.kindID, into: &progress.pity)
        try saveProgress(progress, accountID: accountID, database: database)
    }

    private func migrateLegacyJSON(accountID: String) -> Bool {
        guard shouldMigrateLegacyJSON else { return true }
        guard let database else { return false }
        let key = "legacy.catches.v1.\(accountID)"
        do {
            if try database.hasMigration(key) { return true }
            let directory = directoryURL()
            guard FileManager.default.fileExists(atPath: directory.path) else {
                try database.markMigration(key)
                return true
            }
            let prefix = "banked-event-\(sanitized(accountID))-"
            let provisionalPrefix = "provisional-\(sanitized(accountID))-"
            let candidates = try FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: nil
            ).filter { url in
                url.lastPathComponent == "banked-\(sanitized(accountID)).json"
                    || (url.lastPathComponent.hasPrefix(prefix) && url.pathExtension == "json")
                    || (url.lastPathComponent.hasPrefix(provisionalPrefix) && url.pathExtension == "json")
            }
            var events: [CatchEvent] = []
            for url in candidates {
                let data = try Data(contentsOf: url)
                if let event = try? decoder.decode(CatchEvent.self, from: data) {
                    events.append(event)
                } else {
                    events.append(contentsOf: try decoder.decode([CatchEvent].self, from: data))
                }
            }
            try database.transaction {
                for event in events {
                    try database.execute("""
                        INSERT OR IGNORE INTO catches(id, account_id, session_id, kind_id, deposited_at, banked_at, payload)
                        VALUES(?, ?, ?, ?, ?, ?, ?)
                        """, [
                            .text(event.id.uuidString), .text(event.accountID), .text(event.sessionID.uuidString),
                            .text(event.kindID), .real(event.depositedAt.timeIntervalSince1970),
                            event.bankedAt.map { .real($0.timeIntervalSince1970) } ?? .null,
                            .blob(try encoder.encode(event))
                        ])
                }
                try database.markMigration(key)
            }
            Logger.store.info("Migrated \(events.count) legacy catch records for local account")
            return true
        } catch {
            Logger.store.error("Migrate catch JSON failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func directoryURL() -> URL {
        if let storageDirectory { return storageDirectory }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Qoma/Catches")
    }

    private func sanitized(_ accountID: String) -> String {
        accountID.map { char in
            guard let scalar = String(char).unicodeScalars.first,
                  CharacterSet.alphanumerics.contains(scalar) else { return "-" }
            return String(char)
        }.joined()
    }

    private func list(_ sql: String, _ values: [QomaDatabase.Value]) -> [CatchEvent] {
        guard let database else { return [] }
        let rows: [[String: QomaDatabase.Value]]
        do { rows = try database.query(sql, values) }
        catch {
            Logger.store.error("Read catch records failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
        return rows.compactMap { row in
            guard let event = decode(CatchEvent.self, from: row["payload"]) else {
                Logger.store.error("A catch row could not be decoded")
                return nil
            }
            return event
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from value: QomaDatabase.Value?) -> T? {
        guard case .blob(let data)? = value else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
