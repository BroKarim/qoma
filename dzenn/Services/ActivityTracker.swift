import Foundation
import Combine
import AppKit

final class ActivityTracker: ObservableObject {
    static let shared = ActivityTracker()

    @Published var isTracking = false
    @Published var currentSessionID: UUID?

    private var currentAppStartTime: Date?
    private var currentAppBundleID: String?
    private var currentAppName: String?
    private var pendingEvents: [AppActivityEvent] = []

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidActivate),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    func startTracking(sessionID: UUID) {
        isTracking = true
        currentSessionID = sessionID
        pendingEvents = []
        captureCurrentApp()
    }

    func pauseTracking() {
        finalizeCurrentEvent()
        isTracking = false
    }

    func resumeTracking(sessionID: UUID) {
        isTracking = true
        currentSessionID = sessionID
        captureCurrentApp()
    }

    func stopTracking() -> [AppActivityEvent] {
        finalizeCurrentEvent()
        isTracking = false
        let events = pendingEvents
        pendingEvents = []
        currentSessionID = nil
        return events
    }

    @objc private func appDidActivate() {
        guard isTracking else { return }
        finalizeCurrentEvent()
        captureCurrentApp()
    }

    private func captureCurrentApp() {
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        currentAppBundleID = app.bundleIdentifier ?? app.localizedName ?? "unknown"
        currentAppName = app.localizedName ?? "Unknown"
        currentAppStartTime = Date()
    }

    private func finalizeCurrentEvent() {
        guard let sessionID = currentSessionID,
              let bundleID = currentAppBundleID,
              let name = currentAppName,
              let startTime = currentAppStartTime else { return }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        guard duration > 0 else { return }

        let event = AppActivityEvent(
            sessionID: sessionID,
            appBundleID: bundleID,
            appName: name,
            startedAt: startTime,
            endedAt: endTime,
            durationSeconds: duration
        )
        pendingEvents.append(event)

        currentAppStartTime = nil
        currentAppBundleID = nil
        currentAppName = nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }
}
