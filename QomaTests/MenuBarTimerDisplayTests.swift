import Foundation
import Testing
@testable import Qoma

@MainActor
struct MenuBarTimerDisplayTests {
    @Test func idleShowsLatestSelectionAndActiveCountdownTakesPriority() {
        let suite = "menubar-timer-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(MenuBarController.displayTitle(sessionTitle: "", defaults: defaults) == "25:00")
        defaults.set(35, forKey: AppConstants.MenuBarSettings.selectedPresetMinutesKey)
        #expect(MenuBarController.displayTitle(sessionTitle: "", defaults: defaults) == "35:00")
        defaults.set(10, forKey: AppConstants.MenuBarSettings.selectedPresetMinutesKey)
        defaults.set(true, forKey: AppConstants.MenuBarSettings.compactIconKey)
        #expect(MenuBarController.displayTitle(sessionTitle: "", defaults: defaults) == "10:00")
        #expect(MenuBarController.displayTitle(sessionTitle: "04:32", defaults: defaults) == "04:32")
        defaults.set(0, forKey: AppConstants.MenuBarSettings.selectedPresetMinutesKey)
        #expect(MenuBarController.displayTitle(sessionTitle: "", defaults: defaults) == "01:00")
        defaults.set(120, forKey: AppConstants.MenuBarSettings.selectedPresetMinutesKey)
        #expect(MenuBarController.displayTitle(sessionTitle: "", defaults: defaults) == "60:00")
    }
}
