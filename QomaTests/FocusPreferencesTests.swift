import Foundation
import Testing
@testable import Qoma

@MainActor
struct FocusPreferencesTests {
    @Test
    func policyAndTimerPreferencePersistAndBecomeNewSessionSnapshot() {
        let suite = "qyube-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let preferences = FocusPreferences(defaults: defaults)
        #expect(preferences.policy == .timerOnly)
        preferences.policy.mode = .blocking
        preferences.policy.blockedApps.insert("com.example.Blocked")
        preferences.policy.blockedDomains.insert("example.com")
        preferences.browserBundleID = "com.google.Chrome"
        preferences.hideFloatingTimer = true
        let activeDraft = preferences.draft(minutes: 25)
        preferences.policy.mode = .allowing
        preferences.policy.allowedApps.insert("com.example.Allowed")

        let restored = FocusPreferences(defaults: defaults)
        let draft = restored.draft(minutes: 25)
        #expect(activeDraft.policy.mode == .blocking)
        #expect(draft.policy.mode == .allowing)
        #expect(draft.policy.blockedApps.contains("com.example.Blocked"))
        #expect(draft.policy.allowedApps.contains("com.example.Allowed"))
        #expect(draft.policy.allowedDomains.isEmpty)
        #expect(draft.policy.blockedDomains.isEmpty)
        #expect(draft.domainBrowserBundleID == "com.google.Chrome")
        #expect(restored.hideFloatingTimer)
        #expect(draft.plannedMinutes == 25)
    }
}
