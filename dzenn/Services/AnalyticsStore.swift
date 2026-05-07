import Foundation

final class AnalyticsStore {
    static let shared = AnalyticsStore()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        bootstrapDirectory()
    }

    // MARK: - Directory

    private func bootstrapDirectory() {
        let url = AppConstants.AnalyticsSettings.analyticsDirectoryURL
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func fileURL(for filename: String) -> URL {
        AppConstants.AnalyticsSettings.analyticsDirectoryURL.appendingPathComponent(filename)
    }

    // MARK: - Focus Sessions

    func loadFocusSessions() -> [FocusSessionRecord] {
        load(from: AppConstants.AnalyticsSettings.focusSessionsFile) ?? []
    }

    func saveFocusSessions(_ records: [FocusSessionRecord]) {
        save(records, to: AppConstants.AnalyticsSettings.focusSessionsFile)
    }

    func appendFocusSession(_ record: FocusSessionRecord) {
        var records = loadFocusSessions()
        records.append(record)
        saveFocusSessions(records)
    }

    func updateFocusSession(_ record: FocusSessionRecord) {
        var records = loadFocusSessions()
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
        saveFocusSessions(records)
    }

    // MARK: - App Activity

    func loadAppActivityEvents() -> [AppActivityEvent] {
        load(from: AppConstants.AnalyticsSettings.appActivityFile) ?? []
    }

    func saveAppActivityEvents(_ events: [AppActivityEvent]) {
        save(events, to: AppConstants.AnalyticsSettings.appActivityFile)
    }

    func appendAppActivityEvents(_ events: [AppActivityEvent]) {
        var existing = loadAppActivityEvents()
        existing.append(contentsOf: events)
        saveAppActivityEvents(existing)
    }

    // MARK: - Website Visits

    func loadWebsiteVisits() -> [WebsiteVisitRecord] {
        load(from: AppConstants.AnalyticsSettings.websiteVisitsFile) ?? []
    }

    func saveWebsiteVisits(_ records: [WebsiteVisitRecord]) {
        save(records, to: AppConstants.AnalyticsSettings.websiteVisitsFile)
    }

    func appendWebsiteVisits(_ records: [WebsiteVisitRecord]) {
        var existing = loadWebsiteVisits()
        existing.append(contentsOf: records)
        saveWebsiteVisits(existing)
    }

    // MARK: - Prune

    func pruneOldData() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -AppConstants.AnalyticsSettings.retentionDays, to: Date()) ?? Date()

        var sessions = loadFocusSessions()
        sessions.removeAll { $0.startedAt < cutoff }
        saveFocusSessions(sessions)

        var appEvents = loadAppActivityEvents()
        appEvents.removeAll { $0.startedAt < cutoff }
        saveAppActivityEvents(appEvents)

        var webVisits = loadWebsiteVisits()
        webVisits.removeAll { $0.startedAt < cutoff }
        saveWebsiteVisits(webVisits)
    }

    // MARK: - Generic Load/Save

    private func load<T: Decodable>(from filename: String) -> T? {
        let url = fileURL(for: filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[AnalyticsStore] Decode error for \(filename): \(error)")
            return nil
        }
    }

    private func save<T: Encodable>(_ value: T, to filename: String) {
        let url = fileURL(for: filename)
        do {
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[AnalyticsStore] Save error for \(filename): \(error)")
        }
    }
}
