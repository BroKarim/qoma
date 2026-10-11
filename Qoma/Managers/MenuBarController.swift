import AppKit
import Combine
import SwiftUI

@MainActor
final class MenuBarPanelState: ObservableObject {
    @Published var completedSession: FocusSession?
    @Published var completedCatchCount = 0
}

@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {
    static var shared: MenuBarController?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private let panelState = MenuBarPanelState()
    private weak var coordinator: SessionCoordinator?

    override init() {
        super.init()
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
        popover.behavior = .transient
        popover.delegate = self
        updateTitle("")
        Self.shared = self
    }

    func configure(
        coordinator: SessionCoordinator,
        onStart: @escaping (Int) async -> Bool,
        onOpen: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        onShowTimer: @escaping () -> Void,
        onViewCatches: @escaping (FocusSession) -> Void
    ) {
        self.coordinator = coordinator
        popover.contentViewController = NSHostingController(rootView: MenuBarView(
            coordinator: coordinator,
            panelState: panelState,
            onStart: onStart,
            onOpen: { [weak self] in self?.popover.performClose(nil); onOpen() },
            onSettings: { [weak self] in self?.popover.performClose(nil); onSettings() },
            onShowTimer: { [weak self] in self?.popover.performClose(nil); onShowTimer() },
            onViewCatches: { [weak self] session in
                self?.popover.performClose(nil)
                onViewCatches(session)
            }
        ))
    }

    func updateTitle(_ title: String) {
        guard let button = statusItem.button else { return }
        let compact = UserDefaults.standard.object(forKey: AppConstants.MenuBarSettings.compactIconKey) as? Bool ?? true
        let title = compact ? "" : title
        button.title = title
        button.image = title.isEmpty ? makeStatusIcon() : nil
        button.imagePosition = title.isEmpty ? .imageOnly : .noImage
        button.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        button.setAccessibilityLabel(title.isEmpty ? "Open qyube controls" : "qyube, \(title) remaining")
        statusItem.length = title.isEmpty ? NSStatusItem.squareLength : NSStatusItem.variableLength
    }

    func showCompletion(_ session: FocusSession, catchCount: Int) {
        guard session.status == .completed else { return }
        panelState.completedSession = session
        panelState.completedCatchCount = catchCount
        showPopover()
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        let height: CGFloat = if panelState.completedSession != nil {
            160
        } else if coordinator?.snapshot != nil {
            176
        } else {
            235
        }
        popover.contentSize = NSSize(width: 282, height: height)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func popoverDidClose(_ notification: Notification) {
        panelState.completedSession = nil
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func makeStatusIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { rect in
            NSColor.labelColor.setFill()
            NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 4, yRadius: 4).fill()
            let label = NSString(string: "Q")
            label.draw(at: NSPoint(x: 4, y: 2), withAttributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold),
                .foregroundColor: NSColor.windowBackgroundColor,
            ])
            return true
        }
        image.isTemplate = true
        return image
    }
}
