import Foundation

enum LocalAccountMigrator {
    private static let marker = "local-account-import-v1"
    private static let tables = [
        "sessions", "catches", "catch_progress", "analytics_sessions", "app_activity", "website_visits"
    ]

    static func hasLocalData(database: QomaDatabase? = QomaDatabase.shared) -> Bool {
        guard let database, (try? database.hasMigration(marker)) == false else { return false }
        for table in tables {
            guard let rows = try? database.query("SELECT 1 FROM \(table) WHERE account_id = 'local' LIMIT 1") else { return false }
            if !rows.isEmpty { return true }
        }
        return false
    }

    @discardableResult
    static func importToAccount(_ accountID: String, database: QomaDatabase? = QomaDatabase.shared,
                                backupURL: URL? = nil) throws -> Bool {
        guard accountID != "local", accountID != "signed-out", let database else { return false }
        guard try !database.hasMigration(marker) else { return false }
        guard hasLocalData(database: database) else { return false }
        let backup = backupURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Qoma/backups/pre-account-import-\(UUID().uuidString).sqlite3")
        try database.backup(to: backup)
        try database.transaction {
            let targetProgress = try database.query("SELECT 1 FROM catch_progress WHERE account_id = ?", [.text(accountID)])
            let localProgress = try database.query("SELECT 1 FROM catch_progress WHERE account_id = 'local'")
            if !targetProgress.isEmpty && !localProgress.isEmpty {
                throw QomaDatabase.error("Existing account progress needs manual merge; local data was not changed")
            }
            for table in tables {
                let rows = try database.query("SELECT rowid, payload FROM \(table) WHERE account_id = 'local'")
                for row in rows {
                    guard case .integer(let rowID)? = row["rowid"], case .blob(let payload)? = row["payload"] else {
                        throw QomaDatabase.error("Local row could not be decoded; no data changed")
                    }
                    let object = try JSONSerialization.jsonObject(with: payload)
                    var changed = object as? [String: Any]
                    if changed?["accountID"] as? String == "local" { changed?["accountID"] = accountID }
                    let updated = try changed.map { try JSONSerialization.data(withJSONObject: $0) } ?? payload
                    try database.execute("UPDATE \(table) SET account_id = ?, payload = ? WHERE rowid = ? AND account_id = 'local'",
                                         [.text(accountID), .blob(updated), .integer(rowID)])
                }
            }
            try database.markMigration(marker)
        }
        return true
    }
}
