import Foundation
import Testing
@testable import Qoma

struct LocalAccountMigratorTests {
    @Test func importIsAtomicAndKeepsBackup() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let database = try QomaDatabase(url: root.appendingPathComponent("store.sqlite3"))
        let payload = try JSONSerialization.data(withJSONObject: ["accountID": "local", "value": 42])
        try database.execute("INSERT INTO sessions(id, account_id, started_at, record_type, payload) VALUES(?, 'local', 0, 'history', ?)",
                             [.text(UUID().uuidString), .blob(payload)])
        let backup = root.appendingPathComponent("backup.sqlite3")
        #expect(LocalAccountMigrator.hasLocalData(database: database))
        #expect(try LocalAccountMigrator.importToAccount("user-1", database: database, backupURL: backup))
        #expect(FileManager.default.fileExists(atPath: backup.path))
        #expect(try !LocalAccountMigrator.importToAccount("user-2", database: database, backupURL: root.appendingPathComponent("second.sqlite3")))
        let rows = try database.query("SELECT account_id, payload FROM sessions")
        guard case .text(let account)? = rows.first?["account_id"], case .blob(let data)? = rows.first?["payload"],
              let body = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            Issue.record("Imported row missing")
            return
        }
        #expect(account == "user-1")
        #expect(body["accountID"] as? String == "user-1")
    }

    @Test func backupFailureLeavesLocalRowsUntouched() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let database = try QomaDatabase(url: root.appendingPathComponent("store.sqlite3"))
        try database.execute("INSERT INTO sessions(id, account_id, started_at, record_type, payload) VALUES(?, 'local', 0, 'history', ?)",
                             [.text(UUID().uuidString), .blob(Data("{}".utf8))])
        let parentFile = root.appendingPathComponent("not-a-directory")
        try Data("x".utf8).write(to: parentFile)
        #expect(throws: Error.self) {
            try LocalAccountMigrator.importToAccount("user-1", database: database,
                                                     backupURL: parentFile.appendingPathComponent("backup.sqlite3"))
        }
        #expect(try database.query("SELECT 1 FROM sessions WHERE account_id = 'local'").count == 1)
        #expect(try !database.hasMigration("local-account-import-v1"))
    }
}
