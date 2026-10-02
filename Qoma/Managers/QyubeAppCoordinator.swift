import Cocoa
import Combine
import SwiftUI

/// Owns the qyube runtime: home window, session coordinator, timer panel, companion panel, and menu bar status.
@MainActor
final class QyubeAppCoordinator {
    let sessionCoordinator: SessionCoordinator
    private let timerController = FloatingTimerController()
    private let companionController = CompanionWindowController()
    private let menuBarController: MenuBarController
    private var cancellables = Set<AnyCancellable>()

    init(sessionCoordinator: SessionCoordinator? = nil) {
        self.sessionCoordinator = sessionCoordinator ?? SessionCoordinator()
        self.menuBarController = MenuBarController()

        self.menuBarController.configure { [weak self] in
            self?.handleStatusClick()
        }

        configurePanels()
        bindSessionCoordinator()
    }

    func showHomeWindow() {
        if let existing = homeWindowController?.window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = QyubeHomeView(sessionCoordinator: sessionCoordinator)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "qyube"
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.homeWindowController = NSWindowController(window: window)
    }

    func restoreTimerPanel() {
        guard let snapshot = sessionCoordinator.snapshot else { return }
        timerController.show(remainingTime: sessionCoordinator.remainingTime, taskTitle: snapshot.draft.displayTitle)
    }

    // MARK: - Private

    private var homeWindowController: NSWindowController?

    private func configurePanels() {
        timerController.configure(actions: FloatingTimerActions(
            onClose: { [weak self] in self?.timerController.hide() },
            onPause: { [weak self] in self?.sessionCoordinator.pauseSession() },
            onResume: { [weak self] in self?.sessionCoordinator.resumeSession() },
            onStop: { [weak self] in self?.sessionCoordinator.stopSession() }
        ))

        companionController.configure(onTap: { [weak self] in
            self?.restoreTimerPanel()
        })
    }

    private func bindSessionCoordinator() {
        sessionCoordinator.$snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.handleSnapshotChange(snapshot)
            }
            .store(in: &cancellables)

        sessionCoordinator.$remainingTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTimerPanel()
                self?.updateStatusItem()
            }
            .store(in: &cancellables)
    }

    private func handleSnapshotChange(_ snapshot: ActiveSessionSnapshot?) {
        if let snapshot {
            if snapshot.status == .active || snapshot.status == .paused {
                timerController.show(remainingTime: sessionCoordinator.remainingTime, taskTitle: snapshot.draft.displayTitle)
                companionController.show()
            } else {
                timerController.hide()
                companionController.hide()
            }
        } else {
            timerController.hide()
            companionController.hide()
        }
        updateStatusItem()
    }

    private func updateTimerPanel() {
        guard sessionCoordinator.snapshot != nil else { return }
        timerController.update(remainingTime: sessionCoordinator.remainingTime, taskTitle: sessionCoordinator.currentTaskTitle)
    }

    private func updateStatusItem() {
        let title: String
        if let snapshot = sessionCoordinator.snapshot, snapshot.status == .active || snapshot.status == .paused {
            title = formatTime(sessionCoordinator.remainingTime)
        } else {
            title = ""
        }
        menuBarController.updateTitle(title)
    }

    private func handleStatusClick() {
        if sessionCoordinator.snapshot != nil {
            restoreTimerPanel()
        } else {
            showHomeWindow()
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
