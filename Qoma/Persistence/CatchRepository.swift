import Foundation
import OSLog

/// Abstract repository for catch ledger persistence.
protocol CatchRepositoryProtocol: Sendable {
    func saveProvisional(_ event: CatchEvent) -> Bool
    func bank(_ eventID: UUID, sessionID: UUID, accountID: String, at: Date) -> Bool
    func bankProvisional(sessionID: UUID, accountID: String, at: Date) -> Bool
    func listBanked(accountID: String) -> [CatchEvent]
    func listProvisional(sessionID: UUID, accountID: String) -> [CatchEvent]
    func countByKind(accountID: String) -> [String: Int]
    func deleteProvisional(sessionID: UUID, accountID: String) -> Bool
}

/// JSON-backed catch ledger. Provisional events live only for the active session.
final class CatchRepository: CatchRepositoryProtocol, @unchecked Sendable {
    static let shared = CatchRepository()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let ioQueue = DispatchQueue(label: "com.dzulkiram.qoma.catchrepository.io")
    private let queueKey = DispatchSpecificKey<Void>()
    private let storageDirectory: URL?

    init(storageDirectory: URL? = nil) {
        self.storageDirectory = storageDirectory
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
        if let storageDirectory { return storageDirectory }
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

    func saveProvisional(_ event: CatchEvent) -> Bool {
        syncIO {
            var events = loadProvisionalSync(sessionID: event.sessionID, accountID: event.accountID)
            events.removeAll { $0.id == event.id }
            events.append(event)

            let url = provisionalFileURL(sessionID: event.sessionID, accountID: event.accountID)
            do {
                let data = try encoder.encode(events)
                try data.write(to: url, options: .atomic)
                return true
            } catch {
                Logger.store.error("Save provisional catch failed: \(error.localizedDescription, privacy: .public)")
                return false
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

    func deleteProvisional(sessionID: UUID, accountID: String) -> Bool {
        syncIO {
            let url = provisionalFileURL(sessionID: sessionID, accountID: accountID)
            guard FileManager.default.fileExists(atPath: url.path) else { return true }
            do {
                try FileManager.default.removeItem(at: url)
                return true
            } catch {
                Logger.store.error("Delete provisional catches failed: \(error.localizedDescription, privacy: .public)")
                return false
            }
        }
    }

    // MARK: - Banked

    func bank(_ eventID: UUID, sessionID: UUID, accountID: String, at: Date) -> Bool {
        syncIO {
            guard var event = findProvisionalSync(eventID: eventID, sessionID: sessionID, accountID: accountID) else {
                Logger.store.warning("bank called for unknown provisional \(eventID, privacy: .public)")
                return false
            }

            event.bankedAt = at
            guard writeBankedEvent(event) else { return false }
            removeProvisionalEvent(eventID, sessionID: sessionID, accountID: accountID)
            Logger.store.info("Banked catch \(eventID, privacy: .public)")
            return true
        }
    }

    func bankProvisional(sessionID: UUID, accountID: String, at: Date) -> Bool {
        syncIO {
            let events = loadProvisionalSync(sessionID: sessionID, accountID: accountID)
            guard !events.isEmpty else { return true }
            for var event in events {
                event.bankedAt = at
                guard writeBankedEvent(event) else { return false }
            }
            let url = provisionalFileURL(sessionID: sessionID, accountID: accountID)
            do {
                try FileManager.default.removeItem(at: url)
                return true
            } catch {
                Logger.store.error("Clear banked provisional catches failed: \(error.localizedDescription, privacy: .public)")
                return false
            }
        }
    }

    func listBanked(accountID: String) -> [CatchEvent] {
        syncIO {
            loadBankedSync(accountID: accountID)
        }
    }

    private func loadBankedSync(accountID: String) -> [CatchEvent] {
        var events: [UUID: CatchEvent] = [:]
        if let data = try? Data(contentsOf: bankedFileURL(accountID: accountID)),
           let legacyEvents = try? decoder.decode([CatchEvent].self, from: data) {
            for event in legacyEvents { events[event.id] = event }
        }
        let prefix = "banked-event-\(sanitized(accountID))-"
        guard let files = try? FileManager.default.contentsOfDirectory(at: directoryURL(), includingPropertiesForKeys: nil)
        else { return Array(events.values) }
        for url in files where url.lastPathComponent.hasPrefix(prefix) && url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  let event = try? decoder.decode(CatchEvent.self, from: data) else { continue }
            events[event.id] = event
        }
        return Array(events.values)
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

    private func findProvisionalSync(eventID: UUID, sessionID: UUID, accountID: String) -> CatchEvent? {
        loadProvisionalSync(sessionID: sessionID, accountID: accountID).first { $0.id == eventID }
    }

    private func writeBankedEvent(_ event: CatchEvent) -> Bool {
        do {
            let url = directoryURL().appendingPathComponent(
                "banked-event-\(sanitized(event.accountID))-\(event.id.uuidString).json")
            let data = try encoder.encode(event)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            Logger.store.error("Bank catch failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func removeProvisionalEvent(_ eventID: UUID, sessionID: UUID, accountID: String) {
        let url = provisionalFileURL(sessionID: sessionID, accountID: accountID)
        var events = loadProvisionalSync(sessionID: sessionID, accountID: accountID)
        events.removeAll { $0.id == eventID }
        if events.isEmpty {
            try? FileManager.default.removeItem(at: url)
        } else if let data = try? encoder.encode(events) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func syncIO<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            return work()
        }
        return ioQueue.sync(execute: work)
    }
}
