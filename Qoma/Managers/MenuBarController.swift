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
final class MenuBarPanelState: ObservableObject {
    @Published var completedSession: FocusSession?
    @Published var completedCatchCount = 0
}

@MainActor
final class MenuBarController: NSObject {
    static var shared: MenuBarController?
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let panel = MenuBarPanel(
        contentRect: NSRect(x: 0, y: 0, width: AppConstants.MenuBarSettings.panelWidth, height: AppConstants.MenuBarSettings.panelHeight),
        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false
    )
    private let panelState = MenuBarPanelState()
    private var latestTitle = ""
    private var preferencesObserver: AnyCancellable?
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?

    override init() {
        super.init()
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
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
        onStart: @escaping (Int) async -> Bool,
        onOpen: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onShowTimer: @escaping () -> Void,
        onViewCatches: @escaping (FocusSession) -> Void
    ) {
        let rootView = MenuBarView(
            coordinator: coordinator, panelState: panelState,
            onStart: { [weak self] minutes in
                let success = await onStart(minutes)
                if success { self?.closePanel() }
                return success
            },
            onOpen: { [weak self] in self?.closePanel(); onOpen() },
            onSettings: { [weak self] in self?.closePanel(); onSettings() },
            onShowTimer: { [weak self] in self?.closePanel(); onShowTimer() },
            onViewCatches: { [weak self] session in self?.closePanel(); onViewCatches(session) }
        )
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
        button.setAccessibilityLabel("Open qyube controls, \(title)")
        statusItem.length = NSStatusItem.variableLength
    }

    func showCompletion(_ session: FocusSession, catchCount: Int) {
        guard session.status == .completed else { return }
        panelState.completedSession = session
        panelState.completedCatchCount = catchCount
        showPopover()
    }

    func showPopover() {
        positionPanelBelowStatusItem()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePanel() {
        panel.orderOut(nil)
        panelState.completedSession = nil
    }

    @objc private func togglePopover() {
        if panel.isVisible { closePanel() } else { showPopover() }
    }

    private func positionPanelBelowStatusItem() {
        guard let buttonFrame = self.statusButtonFrameInScreen() else { return }

        let panelSize = NSSize(
            width: AppConstants.MenuBarSettings.panelWidth,
            height: AppConstants.MenuBarSettings.panelHeight)
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
