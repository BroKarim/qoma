import AppKit
import CoreGraphics

struct DistractionTargetWindow: Equatable {
    let number: Int
    let ownerPID: pid_t
    let level: Int
    let frame: CGRect
}

/// Reads window geometry only. It never captures another app's pixels.
struct DistractionTargetWindowLocator {
    func frontWindow(for pid: pid_t) -> DistractionTargetWindow? {
        guard let mainScreen = NSScreen.screens.first(where: { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }
            return number.uint32Value == CGMainDisplayID()
        }),
            let windows = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
        else { return nil }

        for info in windows {
            guard let windowPID = (info[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
                windowPID == pid,
                let number = (info[kCGWindowNumber as String] as? NSNumber)?.intValue,
                let level = (info[kCGWindowLayer as String] as? NSNumber)?.intValue,
                level >= 0, level <= NSWindow.Level.modalPanel.rawValue,
                let bounds = info[kCGWindowBounds as String] as? [String: NSNumber],
                let x = bounds["X"]?.doubleValue,
                let y = bounds["Y"]?.doubleValue,
                let width = bounds["Width"]?.doubleValue,
                let height = bounds["Height"]?.doubleValue,
                width >= 120, height >= 80,
                ((info[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1) > 0.01
            else { continue }

            // CGWindow bounds use a top-left global origin; AppKit uses bottom-left.
            let frame = CGRect(
                x: x,
                y: mainScreen.frame.maxY - y - height,
                width: width,
                height: height)
            guard NSScreen.screens.contains(where: { $0.frame.intersects(frame) }) else { continue }
            return DistractionTargetWindow(number: number, ownerPID: pid, level: level, frame: frame)
        }
        return nil
    }
}
