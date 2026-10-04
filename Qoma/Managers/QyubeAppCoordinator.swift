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
    private let navigation = QyubeNavigation()
    private var visibleSessionID: UUID?

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
        SettingsWindowController.compactSettingsAction = { [weak self] in
            self?.navigation.page = .settings
            self?.showHomeWindow()
        }
        self.sessionCoordinator.restore()
    }

    func showHomeWindow() {
        if let existing = homeWindowController?.window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = QyubeHomeView(
            sessionCoordinator: sessionCoordinator, navigation: navigation,
            onClose: { [weak self] in self?.homeWindowController?.window?.orderOut(nil) },
            onShowTimer: { [weak self] in self?.restoreTimerPanel() },
            onStarted: { [weak self] in self?.homeWindowController?.window?.orderOut(nil) }
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 610),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "qyube"
        window.appearance = NSAppearance(named: .aqua)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.center()
        window.contentView = NSHostingView(rootView: contentView.ignoresSafeArea())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.homeWindowController = NSWindowController(window: window)
    }

    func restoreTimerPanel() {
        guard let snapshot = sessionCoordinator.snapshot else { return }
        guard !timerController.isVisible else { return }
        timerController.show(remainingTime: sessionCoordinator.remainingTime, taskTitle: snapshot.draft.displayTitle, isPaused: snapshot.status == .paused)
    }

    // MARK: - Private

    private var homeWindowController: NSWindowController?

    private func configurePanels() {
        overlayController.onVisualStateChanged = { [weak self] visual in
            self?.companionController.setDistractionVisual(visual)
        }

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
                companionController.show(sessionID: snapshot.id, paused: snapshot.status == .paused)
                if visibleSessionID != snapshot.id {
                    visibleSessionID = snapshot.id
                    timerController.show(remainingTime: sessionCoordinator.remainingTime, taskTitle: snapshot.draft.displayTitle, isPaused: snapshot.status == .paused)
                } else {
                    timerController.update(remainingTime: sessionCoordinator.remainingTime, taskTitle: snapshot.draft.displayTitle, isPaused: snapshot.status == .paused)
                }
                if snapshot.status == .active, snapshot.draft.policy.mode != .timerOnly {
                    distractionCoordinator.start(policy: snapshot.draft.policy)
                } else {
                    distractionCoordinator.stop()
                    overlayController.hide()
                }
            } else {
                visibleSessionID = nil
                timerController.hide()
                companionController.hide()
                distractionCoordinator.stop()
                overlayController.hide()
            }
        } else {
            visibleSessionID = nil
            timerController.hide()
            companionController.hide()
            distractionCoordinator.stop()
            overlayController.hide()
        }
        updateStatusItem()
    }

    private func updateTimerPanel() {
        guard sessionCoordinator.snapshot != nil else { return }
        timerController.update(remainingTime: sessionCoordinator.remainingTime, taskTitle: sessionCoordinator.currentTaskTitle, isPaused: sessionCoordinator.isPaused)
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
        navigation.showReport(session)
        showHomeWindow()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
