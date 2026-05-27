import Foundation
import Combine
import AppKit

final class ActivityTracker: NSObject, ObservableObject {
    static let shared = ActivityTracker()

    @Published var isTracking = false
    @Published var currentSessionID: UUID?

    private var pollingTimer: Timer?
    private var currentAppSession: AppActivityEvent?
    private var currentWebsiteSession: WebsiteVisitRecord?
    private var pendingEvents: [AppActivityEvent] = []
    private var pendingWebsiteVisits: [WebsiteVisitRecord] = []
    private var lastActivityTime: Date?
    private var activeWebsitePollTasks = 0
    private var appIconCache: [String: Data] = [:]

    private override init() {
        super.init()
    }

    func startTracking(sessionID: UUID) {
        isTracking = true
        currentSessionID = sessionID
        pendingEvents = []
        pendingWebsiteVisits = []
        lastActivityTime = Date()

        print("[ActivityTracker] Started tracking session: \(sessionID)")

        startPolling()
        tick()
    }

    func pauseTracking() {
        stopPolling()
        finalizeCurrentAppSession()
        finalizeCurrentWebsiteSession()
        isTracking = false
        print("[ActivityTracker] Paused tracking")
    }

    func resumeTracking(sessionID: UUID) {
        isTracking = true
        currentSessionID = sessionID
        lastActivityTime = Date()

        print("[ActivityTracker] Resumed tracking session: \(sessionID)")

        startPolling()
        tick()
    }

    func stopTracking() -> ([AppActivityEvent], [WebsiteVisitRecord]) {
        stopPolling()
        finalizeCurrentAppSession()
        finalizeCurrentWebsiteSession()
        isTracking = false

        let events = pendingEvents
        let visits = pendingWebsiteVisits

        print("""
            [ActivityTracker] Stopped tracking - Captured \
            \(events.count) app events, \(visits.count) website visits
            """)

        pendingEvents = []
        pendingWebsiteVisits = []
        currentSessionID = nil
        currentAppSession = nil
        currentWebsiteSession = nil
        return (events, visits)
    }

    private func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(
            withTimeInterval: AppConstants.AnalyticsSettings.pollingInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func tick() {
        guard isTracking else { return }

        let idleTime = getSystemIdleTime()
        if idleTime >= AppConstants.AnalyticsSettings.idleThreshold {
            finalizeCurrentAppSession()
            finalizeCurrentWebsiteSession()
            lastActivityTime = Date()
            return
        }

        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontmostApp.bundleIdentifier,
              let name = frontmostApp.localizedName else {
            return
        }

        guard !AppConstants.AnalyticsSettings.excludedBundleIds.contains(bundleId) else {
            return
        }

        lastActivityTime = Date()
        cacheIcon(for: bundleId)
        updateAppSession(identifier: bundleId, name: name)
        scheduleWebsitePoll(bundleId: bundleId, appName: name)
    }

    private func cacheIcon(for bundleId: String) {
        guard appIconCache[bundleId] == nil else { return }
        if let iconData = IconUtils.getAppIconAsPNG(for: bundleId) {
            appIconCache[bundleId] = iconData
        }
    }

    private func getSystemIdleTime() -> TimeInterval {
        let idleTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .mouseMoved
        )
        return TimeInterval(idleTime)
    }

    private func updateAppSession(identifier: String, name: String) {
        if let current = currentAppSession {
            if current.appBundleID != identifier {
                finalizeCurrentAppSession()
                startNewAppSession(identifier: identifier, name: name)
            }
        } else {
            startNewAppSession(identifier: identifier, name: name)
        }
    }

    private func startNewAppSession(identifier: String, name: String) {
        guard let sessionID = currentSessionID else { return }

        let event = AppActivityEvent(
            sessionID: sessionID,
            appBundleID: identifier,
            appName: name,
            startedAt: Date(),
            endedAt: nil,
            durationSeconds: 0
        )
        currentAppSession = event
        print("[ActivityTracker] Started app session: \(name)")
    }

    private func finalizeCurrentAppSession() {
        guard var event = currentAppSession else { return }

        let endTime = Date()
        event.endedAt = endTime
        event.durationSeconds = endTime.timeIntervalSince(event.startedAt)

        if event.durationSeconds > 0 {
            pendingEvents.append(event)
        }

        currentAppSession = nil
    }

    private func scheduleWebsitePoll(bundleId: String, appName: String) {
        guard BrowserActivityResolver.shared.isBrowserSupported(bundleId) else {
            return
        }

        guard activeWebsitePollTasks < AppConstants.AnalyticsSettings.websitePollMaxConcurrent else {
            return
        }

        activeWebsitePollTasks += 1

        Task {
            defer { activeWebsitePollTasks -= 1 }

            if let tabInfo = BrowserActivityResolver.shared.resolveCurrentTab(for: bundleId) {
                updateWebsiteSession(
                    bundleId: bundleId,
                    appName: appName,
                    domain: tabInfo.domain,
                    title: tabInfo.title
                )
            } else {
                finalizeCurrentWebsiteSession()
            }
        }
    }

    private func updateWebsiteSession(
        bundleId: String,
        appName: String,
        domain: String,
        title: String?
    ) {
        if let current = currentWebsiteSession {
            if current.domain != domain {
                finalizeCurrentWebsiteSession()
                startNewWebsiteSession(
                    bundleId: bundleId,
                    appName: appName,
                    domain: domain,
                    title: title
                )
            }
        } else {
            startNewWebsiteSession(
                bundleId: bundleId,
                appName: appName,
                domain: domain,
                title: title
            )
        }
    }

    private func startNewWebsiteSession(
        bundleId: String,
        appName: String,
        domain: String,
        title: String?
    ) {
        guard let sessionID = currentSessionID else { return }

        let visit = WebsiteVisitRecord(
            sessionID: sessionID,
            browserBundleID: bundleId,
            browserName: appName,
            domain: domain,
            pageTitle: title,
            startedAt: Date(),
            endedAt: nil,
            durationSeconds: 0
        )
        currentWebsiteSession = visit
        print("[ActivityTracker] Started website session: \(domain)")
    }

    private func finalizeCurrentWebsiteSession() {
        guard var visit = currentWebsiteSession else { return }

        let endTime = Date()
        visit.endedAt = endTime
        visit.durationSeconds = endTime.timeIntervalSince(visit.startedAt)

        if visit.durationSeconds > 0 {
            pendingWebsiteVisits.append(visit)
        }

        currentWebsiteSession = nil
    }

    deinit {
        pollingTimer?.invalidate()
    }
}
