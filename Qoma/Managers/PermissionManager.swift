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

    private func needsDomainMonitoring(_ policy: SessionPolicy) -> Bool {
        !policy.allowedDomains.isEmpty || !policy.blockedDomains.isEmpty
    }

    /// Request Automation permission if the policy requires browser domain lookup.
    /// Does nothing for Timer Only or app-only policies.
    func requestPermissionIfNeeded(for policy: SessionPolicy) async -> MonitoringPermissionStatus {
        guard permissionRequirement(for: policy) == .needsPermission else {
            return .granted
        }

        // macOS has no direct API to request Automation permission ahead of use.
        // In production, perform a harmless AppleScript targeting Safari/Chrome here,
        // which triggers the system prompt and sets the status.
        // For now, mark as granted so development can continue; gate this behind
        // an actual prompt before shipping.
        automationStatus = .granted
        return automationStatus
    }

    func markPermissionUnavailable() {
        automationStatus = .denied
    }
}
