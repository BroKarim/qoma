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
            onOpen: { [weak self] in
                self?.navigation.todayRequest = UUID()
                self?.showHomeWindow()
            },
            onEditActiveSession: { [weak self] in
                self?.navigation.editActiveSessionRequest = UUID()
                self?.showHomeWindow()
            },
            onSettings: { [weak self] in self?.navigation.page = .settings; self?.showHomeWindow() }
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
            } else {
                NSApp.activate(ignoringOtherApps: true)
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
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
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
        guard !focusPreferences.hideFloatingTimer else { return }
        guard !timerController.isVisible else { return }
        timerController.show(
            remainingTime: sessionCoordinator.remainingTime,
            title: sessionCoordinator.currentTaskTitle,
            isPaused: sessionCoordinator.isPaused
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

    private func configurePanels() {
        timerController.configure(
            onTogglePause: { [weak self] in
                guard let self else { return false }
                let wasPaused = self.sessionCoordinator.isPaused
                if wasPaused { self.sessionCoordinator.resumeSession() } else {
                    self.sessionCoordinator.pauseSession()
                }
                return wasPaused != self.sessionCoordinator.isPaused
            },
            onEdit: { [weak self] in
                self?.navigation.editActiveSessionRequest = UUID()
                self?.showHomeWindow()
            },
            onStop: { [weak self] in
                _ = self?.sessionCoordinator.stopSession(reason: "Stopped from floating timer")
            },
            onRepeat: { [weak self] session in self?.repeatSession(session) ?? false },
            onReview: { [weak self] session in self?.reviewSession(session) },
            onToday: { [weak self] in
                self?.navigation.page = nil
                self?.navigation.sessionToReview = nil
                self?.navigation.todayRequest = UUID()
                self?.showHomeWindow()
            })
        timerController.onBreakChanged = { [weak self] in
            guard let self else { return }
            self.navigation.breakRemaining = self.timerController.isOnBreak
                ? self.timerController.breakRemaining : nil
            self.updateStatusItem()
        }

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
                self.timerController.hideFocus()
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
                    self?.timerController.hideFocus()
                } else {
                    self?.menuBarController.dismissPopover()
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
                    timerController.hideFocus()
                } else if visibleSessionID != snapshot.id {
                    visibleSessionID = snapshot.id
                    timerController.show(
                        remainingTime: sessionCoordinator.remainingTime,
                        title: sessionCoordinator.currentTaskTitle,
                        isPaused: snapshot.status == .paused
                    )
                } else {
                    timerController.update(
                        remainingTime: sessionCoordinator.remainingTime,
                        title: sessionCoordinator.currentTaskTitle,
                        isPaused: snapshot.status == .paused
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
                timerController.hideFocus()
                companionController.hide()
                distractionCoordinator.stop()
                overlayController.hide()
            }
        } else {
            finishAnalyticsTracking()
            visibleSessionID = nil
            timerController.hideFocus()
            companionController.hide()
            distractionCoordinator.stop()
            overlayController.hide()
        }
        updateStatusItem()
    }

    private func updateTimerPanel() {
        guard sessionCoordinator.snapshot != nil else { return }
        timerController.update(
            remainingTime: sessionCoordinator.remainingTime,
            title: sessionCoordinator.currentTaskTitle,
            isPaused: sessionCoordinator.isPaused
        )
    }

    private func updateStatusItem() {
        let title: String
        if timerController.isOnBreak {
            title = timerController.isBreakFinished
                ? "Break done" : "Break \(formatTime(timerController.breakRemaining))"
        } else if let snapshot = sessionCoordinator.snapshot,
                  snapshot.status == .active || snapshot.status == .paused {
            title = snapshot.status == .paused
                ? "Ⅱ \(formatTime(sessionCoordinator.remainingTime))"
                : formatTime(sessionCoordinator.remainingTime)
        } else {
            title = ""
        }
        menuBarController.updateTitle(title)
    }

    private func onSessionEnded(_ session: FocusSession) {
        finishAnalyticsTracking()
        menuBarController.dismissPopover()
        navigation.refresh()
        NotificationCenter.default.post(name: .qyubeCollectionChanged, object: nil)
        guard session.status == .completed else { return }
        let defaults = UserDefaults.standard
        SoundAlertPlayer.shared.play(
            soundID: defaults.string(forKey: AppConstants.SoundSettings.selectedSoundKey)
                ?? AppConstants.SoundSettings.defaultSoundID,
            volume: defaults.object(forKey: AppConstants.SoundSettings.volumeKey) as? Double
                ?? AppConstants.SoundSettings.defaultVolume)
        let catches = CatchRepository.shared.listBanked(accountID: sessionCoordinator.sessionAccountID)
            .filter { $0.sessionID == session.id }
        timerController.showCompletion(session: session, catches: catches)
    }

    private func repeatSession(_ session: FocusSession) -> Bool {
        guard sessionCoordinator.snapshot == nil, sessionCoordinator.finalizationState == .idle else { return false }
        guard let draft = Self.repeatDraft(for: session) else { return false }
        return sessionCoordinator.startSession(draft: draft) != nil
    }

    static func repeatDraft(for session: FocusSession) -> SessionDraft? {
        var draft = session.draftSnapshot
        draft.taskTitle = draft.taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !draft.taskTitle.isEmpty else { return nil }
        guard draft.policy.mode != .allowing || !draft.policy.allowedApps.isEmpty else { return nil }
        return draft
    }

    private func reviewSession(_ session: FocusSession) {
        navigation.page = nil
        navigation.sessionToReview = session
        showHomeWindow()
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
