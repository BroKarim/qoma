import Foundation
import OSLog

/// One-time, idempotent import of analytics-era sessions into the qyube history.
enum LegacySessionMigrator {
    private static let markerKey = "legacyFocusSessionsMigrated.v1"

    static func migrateIfNeeded(
        accountID: String = "local",
        analyticsStore: AnalyticsStore = .shared,
        sessionRepository: SessionRepository = .shared,
        defaults: UserDefaults = .standard
    ) {
        guard !defaults.bool(forKey: markerKey) else { return }
        do {
            guard let records = try analyticsStore.readFocusSessionsForMigration() else { return }
            let sessions = records.compactMap { record -> FocusSession? in
                guard let endedAt = record.endedAt else { return nil }
                let draft = SessionDraft(
                    taskTitle: record.taskTitle ?? "",
                    plannedMinutes: record.plannedMinutes,
                    policy: .timerOnly
                )
                return FocusSession(
                    id: record.id,
                    accountID: accountID,
                    startedAt: record.startedAt,
                    endedAt: endedAt,
                    plannedMinutes: record.plannedMinutes,
                    actualActiveSeconds: min(record.actualFocusSeconds, TimeInterval(record.plannedMinutes * 60)),
                    status: record.completed ? .completed : .interrupted,
                    draftSnapshot: draft,
                    taskTitle: draft.displayTitle,
                    interruptedReason: record.interruptedReason ?? (record.completed ? nil : "Legacy session")
                )
            }
            guard sessionRepository.importHistory(sessions) else { return }
            defaults.set(true, forKey: markerKey)
            Logger.store.info("Migrated \(sessions.count) legacy focus sessions")
        } catch {
            Logger.store.error("Legacy session migration failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
