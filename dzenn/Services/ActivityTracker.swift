import Foundation
import Combine
import AppKit
import OSLog

final class ActivityTracker: NSObject, ObservableObject {
    static let shared = ActivityTracker()

    @Published var isTracking = false
    @Published var currentSessionID: UUID?

    private let browserResolver: BrowserActivityResolver
    private let iconCache: IconCacheActor
    private var pollingTimer: Timer?
    private var workspaceObserver: NSObjectProtocol?
    private var currentAppSession: AppActivityEvent?
    private var currentWebsiteSession: WebsiteVisitRecord?
    private var pendingEvents: [AppActivityEvent] = []
    private var pendingWebsiteVisits: [WebsiteVisitRecord] = []
    private var lastActivityTime: Date?
    private var activeWebsitePollTasks = 0
    private var websitePollGeneration = 0
    private var websiteGraceTimer: Timer?

    init(browserResolver: BrowserActivityResolver = .shared, iconCache: IconCacheActor = .init()) {
        self.browserResolver = browserResolver
        self.iconCache = iconCache
        super.init()
    }

    func startTracking(sessionID: UUID) {
        isTracking = true
        currentSessionID = sessionID
        pendingEvents = []
        pendingWebsiteVisits = []
        lastActivityTime = Date()

        Logger.tracking.info("Started tracking session: \(sessionID, privacy: .public)")

        installWorkspaceObserver()
        startPolling()
        tick()
    }

    func pauseTracking() {
        uninstallWorkspaceObserver()
        stopPolling()
        finalizeCurrentAppSession()
        finalizeCurrentWebsiteSession()
        isTracking = false
        Logger.tracking.info("Paused tracking")
    }

    func resumeTracking(sessionID: UUID) {
        isTracking = true
        currentSessionID = sessionID
        lastActivityTime = Date()

        Logger.tracking.info("Resumed tracking session: \(sessionID, privacy: .public)")

        installWorkspaceObserver()
        startPolling()
        tick()
    }

    func stopTracking() -> ([AppActivityEvent], [WebsiteVisitRecord]) {
        uninstallWorkspaceObserver()
        stopPolling()
        finalizeCurrentAppSession()
        finalizeCurrentWebsiteSession()
        isTracking = false

        let events = pendingEvents
        let visits = pendingWebsiteVisits

        Logger.tracking.info("Stopped tracking — Captured \(events.count) app events, \(visits.count) website visits")

        pendingEvents = []
        pendingWebsiteVisits = []
        currentSessionID = nil
        currentAppSession = nil
        currentWebsiteSession = nil
        return (events, visits)
    }

    // MARK: - Workspace Notification (Hybrid Polling)

    private func installWorkspaceObserver() {
        uninstallWorkspaceObserver()
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func uninstallWorkspaceObserver() {
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            workspaceObserver = nil
        }
    }

    // MARK: - Polling

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

    // MARK: - Tick

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

        if WindowDetectionService.shared.isFloatingWindow(app: frontmostApp) {
            return
        }

        lastActivityTime = Date()
        cacheIcon(for: bundleId)
        updateAppSession(identifier: bundleId, name: name)
        scheduleWebsitePoll(bundleId: bundleId, appName: name)
    }

    // MARK: - App Session

    private func cacheIcon(for bundleId: String) {
        Task {
            guard await iconCache.get(bundleId) == nil else { return }
            if let iconData = IconUtils.getAppIconAsPNG(for: bundleId) {
                await iconCache.set(bundleId, value: iconData)
            }
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
        Logger.tracking.info("Started app session: \(name, privacy: .public)")
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

    // MARK: - Website Session (Generation Tracking + Grace Period)

    private func scheduleWebsitePoll(bundleId: String, appName: String) {
        guard browserResolver.isBrowserSupported(bundleId) else {
            return
        }

        guard activeWebsitePollTasks < AppConstants.AnalyticsSettings.websitePollMaxConcurrent else {
            return
        }

        websitePollGeneration += 1
        let currentGeneration = websitePollGeneration
        activeWebsitePollTasks += 1

        Task {
            defer { activeWebsitePollTasks -= 1 }

            // Abort if a newer poll has started
            guard currentGeneration == self.websitePollGeneration else {
                Logger.browser.debug("Skipped stale website poll (gen \(currentGeneration) != \(self.websitePollGeneration))")
                return
            }

            if let tabInfo = browserResolver.resolveCurrentTab(for: bundleId) {
                guard currentGeneration == self.websitePollGeneration else { return }
                self.cancelWebsiteGracePeriod()
                self.updateWebsiteSession(
                    bundleId: bundleId,
                    appName: appName,
                    domain: tabInfo.domain,
                    title: tabInfo.title
                )
            } else {
                guard currentGeneration == self.websitePollGeneration else { return }
                self.beginWebsiteGracePeriod()
            }
        }
    }

    private func beginWebsiteGracePeriod() {
        guard websiteGraceTimer == nil, currentWebsiteSession != nil else { return }
        websiteGraceTimer = Timer.scheduledTimer(
            withTimeInterval: AppConstants.AnalyticsSettings.websitePollGracePeriod,
            repeats: false
        ) { [weak self] _ in
            self?.finalizeCurrentWebsiteSession()
        }
        Logger.tracking.debug("Website grace period started (\(AppConstants.AnalyticsSettings.websitePollGracePeriod)s)")
    }

    private func cancelWebsiteGracePeriod() {
        websiteGraceTimer?.invalidate()
        websiteGraceTimer = nil
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
        Logger.tracking.info("Started website session: \(domain, privacy: .public)")
    }

    private func finalizeCurrentWebsiteSession() {
        guard var visit = currentWebsiteSession else { return }

        cancelWebsiteGracePeriod()

        let endTime = Date()
        visit.endedAt = endTime
        visit.durationSeconds = endTime.timeIntervalSince(visit.startedAt)

        if visit.durationSeconds > 0 {
            pendingWebsiteVisits.append(visit)
        }

        currentWebsiteSession = nil
        Logger.tracking.debug("Finalized website session for \(visit.domain, privacy: .public)")
    }

    deinit {
        pollingTimer?.invalidate()
        websiteGraceTimer?.invalidate()
        uninstallWorkspaceObserver()
    }
}
