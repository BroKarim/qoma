import AppKit

/// Borderless main window that still accepts keyboard input and presents sheets.
final class QyubeHomeWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
