import Testing
@testable import Qoma

struct MenuBarRoutingTests {
    @MainActor @Test func onlyHiddenTimerOrSaveStateUsesPopover() {
        #expect(!MenuBarController.shouldShowPopover(
            isRunning: false, timerHidden: true, finalization: .idle))
        #expect(!MenuBarController.shouldShowPopover(
            isRunning: true, timerHidden: false, finalization: .idle))
        #expect(MenuBarController.shouldShowPopover(
            isRunning: true, timerHidden: true, finalization: .idle))
        #expect(MenuBarController.shouldShowPopover(
            isRunning: false, timerHidden: false, finalization: .failed("Save failed")))
    }
}
