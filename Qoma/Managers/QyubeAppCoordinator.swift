import Cocoa
import Combine
import SwiftUI

/// Owns the qyube runtime: home window, session coordinator, timer panel, companion panel, overlay, and menu bar status.
@MainActor
final class QyubeAppCoordinator {
    let sessionCoordinator: SessionCoordinator
    private let timerController = FloatingTimerController()
    private let companionController = CompanionWindowController()
    private let overlayController = DistractionOverlayController()
    private let distractionCoordinator: DistractionCoordinator
    private let menuBarController: MenuBarController
    private var cancellables = Set<AnyCancellable>()
    private var reportWindowController: NSWindowController?

    init(sessionCoordinator: SessionCoordinator? = nil) {
        self.sessionCoordinator = sessionCoordinator ?? SessionCoordinator()
        self.distractionCoordinator = DistractionCoordinator(monitor: ForegroundActivityMonitor())
        self.menuBarController = MenuBarController()

        self.menuBarController.configure { [weak self] in
            self?.handleStatusClick()
        }

        configurePanels()
        bindSessionCoordinator()
        bindDistractionCoordinator()
    }

    func showHomeWindow() {
        if let existing = homeWindowController?.window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        dismissReportWindow()
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
            onStop: { [weak self] in self?.sessionCoordinator.stopSession() },
            onTaskChange: { [weak self] title in self?.sessionCoordinator.updateTask(title: title) }
        ))

        companionController.configure(onTap: { [weak self] in
            self?.restoreTimerPanel()
        })

        sessionCoordinator.onSessionEnded = { [weak self] session in
            self?.onSessionEnded(session)
        }
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

    private func bindDistractionCoordinator() {
        distractionCoordinator.$isDistractionActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] active in
                guard let self else { return }
                self.sessionCoordinator.setDistractionActive(active)
                if active, let decision = self.distractionCoordinator.currentDecision {
                    self.overlayController.show(decision: decision)
                } else {
                    self.overlayController.hide()
                }
            }
            .store(in: &cancellables)
    }

    private func handleSnapshotChange(_ snapshot: ActiveSessionSnapshot?) {
        if let snapshot {
            if snapshot.status == .active || snapshot.status == .paused {
                timerController.show(remainingTime: sessionCoordinator.remainingTime, taskTitle: snapshot.draft.displayTitle)
                companionController.show()
                distractionCoordinator.start(policy: snapshot.draft.policy)
            } else {
                timerController.hide()
                companionController.hide()
                distractionCoordinator.stop()
                overlayController.hide()
            }
        } else {
            timerController.hide()
            companionController.hide()
            distractionCoordinator.stop()
            overlayController.hide()
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

    private func onSessionEnded(_ session: FocusSession) {
        showReportWindow(for: session)
    }

    private func showReportWindow(for session: FocusSession) {
        dismissReportWindow()

        let catches = CatchRepository.shared.listBanked(accountID: session.accountID)
            .filter { $0.sessionID == session.id }
        let contentView = FishingReportView(
            session: session,
            catches: catches,
            onStartAgain: { [weak self] in
                self?.dismissReportWindow()
                self?.showHomeWindow()
            },
            onGoHome: { [weak self] in
                self?.dismissReportWindow()
                self?.showHomeWindow()
            }
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = session.status == .completed ? "Fishing Report" : "Session Ended"
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.reportWindowController = NSWindowController(window: window)
    }

    private func dismissReportWindow() {
        reportWindowController?.close()
        reportWindowController = nil
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
