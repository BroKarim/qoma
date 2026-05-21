import Foundation
import Combine
import AppKit

final class ActivityTracker: NSObject, ObservableObject {
    static let shared = ActivityTracker()

    @Published var isTracking = false
    @Published var currentSessionID: UUID?

    private var currentAppStartTime: Date?
    private var currentAppBundleID: String?
    private var currentAppName: String?
    private var pendingEvents: [AppActivityEvent] = []
    private var pendingWebsiteVisits: [WebsiteVisitRecord] = []

    private override init() {
        super.init()
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
        print("[ActivityTracker] 🟢 Started tracking session: \(sessionID)")
        captureCurrentApp()
    }

    func pauseTracking() {
        finalizeCurrentEvent()
        isTracking = false
        print("[ActivityTracker] ⏸ Paused tracking")
    }

    func resumeTracking(sessionID: UUID) {
        isTracking = true
        currentSessionID = sessionID
        print("[ActivityTracker] ▶️ Resumed tracking session: \(sessionID)")
        captureCurrentApp()
    }

    func stopTracking() -> ([AppActivityEvent], [WebsiteVisitRecord]) {
        finalizeCurrentEvent()
        isTracking = false
        let events = pendingEvents
        let visits = pendingWebsiteVisits
        
        print("[ActivityTracker] 🛑 Stopped tracking - Captured \(events.count) app events, \(visits.count) website visits")
        
        pendingEvents = []
        pendingWebsiteVisits = []
        currentSessionID = nil
        return (events, visits)
    }

    @objc private func appDidActivate(_ notification: Notification) {
        guard isTracking else { return }
        finalizeCurrentEvent()
        captureCurrentApp()
    }

    private func captureCurrentApp() {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            print("[ActivityTracker] ⚠️ Failed to get frontmost application")
            return
        }
        
        let bundleID = app.bundleIdentifier ?? app.localizedName ?? "unknown"
        let name = app.localizedName ?? "Unknown"
        
        currentAppBundleID = bundleID
        currentAppName = name
        currentAppStartTime = Date()
        
        print("[ActivityTracker] 📱 Captured app: \(name) (\(bundleID))")

        if let bundleID = app.bundleIdentifier {
            if let tabInfo = BrowserActivityResolver.shared.resolveCurrentTab(for: bundleID) {
                captureWebsiteVisit(
                    sessionID: currentSessionID,
                    bundleID: bundleID,
                    appName: name,
                    domain: tabInfo.domain,
                    title: tabInfo.title)
            }
        }
    }

    private func captureWebsiteVisit(
        sessionID: UUID?,
        bundleID: String,
        appName: String,
        domain: String,
        title: String?)
    {
        guard let sessionID = sessionID else { return }
        let visit = WebsiteVisitRecord(
            sessionID: sessionID,
            browserBundleID: bundleID,
            browserName: appName,
            domain: domain,
            pageTitle: title,
            startedAt: Date(),
            endedAt: nil,
            durationSeconds: 0
        )
        pendingWebsiteVisits.append(visit)
        print("[ActivityTracker] 🌐 Captured website: \(domain) from \(appName)")
    }

    private func finalizeCurrentEvent() {
        guard let sessionID = currentSessionID,
              let bundleID = currentAppBundleID,
              let name = currentAppName,
              let startTime = currentAppStartTime else { return }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)

        guard duration > 0 else { return }

        if let lastEventIndex = pendingEvents.indices.last,
           let lastEvent = pendingEvents[lastEventIndex].endedAt,
           pendingEvents[lastEventIndex].appBundleID == bundleID,
           lastEvent == startTime
        {
            var lastEvent = pendingEvents[lastEventIndex]
            lastEvent.endedAt = endTime
            lastEvent.durationSeconds = endTime.timeIntervalSince(lastEvent.startedAt)
            pendingEvents[lastEventIndex] = lastEvent
        } else {
            let event = AppActivityEvent(
                sessionID: sessionID,
                appBundleID: bundleID,
                appName: name,
                startedAt: startTime,
                endedAt: endTime,
                durationSeconds: duration
            )
            pendingEvents.append(event)
        }

        finalizeCurrentWebsiteVisit(endTime: endTime)

        currentAppStartTime = nil
        currentAppBundleID = nil
        currentAppName = nil
    }

    private func finalizeCurrentWebsiteVisit(endTime: Date) {
        guard let lastVisitIndex = pendingWebsiteVisits.indices.last,
              pendingWebsiteVisits[lastVisitIndex].endedAt == nil
        else { return }

        var visit = pendingWebsiteVisits[lastVisitIndex]
        let duration = endTime.timeIntervalSince(visit.startedAt)
        visit.endedAt = endTime
        visit.durationSeconds = duration
        pendingWebsiteVisits[lastVisitIndex] = visit
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil)
    }
}
