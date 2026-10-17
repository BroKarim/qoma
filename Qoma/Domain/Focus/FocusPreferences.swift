import Combine
import Foundation

@MainActor
final class FocusPreferences: ObservableObject {
    static let shared = FocusPreferences()

    private enum Key {
        static let policy = "qyube.focus.policy"
        static let browser = "qyube.focus.browser"
        static let hideTimer = "qyube.focus.hideFloatingTimer"
    }

    private let defaults: UserDefaults

    @Published var policy: SessionPolicy {
        didSet {
            if let data = try? JSONEncoder().encode(policy) {
                defaults.set(data, forKey: Key.policy)
            }
        }
    }

    @Published var browserBundleID: String {
        didSet { defaults.set(browserBundleID, forKey: Key.browser) }
    }

    @Published var hideFloatingTimer: Bool {
        didSet { defaults.set(hideFloatingTimer, forKey: Key.hideTimer) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Key.policy),
           let saved = try? JSONDecoder().decode(SessionPolicy.self, from: data) {
            policy = saved
        } else {
            policy = .timerOnly
        }
        browserBundleID = defaults.string(forKey: Key.browser) ?? "com.apple.Safari"
        hideFloatingTimer = defaults.bool(forKey: Key.hideTimer)
    }

    func draft(minutes: Int) -> SessionDraft {
        var appOnlyPolicy = policy
        appOnlyPolicy.allowedDomains = []
        appOnlyPolicy.blockedDomains = []
        return SessionDraft(
            plannedMinutes: min(60, max(1, minutes)),
            policy: appOnlyPolicy,
            domainBrowserBundleID: browserBundleID
        )
    }

    func updateApps(_ apps: Set<String>, for mode: FocusPolicyMode) {
        let apps = Set(apps.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        switch mode {
        case .allowing:
            policy.allowedApps = apps
        case .blocking:
            policy.blockedApps = apps
        case .timerOnly:
            break
        }
    }
}
