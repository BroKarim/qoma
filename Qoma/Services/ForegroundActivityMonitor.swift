import Foundation
import AppKit
import Combine
import OSLog

/// Emits foreground activity observations without gating on analytics settings.
/// Separated from `ActivityTracker` so policy reactions are independent of analytics collection.
@MainActor
final class ForegroundActivityMonitor: ObservableObject {
    @Published private(set) var currentActivity: ForegroundActivity?

    private let browserResolver: BrowserActivityResolver
    private var workspaceObserver: NSObjectProtocol?
    private var pollingTimer: Timer?
    private var lastBundleID: String?
    private var policy: SessionPolicy?
    private var selectedDomainBrowserID = "com.apple.Safari"
    private let lookupQueue = DispatchQueue(label: "com.dzulkiram.qoma.domain-lookup")
    private var lookupInFlight = false
    private var lastLookupAt = Date.distantPast
    private var activityGeneration = 0

    init(browserResolver: BrowserActivityResolver? = nil) {
        self.browserResolver = browserResolver ?? .shared
    }

    var isMonitoring: Bool { workspaceObserver != nil }

    func startMonitoring(policy: SessionPolicy, selectedDomainBrowserID: String = "com.apple.Safari") {
        stopMonitoring()
        self.policy = policy
        self.selectedDomainBrowserID = selectedDomainBrowserID
        lastLookupAt = .distantPast
        installWorkspaceObserver()
        startPolling()
        tick()
    }

    func stopMonitoring() {
        uninstallWorkspaceObserver()
        stopPolling()
        currentActivity = nil
        lastBundleID = nil
        policy = nil
        activityGeneration += 1
        lookupInFlight = false
    }

    // MARK: - Workspace

    private func installWorkspaceObserver() {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
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
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - Tick

    private func tick() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let bundleID = frontmostApp.bundleIdentifier,
              let appName = frontmostApp.localizedName else {
            currentActivity = nil
            lastBundleID = nil
            activityGeneration += 1
            return
        }

        let previousBundleID = lastBundleID
        activityGeneration += previousBundleID == bundleID ? 0 : 1
        let generation = activityGeneration
        let domain = currentActivity?.bundleID == bundleID ? currentActivity?.domain : nil
        let activity = ForegroundActivity(
            bundleID: bundleID,
            appName: appName,
            domain: domain,
            browserBundleID: FocusPolicyEvaluator.isBrowserCapableOfDomainPolicy(bundleID) ? bundleID : nil
        )

        currentActivity = activity
        lastBundleID = bundleID
        guard PermissionManager.shared.canReadDomains(for: policy ?? .timerOnly, browserBundleID: selectedDomainBrowserID) else { return }
        guard let policy, Self.requiresDomainLookup(bundleID: bundleID, policy: policy),
              bundleID == selectedDomainBrowserID,
              FocusPolicyEvaluator.isBrowserCapableOfDomainPolicy(bundleID),
              !lookupInFlight, Date().timeIntervalSince(lastLookupAt) >= 1 else { return }
        lookupInFlight = true
        lastLookupAt = Date()
        lookupQueue.async { [weak self] in
            let domain = self?.browserResolver.resolveCurrentTab(for: bundleID).map {
                FocusPolicyEvaluator.normalizeDomain($0.domain)
            }
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.lookupInFlight = false
                    guard self.activityGeneration == generation,
                          self.lastBundleID == bundleID,
                          let current = self.currentActivity else { return }
                    self.currentActivity = ForegroundActivity(
                        bundleID: current.bundleID,
                        appName: current.appName,
                        domain: domain,
                        browserBundleID: current.browserBundleID
                    )
                }
            }
        }
    }

    static func requiresDomainLookup(bundleID: String, policy: SessionPolicy) -> Bool {
        switch policy.mode {
        case .timerOnly: return false
        case .allowing: return !policy.allowedApps.contains(bundleID) && !policy.allowedDomains.isEmpty
        case .blocking: return !policy.blockedApps.contains(bundleID) && !policy.blockedDomains.isEmpty
        }
    }
}
