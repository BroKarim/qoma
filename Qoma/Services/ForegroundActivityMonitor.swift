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

    init(browserResolver: BrowserActivityResolver? = nil) {
        self.browserResolver = browserResolver ?? .shared
    }

    var isMonitoring: Bool { workspaceObserver != nil }

    func startMonitoring(policy: SessionPolicy) {
        stopMonitoring()
        self.policy = policy
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
            return
        }

        let domain: String? = resolveDomainIfNeeded(bundleID: bundleID)
        let activity = ForegroundActivity(
            bundleID: bundleID,
            appName: appName,
            domain: domain,
            browserBundleID: FocusPolicyEvaluator.isBrowserCapableOfDomainPolicy(bundleID) ? bundleID : nil
        )

        currentActivity = activity
        lastBundleID = bundleID
    }

    private func resolveDomainIfNeeded(bundleID: String) -> String? {
        guard let policy, Self.requiresDomainLookup(bundleID: bundleID, policy: policy) else { return nil }
        guard FocusPolicyEvaluator.isBrowserCapableOfDomainPolicy(bundleID) else { return nil }
        guard let tabInfo = browserResolver.resolveCurrentTab(for: bundleID) else { return nil }
        return FocusPolicyEvaluator.normalizeDomain(tabInfo.domain)
    }

    static func requiresDomainLookup(bundleID: String, policy: SessionPolicy) -> Bool {
        switch policy.mode {
        case .timerOnly: return false
        case .allowing: return !policy.allowedApps.contains(bundleID) && !policy.allowedDomains.isEmpty
        case .blocking: return !policy.blockedApps.contains(bundleID) && !policy.blockedDomains.isEmpty
        }
    }
}
