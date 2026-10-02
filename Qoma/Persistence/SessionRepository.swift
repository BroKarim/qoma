import Foundation
import OSLog

/// Abstract repository for session persistence.
protocol SessionRepositoryProtocol: Sendable {
    func loadActive(accountID: String) -> ActiveSessionSnapshot?
    func saveActive(_ snapshot: ActiveSessionSnapshot)
    func deleteActive(accountID: String)
    func finalizeOnce(_ session: FocusSession)
    func loadHistory(accountID: String) -> [FocusSession]
}

/// JSON-backed repository with atomic writes.
/// Designed so a SwiftData implementation can adopt the same protocol.
final class SessionRepository: SessionRepositoryProtocol, @unchecked Sendable {
    static let shared = SessionRepository()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let ioQueue = DispatchQueue(label: "com.dzulkiram.qoma.sessionrepository.io")
    private let queueKey = DispatchSpecificKey<Void>()
    private var finalizedIDs: Set<UUID> = []

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        ioQueue.setSpecific(key: queueKey, value: ())
        bootstrapDirectory()
    }

    // MARK: - Directory

    private func bootstrapDirectory() {
        let url = directoryURL()
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func directoryURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Qoma").appendingPathComponent("Sessions")
    }

    private func activeFileURL(accountID: String) -> URL {
        directoryURL().appendingPathComponent("active-\(sanitized(accountID)).json")
    }

    private func historyFileURL(accountID: String) -> URL {
        directoryURL().appendingPathComponent("history-\(sanitized(accountID)).json")
    }

    private func sanitized(_ accountID: String) -> String {
        accountID.map { char -> String in
            let scalar = String(char).unicodeScalars.first!
            if CharacterSet.alphanumerics.contains(scalar) {
                return String(char)
            }
            return "-"
        }.joined()
    }

    // MARK: - Active snapshot

    func loadActive(accountID: String) -> ActiveSessionSnapshot? {
        syncIO {
            let url = activeFileURL(accountID: accountID)
            guard let data = try? Data(contentsOf: url) else { return nil }
            do {
                return try decoder.decode(ActiveSessionSnapshot.self, from: data)
            } catch {
                Logger.store.error("Decode active snapshot failed: \(error.localizedDescription, privacy: .public)")
                return nil
            }
        }
    }

    func saveActive(_ snapshot: ActiveSessionSnapshot) {
        syncIO {
            let url = activeFileURL(accountID: snapshot.accountID)
            do {
                let data = try encoder.encode(snapshot)
                try data.write(to: url, options: .atomic)
            } catch {
                Logger.store.error("Save active snapshot failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func deleteActive(accountID: String) {
        syncIO {
            let url = activeFileURL(accountID: accountID)
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - History

    func loadHistory(accountID: String) -> [FocusSession] {
        syncIO {
            let url = historyFileURL(accountID: accountID)
            guard let data = try? Data(contentsOf: url) else { return [] }
            do {
                return try decoder.decode([FocusSession].self, from: data)
            } catch {
                Logger.store.error("Decode history failed: \(error.localizedDescription, privacy: .public)")
                return []
            }
        }
    }

    func finalizeOnce(_ session: FocusSession) {
        syncIO {
            guard !finalizedIDs.contains(session.id) else {
                Logger.store.info("finalizeOnce skipped duplicate \(session.id, privacy: .public)")
                return
            }

            let url = historyFileURL(accountID: session.accountID)
            var history = (try? Data(contentsOf: url)).flatMap {
                try? decoder.decode([FocusSession].self, from: $0)
            } ?? []

            history.removeAll { $0.id == session.id }
            history.append(session)

            do {
                let data = try encoder.encode(history)
                try data.write(to: url, options: .atomic)
                finalizedIDs.insert(session.id)
                Logger.store.info("Finalized session \(session.id, privacy: .public)")
            } catch {
                Logger.store.error("Finalize session failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - IO helper

    private func syncIO<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            return work()
        }
        return ioQueue.sync(execute: work)
    }
}
