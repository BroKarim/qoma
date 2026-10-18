import Foundation
import SQLite3
import OSLog

/// Shared, transactional store for the local session, catch, and analytics ledgers.
final class QomaDatabase: @unchecked Sendable {
    enum Value {
        case text(String)
        case integer(Int64)
        case real(Double)
        case blob(Data)
        case null
    }

    static let shared: QomaDatabase? = {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Qoma", isDirectory: true)
        do { return try QomaDatabase(url: root.appendingPathComponent("qoma.sqlite3")) }
        catch {
            Logger.store.error("Open Qoma database failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }()

    private let connection: OpaquePointer
    private let lock = NSRecursiveLock()

    init(url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var connection: OpaquePointer?
        guard sqlite3_open_v2(
            url.path, &connection, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil
        ) == SQLITE_OK, let connection else {
            let message = connection.map { String(cString: sqlite3_errmsg($0)) } ?? "unable to open database"
            if let connection { sqlite3_close(connection) }
            throw Self.error(message)
        }
        self.connection = connection
        sqlite3_busy_timeout(connection, 5_000)
        do {
            try execute("PRAGMA journal_mode=WAL")
            try execute("PRAGMA synchronous=FULL")
            try execute("PRAGMA foreign_keys=ON")
            try executeScript("""
                CREATE TABLE IF NOT EXISTS catches (
                    id TEXT PRIMARY KEY, account_id TEXT NOT NULL, session_id TEXT NOT NULL,
                    kind_id TEXT NOT NULL, deposited_at REAL NOT NULL, banked_at REAL, payload BLOB NOT NULL
                );
                CREATE INDEX IF NOT EXISTS catches_account_date ON catches(account_id, deposited_at);
                CREATE INDEX IF NOT EXISTS catches_account_kind ON catches(account_id, kind_id);
                CREATE INDEX IF NOT EXISTS catches_session ON catches(account_id, session_id, banked_at);
                CREATE TABLE IF NOT EXISTS sessions (
                    id TEXT PRIMARY KEY, account_id TEXT NOT NULL, started_at REAL NOT NULL,
                    ended_at REAL, record_type TEXT NOT NULL, payload BLOB NOT NULL
                );
                CREATE INDEX IF NOT EXISTS sessions_account_date ON sessions(account_id, started_at);
                CREATE TABLE IF NOT EXISTS analytics_sessions (
                    id TEXT PRIMARY KEY, account_id TEXT NOT NULL, started_at REAL NOT NULL,
                    payload BLOB NOT NULL
                );
                CREATE INDEX IF NOT EXISTS analytics_sessions_account_date
                    ON analytics_sessions(account_id, started_at);
                CREATE TABLE IF NOT EXISTS app_activity (
                    id TEXT PRIMARY KEY, account_id TEXT NOT NULL, session_id TEXT NOT NULL,
                    started_at REAL NOT NULL, payload BLOB NOT NULL
                );
                CREATE INDEX IF NOT EXISTS app_activity_account_date ON app_activity(account_id, started_at);
                CREATE INDEX IF NOT EXISTS app_activity_session ON app_activity(account_id, session_id, started_at);
                CREATE TABLE IF NOT EXISTS website_visits (
                    id TEXT PRIMARY KEY, account_id TEXT NOT NULL, session_id TEXT NOT NULL,
                    started_at REAL NOT NULL, payload BLOB NOT NULL
                );
                CREATE INDEX IF NOT EXISTS website_visits_account_date ON website_visits(account_id, started_at);
                CREATE INDEX IF NOT EXISTS website_visits_session ON website_visits(account_id, session_id, started_at);
                CREATE TABLE IF NOT EXISTS migrations (
                    key TEXT PRIMARY KEY, completed_at REAL NOT NULL
                );
                """)
        } catch {
            sqlite3_close(connection)
            throw error
        }
    }

    deinit { sqlite3_close(connection) }

    func execute(_ sql: String, _ values: [Value] = []) throws {
        lock.lock()
        defer { lock.unlock() }
        let statement = try prepare(sql, values)
        defer { sqlite3_finalize(statement) }
        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE || result == SQLITE_ROW else { throw databaseError() }
    }

    private func executeScript(_ sql: String) throws {
        lock.lock()
        defer { lock.unlock() }
        var message: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(connection, sql, nil, nil, &message) == SQLITE_OK else {
            let detail = message.map { String(cString: $0) } ?? String(cString: sqlite3_errmsg(connection))
            sqlite3_free(message)
            throw Self.error(detail)
        }
    }

    func query(_ sql: String, _ values: [Value] = []) throws -> [[String: Value]] {
        lock.lock()
        defer { lock.unlock() }
        let statement = try prepare(sql, values)
        defer { sqlite3_finalize(statement) }
        var rows: [[String: Value]] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { return rows }
            guard result == SQLITE_ROW else { throw databaseError() }
            var row: [String: Value] = [:]
            for index in 0..<sqlite3_column_count(statement) {
                guard let name = sqlite3_column_name(statement, index) else { continue }
                switch sqlite3_column_type(statement, index) {
                case SQLITE_INTEGER: row[String(cString: name)] = .integer(sqlite3_column_int64(statement, index))
                case SQLITE_FLOAT: row[String(cString: name)] = .real(sqlite3_column_double(statement, index))
                case SQLITE_BLOB:
                    let count = Int(sqlite3_column_bytes(statement, index))
                    if let pointer = sqlite3_column_blob(statement, index) {
                        row[String(cString: name)] = .blob(Data(bytes: pointer, count: count))
                    }
                case SQLITE_NULL: row[String(cString: name)] = .null
                default:
                    if let text = sqlite3_column_text(statement, index) {
                        row[String(cString: name)] = .text(String(cString: text))
                    }
                }
            }
            rows.append(row)
        }
    }

    func transaction(_ work: () throws -> Void) throws {
        lock.lock()
        defer { lock.unlock() }
        try execute("BEGIN IMMEDIATE")
        do {
            try work()
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    func hasMigration(_ key: String) throws -> Bool {
        try !query("SELECT key FROM migrations WHERE key = ?", [.text(key)]).isEmpty
    }

    func markMigration(_ key: String) throws {
        try execute("INSERT OR IGNORE INTO migrations(key, completed_at) VALUES(?, ?)",
                    [.text(key), .real(Date().timeIntervalSince1970)])
    }

    static func error(_ message: String) -> NSError {
        NSError(domain: "QomaDatabase", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func prepare(_ sql: String, _ values: [Value]) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(connection, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw databaseError()
        }
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let result: Int32
            switch value {
            case .text(let value):
                result = value.withCString { sqlite3_bind_text(statement, index, $0, -1, sqliteTransient) }
            case .integer(let value): result = sqlite3_bind_int64(statement, index, value)
            case .real(let value): result = sqlite3_bind_double(statement, index, value)
            case .blob(let value):
                result = value.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, index, bytes.baseAddress, Int32(bytes.count), sqliteTransient)
                }
            case .null: result = sqlite3_bind_null(statement, index)
            }
            guard result == SQLITE_OK else {
                sqlite3_finalize(statement)
                throw databaseError()
            }
        }
        return statement
    }

    private func databaseError() -> NSError {
        Self.error(String(cString: sqlite3_errmsg(connection)))
    }
}

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
