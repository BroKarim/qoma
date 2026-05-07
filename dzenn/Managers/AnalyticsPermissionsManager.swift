import Foundation
import Combine
import AppKit

final class AnalyticsPermissionsManager: ObservableObject {
    @Published var canTrackApps = false
    @Published var canTrackBrowserMetadata = false

    init() {
        refreshStatus()
    }

    func refreshStatus() {
        let status = AXIsProcessTrusted()
        canTrackApps = status
        canTrackBrowserMetadata = status
    }

    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
