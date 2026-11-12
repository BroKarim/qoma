import Testing
import Foundation
@testable import Qoma

struct MenuBarRoutingTests {
    @MainActor @Test func hiddenTimerStatusClickOpensSessionPanel() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = FocusPreferences(defaults: defaults)
        preferences.hideFloatingTimer = true
        let coordinator = SessionCoordinator(
            accountID: "menu-test",
            sessionRepository: SessionRepository(storageDirectory: directory.appendingPathComponent("sessions")),
            catchRepository: CatchRepository(storageDirectory: directory.appendingPathComponent("catches")),
            autoCatchEnabled: false)
        #expect(coordinator.startSession(draft: SessionDraft()) != nil)
        let menu = MenuBarController()
        menu.configure(coordinator: coordinator, preferences: preferences, onOpen: {},
                       onEditActiveSession: {}, onSettings: {})
        menu.clickStatusItem()
        #expect(menu.isSessionPanelVisible)
        menu.clickStatusItem()
        #expect(!menu.isSessionPanelVisible)
    }

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
