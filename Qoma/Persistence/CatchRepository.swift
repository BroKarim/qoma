import Foundation
import OSLog

/// Abstract repository for catch ledger persistence.
protocol CatchRepositoryProtocol: Sendable {
    func saveProvisional(_ event: CatchEvent)
    func bank(_ eventID: UUID, accountID: String, at: Date)
    func listBanked(accountID: String) -> [CatchEvent]
    func listProvisional(sessionID: UUID, accountID: String) -> [CatchEvent]
    func countByKind(accountID: String) -> [String: Int]
    func deleteProvisional(sessionID: UUID, accountID: String)
}

/// JSON-backed catch ledger. Provisional events live only for the active session.
final class CatchRepository: CatchRepositoryProtocol, @unchecked Sendable {
    static let shared = CatchRepository()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let ioQueue = DispatchQueue(label: "com.dzulkiram.qoma.catchrepository.io")
    private let queueKey = DispatchSpecificKey<Void>()

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
        return appSupport.appendingPathComponent("Qoma").appendingPathComponent("Catches")
    }

    private func provisionalFileURL(sessionID: UUID, accountID: String) -> URL {
        directoryURL().appendingPathComponent("provisional-\(sanitized(accountID))-\(sessionID.uuidString).json")
    }

    private func bankedFileURL(accountID: String) -> URL {
        directoryURL().appendingPathComponent("banked-\(sanitized(accountID)).json")
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

    // MARK: - Provisional

    func saveProvisional(_ event: CatchEvent) {
        syncIO {
            var events = loadProvisionalSync(sessionID: event.sessionID, accountID: event.accountID)
            events.removeAll { $0.id == event.id }
            events.append(event)

            let url = provisionalFileURL(sessionID: event.sessionID, accountID: event.accountID)
            do {
                let data = try encoder.encode(events)
                try data.write(to: url, options: .atomic)
            } catch {
                Logger.store.error("Save provisional catch failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func listProvisional(sessionID: UUID, accountID: String) -> [CatchEvent] {
        syncIO {
            loadProvisionalSync(sessionID: sessionID, accountID: accountID)
        }
    }

    private func loadProvisionalSync(sessionID: UUID, accountID: String) -> [CatchEvent] {
        let url = provisionalFileURL(sessionID: sessionID, accountID: accountID)
        guard let data = try? Data(contentsOf: url) else { return [] }
        do {
            return try decoder.decode([CatchEvent].self, from: data)
        } catch {
            Logger.store.error("Decode provisional catch failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func deleteProvisional(sessionID: UUID, accountID: String) {
        syncIO {
            let url = provisionalFileURL(sessionID: sessionID, accountID: accountID)
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Banked

    func bank(_ eventID: UUID, accountID: String, at: Date) {
        syncIO {
            guard var event = findProvisionalSync(eventID: eventID, accountID: accountID) else {
                Logger.store.warning("bank called for unknown provisional \(eventID, privacy: .public)")
                return
            }

            event.bankedAt = at

            var banked = loadBankedSync(accountID: accountID)
            banked.removeAll { $0.id == event.id }
            banked.append(event)

            let url = bankedFileURL(accountID: accountID)
            do {
                let data = try encoder.encode(banked)
                try data.write(to: url, options: .atomic)
                Logger.store.info("Banked catch \(eventID, privacy: .public)")
            } catch {
                Logger.store.error("Bank catch failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func listBanked(accountID: String) -> [CatchEvent] {
        syncIO {
            loadBankedSync(accountID: accountID)
        }
    }

    private func loadBankedSync(accountID: String) -> [CatchEvent] {
        let url = bankedFileURL(accountID: accountID)
        guard let data = try? Data(contentsOf: url) else { return [] }
        do {
            return try decoder.decode([CatchEvent].self, from: data)
        } catch {
            Logger.store.error("Decode banked catch failed: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func countByKind(accountID: String) -> [String: Int] {
        let banked = listBanked(accountID: accountID)
        var counts: [String: Int] = [:]
        for event in banked {
            counts[event.kindID, default: 0] += 1
        }
        return counts
    }

    // MARK: - Helpers

    private func findProvisionalSync(eventID: UUID, accountID: String) -> CatchEvent? {
        let directory = directoryURL()
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for case let url as URL in enumerator {
            guard url.lastPathComponent.hasPrefix("provisional-\(sanitized(accountID))-") else { continue }
            guard let data = try? Data(contentsOf: url) else { continue }
            guard let events = try? decoder.decode([CatchEvent].self, from: data) else { continue }
            if let event = events.first(where: { $0.id == eventID }) {
                return event
            }
        }
        return nil
    }

    private func syncIO<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            return work()
        }
        return ioQueue.sync(execute: work)
    }
}
