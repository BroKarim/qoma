import Cocoa
import Combine
import SwiftUI
import OSLog

/// Owns the qyube runtime: home window, session coordinator, timer panel, companion panel, overlay, and menu bar status.
@MainActor
final class QyubeAppCoordinator: NSObject, NSWindowDelegate {
    let sessionCoordinator: SessionCoordinator
    private let focusPreferences = FocusPreferences.shared
    private let timerController = FloatingTimerController()
    private let companionController = CompanionWindowController()
    private let overlayController = DistractionOverlayController()
    private let distractionCoordinator: DistractionCoordinator
    private let menuBarController: MenuBarController
    private var cancellables = Set<AnyCancellable>()
    private let navigation = QyubeNavigation()
    private var visibleSessionID: UUID?
    private var mainWindowIsVisible = false
    private var trackedSessionID: UUID?

    init(sessionCoordinator: SessionCoordinator? = nil) {
        self.sessionCoordinator = sessionCoordinator ?? SessionCoordinator()
        LegacySessionMigrator.migrateIfNeeded()
        self.distractionCoordinator = DistractionCoordinator(monitor: ForegroundActivityMonitor())
        self.menuBarController = MenuBarController()
        super.init()

        menuBarController.configure(
            coordinator: self.sessionCoordinator,
            preferences: self.focusPreferences,
            onStart: { [weak self] minutes in await self?.startFromMenuBar(minutes: minutes) ?? false },
            onOpen: { [weak self] in self?.navigation.page = nil; self?.showHomeWindow() },
            onSettings: { [weak self] in self?.navigation.page = .settings; self?.showHomeWindow() },
            onShowTimer: { [weak self] in self?.restoreTimerPanel() },
            loadCatches: { [weak self] in
                guard let self else { return [] }
                return CatchRepository.shared.listBanked(accountID: self.sessionCoordinator.sessionAccountID)
            }
        )

        configurePanels()
        bindSessionCoordinator()
        bindDistractionCoordinator()
        SettingsWindowController.compactSettingsAction = { [weak self] in
            self?.navigation.page = .settings
            self?.showHomeWindow()
        }
        self.sessionCoordinator.restore()
        navigation.refresh()
    }

    func showHomeWindow() {
        if let existing = homeWindowController?.window {
            if !mainWindowIsVisible {
                mainWindowIsVisible = true
                AppActivationPolicy.enter()
            }
            existing.deminiaturize(nil)
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let contentView = QyubeHomeView(
            navigation: navigation,
            sessionCoordinator: sessionCoordinator,
            onSessionStarted: { [weak self] in self?.homeWindowController?.close() },
            onBackToSession: { [weak self] in self?.returnToSession() })
        let window = QyubeHomeWindow(
            contentRect: NSRect(x: 0, y: 0, width: 310, height: 510),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.title = "qyube"
        window.appearance = NSAppearance(named: .aqua)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        mainWindowIsVisible = true
        AppActivationPolicy.enter()
        window.makeKeyAndOrderFront(nil)
        self.homeWindowController = NSWindowController(window: window)
    }

    func windowWillClose(_ notification: Notification) {
        guard mainWindowIsVisible else { return }
        mainWindowIsVisible = false
        AppActivationPolicy.leave()
    }

    func restoreTimerPanel() {
        guard sessionCoordinator.isActive || sessionCoordinator.isPaused else { return }
        guard !timerController.isVisible else { return }
        timerController.show(
            remainingTime: sessionCoordinator.remainingTime
        )
    }

    private func returnToSession() {
        homeWindowController?.close()
        if focusPreferences.hideFloatingTimer {
            menuBarController.showPopover()
        } else {
            restoreTimerPanel()
        }
    }

    // MARK: - Private

    private var homeWindowController: NSWindowController?

    private func startFromMenuBar(minutes: Int) async -> Bool {
        guard sessionCoordinator.snapshot == nil else { return false }
        let draft = focusPreferences.draft(minutes: minutes)
        return sessionCoordinator.startSession(draft: draft) != nil
    }

    private func configurePanels() {
        overlayController.onVisualStateChanged = { [weak self] visual in
            self?.companionController.setDistractionVisual(visual)
        }

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

        sessionCoordinator.$lastCatchEvent
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.companionController.recordCatch(kindID: event.kindID)
                self?.navigation.refresh()
                NotificationCenter.default.post(name: .qyubeCollectionChanged, object: nil)
            }
            .store(in: &cancellables)

        sessionCoordinator.$remainingTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTimerPanel()
                self?.updateStatusItem()
            }
            .store(in: &cancellables)

        sessionCoordinator.$catchesRevision
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.navigation.refresh()
                NotificationCenter.default.post(name: .qyubeCollectionChanged, object: nil)
            }
            .store(in: &cancellables)

        sessionCoordinator.$finalizationState
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self, state != .idle else { return }
                self.finishAnalyticsTracking()
                self.timerController.hide()
                self.companionController.hide()
                self.distractionCoordinator.stop()
                self.overlayController.hide()
                if case .failed = state {
                    self.menuBarController.showPopover()
                }
            }
            .store(in: &cancellables)

        focusPreferences.$hideFloatingTimer
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hidden in
                if hidden {
                    self?.timerController.hide()
                } else {
                    self?.restoreTimerPanel()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: AppConstants.AnalyticsSettings.trackingPreferenceChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let snapshot = self.sessionCoordinator.snapshot else { return }
                self.updateAnalyticsTracking(for: snapshot)
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
                updateAnalyticsTracking(for: snapshot)
                companionController.show(sessionID: snapshot.id, paused: snapshot.status == .paused)
                if focusPreferences.hideFloatingTimer {
                    timerController.hide()
                } else if visibleSessionID != snapshot.id {
                    visibleSessionID = snapshot.id
                    timerController.show(
                        remainingTime: sessionCoordinator.remainingTime
                    )
                } else {
                    timerController.update(
                        remainingTime: sessionCoordinator.remainingTime
                    )
                }
                visibleSessionID = snapshot.id
                if snapshot.status == .active, snapshot.draft.policy.mode != .timerOnly {
                    distractionCoordinator.start(
                        policy: snapshot.draft.policy,
                        selectedDomainBrowserID: snapshot.draft.domainBrowserBundleID
                    )
                } else {
                    distractionCoordinator.stop()
                    overlayController.hide()
                }
            } else {
                finishAnalyticsTracking()
                visibleSessionID = nil
                timerController.hide()
                companionController.hide()
                distractionCoordinator.stop()
                overlayController.hide()
            }
        } else {
            finishAnalyticsTracking()
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
        timerController.update(
            remainingTime: sessionCoordinator.remainingTime
        )
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

    private func onSessionEnded(_ session: FocusSession) {
        finishAnalyticsTracking()
        navigation.refresh()
        NotificationCenter.default.post(name: .qyubeCollectionChanged, object: nil)
        guard session.status == .completed else { return }
        let defaults = UserDefaults.standard
        SoundAlertPlayer.shared.play(
            soundID: defaults.string(forKey: AppConstants.SoundSettings.selectedSoundKey)
                ?? AppConstants.SoundSettings.defaultSoundID,
            volume: defaults.object(forKey: AppConstants.SoundSettings.volumeKey) as? Double
                ?? AppConstants.SoundSettings.defaultVolume)
        menuBarController.showIdleAfterCompletion()
    }

    private func updateAnalyticsTracking(for snapshot: ActiveSessionSnapshot) {
        guard AppConstants.AnalyticsSettings.isAnalyticsEnabled else {
            finishAnalyticsTracking(persist: false)
            return
        }
        let tracker = ActivityTracker.shared
        if trackedSessionID != snapshot.id {
            finishAnalyticsTracking()
            trackedSessionID = snapshot.id
            if snapshot.status == .active {
                tracker.startTracking(
                    sessionID: snapshot.id,
                    trackWebsites: PermissionManager.shared.automationStatus == .granted
                )
            }
        }
        if snapshot.status == .paused, tracker.isTracking {
            tracker.pauseTracking()
        } else if snapshot.status == .active, !tracker.isTracking {
            tracker.resumeTracking(
                sessionID: snapshot.id,
                trackWebsites: PermissionManager.shared.automationStatus == .granted
            )
        }
    }

    private func finishAnalyticsTracking(persist: Bool = true) {
        guard let sessionID = trackedSessionID else { return }
        trackedSessionID = nil
        let (appEvents, webVisits) = ActivityTracker.shared.stopTracking()
        if persist {
            if !appEvents.isEmpty, !AnalyticsStore.shared.appendAppActivityEvents(appEvents) {
                Logger.store.error("Could not persist final app activity batch")
            }
            if !webVisits.isEmpty, !AnalyticsStore.shared.appendWebsiteVisits(webVisits) {
                Logger.store.error("Could not persist final website activity batch")
            }
        } else if !AnalyticsStore.shared.deleteActivity(sessionID: sessionID) {
            Logger.store.error("Could not remove activity after analytics consent was withdrawn")
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
