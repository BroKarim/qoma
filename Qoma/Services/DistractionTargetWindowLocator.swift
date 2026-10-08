import AppKit
import CoreGraphics

struct DistractionTargetWindow: Equatable {
    let number: Int
    let ownerPID: pid_t
    let level: Int
    let frame: CGRect
    var occludedRegions: [CGRect] = []
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

        for (index, info) in windows.enumerated() {
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
            let occlusions: [CGRect] = windows.prefix(index).compactMap { other in
                guard let owner = (other[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
                    owner != ProcessInfo.processInfo.processIdentifier,
                    let layer = (other[kCGWindowLayer as String] as? NSNumber)?.intValue,
                    layer >= 0, layer <= level + 1,
                    ((other[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1) > 0.01,
                    let b = other[kCGWindowBounds as String] as? [String: NSNumber],
                    let ox = b["X"]?.doubleValue, let oy = b["Y"]?.doubleValue,
                    let ow = b["Width"]?.doubleValue, let oh = b["Height"]?.doubleValue else { return nil }
                let rect = CGRect(x: ox, y: mainScreen.frame.maxY - oy - oh, width: ow, height: oh)
                    .intersection(frame)
                guard !rect.isNull, !rect.isEmpty else { return nil }
                return rect.offsetBy(dx: -frame.minX, dy: -frame.minY)
            }
            return DistractionTargetWindow(
                number: number, ownerPID: pid, level: level, frame: frame, occludedRegions: occlusions)
        }
        return nil
    }
}
