import Cocoa
import Combine
import SwiftUI

private final class MenuBarPanel: NSPanel {
    var onDismiss: (() -> Void)?

    override func cancelOperation(_ sender: Any?) { onDismiss?() }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}

private final class EdgeToEdgeHostingView<Content: View>: NSHostingView<Content> {
    override var safeAreaInsets: NSEdgeInsets {
        .init(top: 0, left: 0, bottom: 0, right: 0)
    }
}

private final class EdgeToEdgeHostingController<Content: View>: NSHostingController<Content> {
    override func loadView() {
        self.view = EdgeToEdgeHostingView(rootView: self.rootView)
    }
}

@MainActor
final class MenuBarController: NSObject {
    static var shared: MenuBarController?
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let panel = MenuBarPanel(
        contentRect: NSRect(
            x: 0,
            y: 0,
            width: AppConstants.MenuBarSettings.panelWidth,
            height: AppConstants.MenuBarSettings.panelHeight
        ),
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )
    private weak var coordinator: SessionCoordinator?
    private var preferences: FocusPreferences?
    private var onOpen: (() -> Void)?
    private var onEditActiveSession: (() -> Void)?
    private var onSettings: (() -> Void)?
    private var latestTitle = ""
    private var preferencesObserver: AnyCancellable?
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?

    override init() {
        super.init()
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = true
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.appearance = NSAppearance(named: .aqua)
        panel.onDismiss = { [weak self] in self?.closePanel() }
        installClickMonitors()
        updateTitle("")
        preferencesObserver = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateTitle(self.latestTitle)
            }
        Self.shared = self
    }

    deinit {
        MainActor.assumeIsolated { self.removeClickMonitors() }
    }

    func configure(
        coordinator: SessionCoordinator,
        preferences: FocusPreferences,
        onOpen: @escaping () -> Void,
        onEditActiveSession: @escaping () -> Void,
        onSettings: @escaping () -> Void
    ) {
        self.coordinator = coordinator
        self.preferences = preferences
        self.onOpen = onOpen
        self.onEditActiveSession = onEditActiveSession
        self.onSettings = onSettings
        let rootView = MenuBarSessionPopover(
            coordinator: coordinator,
            onEdit: { [weak self] in self?.closePanel(); self?.onEditActiveSession?() },
            onStop: { [weak self, weak coordinator] in
                self?.closePanel()
                _ = coordinator?.stopSession(reason: "Stopped from menu bar")
            })
        let hostingController = EdgeToEdgeHostingController(rootView: rootView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentViewController = hostingController
    }

    func updateTitle(_ title: String) {
        latestTitle = title
        guard let button = statusItem.button else { return }
        let title = Self.displayTitle(sessionTitle: title, defaults: .standard)
        button.title = title
        button.image = nil
        button.imagePosition = .noImage
        button.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        let action = preferences?.hideFloatingTimer == true &&
            (coordinator?.isActive == true || coordinator?.isPaused == true)
            ? "Open session controls" : "Open Qyube"
        button.setAccessibilityLabel("\(action), \(title)")
        statusItem.length = NSStatusItem.variableLength
    }

    func showPopover() {
        positionPanelBelowStatusItem()
        panel.makeKeyAndOrderFront(nil)
    }

    func dismissPopover() { closePanel() }

    private func closePanel() {
        panel.orderOut(nil)
    }

    @objc private func togglePopover() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else if panel.isVisible {
            closePanel()
        } else if Self.shouldShowPopover(
            isRunning: coordinator?.isActive == true || coordinator?.isPaused == true,
            timerHidden: preferences?.hideFloatingTimer == true,
            finalization: coordinator?.finalizationState ?? .idle) {
            showPopover()
        } else {
            onOpen?()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        let open = NSMenuItem(title: "Open Qyube", action: #selector(openQyube), keyEquivalent: "")
        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: "")
        let quit = NSMenuItem(title: "Quit Qyube", action: #selector(quitQyube), keyEquivalent: "")
        for item in [open, settings, quit] { item.target = self; menu.addItem(item) }
        guard let button = statusItem.button else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY), in: button)
    }

    @objc private func openQyube() { closePanel(); onOpen?() }
    @objc private func openSettings() { closePanel(); onSettings?() }
    @objc private func quitQyube() { NSApp.terminate(nil) }

    static func shouldShowPopover(
        isRunning: Bool, timerHidden: Bool, finalization: SessionFinalizationState
    ) -> Bool {
        finalization != .idle || (isRunning && timerHidden)
    }

    private func positionPanelBelowStatusItem() {
        guard let buttonFrame = self.statusButtonFrameInScreen() else { return }

        let panelSize = coordinator?.finalizationState == .idle
            ? NSSize(
                width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
                height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)
            : NSSize(width: 260, height: 130)
        let spacing: CGFloat = 6
        var origin = NSPoint(
            x: buttonFrame.midX - (panelSize.width / 2),
            y: buttonFrame.minY - panelSize.height - spacing)

        if let screen = NSScreen.screens.first(where: { $0.frame.intersects(buttonFrame) })
            ?? NSScreen.main
        {
            let visible = screen.visibleFrame
            let minX = visible.minX
            let maxX = visible.maxX - panelSize.width
            origin.x = min(max(origin.x, minX), maxX)
            if origin.y < visible.minY {
                origin.y = buttonFrame.maxY + spacing
            }
        }

        self.panel.setFrame(NSRect(origin: origin, size: panelSize), display: true)
    }

    private func statusButtonFrameInScreen() -> NSRect? {
        guard let button = self.statusItem.button, let window = button.window else { return nil }
        let frameInWindow = button.convert(button.bounds, to: nil)
        return window.convertToScreen(frameInWindow)
    }

    private func installClickMonitors() {
        self.localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown])
            { [weak self] event in
                guard let self else { return event }
                self.dismissPanelIfNeeded(for: event)
                return event
            }

        self.globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown])
            { [weak self] event in
                self?.dismissPanelIfNeeded(for: event)
            }
    }

    private func removeClickMonitors() {
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
    }

    private func dismissPanelIfNeeded(for event: NSEvent) {
        guard self.panel.isVisible else { return }
        if let eventWindow = event.window,
           eventWindow !== panel,
           eventWindow.level == .popUpMenu {
            return
        }

        let screenPoint: NSPoint = if let eventWindow = event.window {
            eventWindow.convertPoint(toScreen: event.locationInWindow)
        } else {
            NSEvent.mouseLocation
        }

        let clickInsidePanel = self.panel.frame.contains(screenPoint)
        guard let statusButtonFrame = self.statusButtonFrameInScreen() else {
            return
        }
        let clickInsideStatusItem = statusButtonFrame.contains(screenPoint)
        if !clickInsidePanel, !clickInsideStatusItem {
            self.closePanel()
        }
    }

    static func displayTitle(sessionTitle: String, defaults: UserDefaults) -> String {
        guard sessionTitle.isEmpty else { return sessionTitle }
        let selected = defaults.object(forKey: AppConstants.MenuBarSettings.selectedPresetMinutesKey) as? Int
            ?? AppConstants.MenuBarSettings.defaultPresetMinutes
        return QyubeFormat.countdown(TimeInterval(min(60, max(1, selected)) * 60))
    }
}
