import Foundation
import Combine
import AppKit
import OSLog

/// Status of macOS system permissions required for app functionality.
/// Used to track automation permissions needed for browser integration.
enum PermissionStatus {
    /// Permission has been granted by the user
    case granted
    /// Permission has been explicitly denied by the user
    case denied
    /// Permission status has not yet been determined
    case notDetermined
}

/// Manages macOS system permissions required for browser automation and website tracking.
/// Monitors AppleScript automation permissions and provides UI feedback for permission states.
/// Coordinates with BrowserActivityResolver to handle browser communication errors.
final class AnalyticsPermissionsManager: ObservableObject {
    static let shared = AnalyticsPermissionsManager()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.dzulkiram.qoma",
        category: "PermissionManager"
    )

    /// Current status of automation permissions for browser AppleScript access
    @Published var automationPermissionStatus: PermissionStatus = .notDetermined
    /// Current status of System Events automation permissions used by Firefox URL tracking.
    @Published var systemEventsPermissionStatus: PermissionStatus = .notDetermined
    /// Current status of Accessibility permissions used by Firefox URL tracking.
    @Published var accessibilityPermissionStatus: PermissionStatus = .notDetermined
    /// Most recent error message from browser communication attempts
    @Published var lastError: String?

    private init() {
        // Don't check permissions on init — let background tracking handle it
    }

    /// Updates permission status based on browser AppleScript execution results.
    /// Called by WebTrackingService when AppleScript operations succeed or fail.
    /// - Parameter success: Whether the AppleScript operation was successful
    func handleBrowserPermissionResult(success: Bool, browserName: String? = nil) {
        Task { @MainActor in
            if success {
                self.automationPermissionStatus = .granted
                self.lastError = nil
            } else {
                self.automationPermissionStatus = .denied
                let browser = browserName ?? "browser"
                self.lastError = "Automation permission needed for \(browser)"
                self.logger.error("Browser permission failed for \(browser, privacy: .public)")
            }
        }
    }

    /// Updates System Events permission status based on AppleScript execution results.
    /// Called when System Events operations succeed or fail.
    /// - Parameter success: Whether the System Events AppleScript operation was successful
    func handleSystemEventsPermissionResult(success: Bool) {
        Task { @MainActor in
            if success {
                self.systemEventsPermissionStatus = .granted
            } else {
                self.systemEventsPermissionStatus = .denied
                self.logger.error("System Events permission denied")
            }
        }
    }

    /// Updates Accessibility permission status based on AppleScript execution results.
    /// Called when Accessibility operations succeed or fail.
    /// - Parameter success: Whether the Accessibility operation was successful
    func handleAccessibilityPermissionResult(success: Bool) {
        Task { @MainActor in
            if success {
                self.accessibilityPermissionStatus = .granted
            } else {
                self.accessibilityPermissionStatus = .denied
                self.logger.error("Accessibility permission denied")
            }
        }
    }

    /// Records browser communication errors for UI display.
    /// - Parameter errorMessage: Description of the browser communication error
    func handleBrowserError(_ errorMessage: String) {
        Task { @MainActor in
            self.lastError = errorMessage
        }
    }
}
