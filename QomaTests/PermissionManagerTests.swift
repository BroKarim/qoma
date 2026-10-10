import Testing
@testable import Qoma

@MainActor
struct PermissionManagerTests {
    @Test
    func timerOnlyDoesNotMarkBrowserAutomationAsGranted() async {
        let manager = PermissionManager()
        let result = await manager.requestPermissionIfNeeded(
            for: .timerOnly,
            browserBundleID: "com.apple.Safari"
        )
        #expect(result == .granted)
        #expect(manager.automationStatus == .notDetermined)
    }
}
