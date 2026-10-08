import Foundation
import AppKit
import Combine
import OSLog

/// Manages monitoring permissions contextually, never at launch.
/// For the new qyube flow, NSWorkspace app foreground requires no permission,
/// but Chrome/Safari domain lookup needs Automation (AppleEvents) permission.
@MainActor
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published private(set) var automationStatus: MonitoringPermissionStatus = .notDetermined

    /// Whether the chosen policy needs any permission beyond what is already granted.
    func permissionRequirement(for policy: SessionPolicy) -> AppMonitoringCapability {
        switch policy.mode {
        case .timerOnly:
            return .available
        case .allowing, .blocking:
            return needsDomainMonitoring(policy) ? .needsPermission : .available
        }
    }

    func permissionRequirement(
        for policy: SessionPolicy,
        browserBundleID: String
    ) -> AppMonitoringCapability {
        guard needsDomainMonitoring(policy) else { return .available }
        return FocusPolicyEvaluator.isBrowserCapableOfDomainPolicy(browserBundleID) ? .needsPermission : .unsupported
    }

    func requestPermissionIfNeeded(
        for policy: SessionPolicy,
        browserBundleID: String
    ) async -> MonitoringPermissionStatus {
        if permissionRequirement(for: policy, browserBundleID: browserBundleID) == .available {
            automationStatus = .granted
            return automationStatus
        }
        guard permissionRequirement(for: policy, browserBundleID: browserBundleID) == .needsPermission else {
            automationStatus = .restricted
            return automationStatus
        }
        let browserName = browserBundleID == "com.apple.Safari" ? "Safari" : "Google Chrome"
        let source = "with timeout of 10 seconds\ntell application \"\(browserName)\" to get name\nend timeout"
        let result = await Task.detached(priority: .userInitiated) {
            guard let script = NSAppleScript(source: source) else { return false }
            var error: NSDictionary?
            _ = script.executeAndReturnError(&error)
            return error == nil
        }.value
        automationStatus = result ? .granted : .denied
        return automationStatus
    }

    func canReadDomains(for policy: SessionPolicy, browserBundleID: String) -> Bool {
        permissionRequirement(for: policy, browserBundleID: browserBundleID) == .available
            || automationStatus == .granted
    }

    private func needsDomainMonitoring(_ policy: SessionPolicy) -> Bool {
        !policy.allowedDomains.isEmpty || !policy.blockedDomains.isEmpty
    }

    /// Request Automation permission if the policy requires browser domain lookup.
    /// Does nothing for Timer Only or app-only policies.
    func requestPermissionIfNeeded(for policy: SessionPolicy) async -> MonitoringPermissionStatus {
        guard needsDomainMonitoring(policy) else { return .granted }
        automationStatus = .restricted
        return automationStatus
    }

    func markPermissionUnavailable() {
        automationStatus = .denied
    }
}
