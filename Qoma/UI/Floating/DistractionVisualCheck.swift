#if DEBUG
import AppKit

/// Actual AppKit surfaces and controller, with a private fixture and clock; no focus records.
@MainActor
enum DistractionVisualCheck {
    static func write(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let frame = CGRect(x: 120, y: 120, width: 900, height: 650)
        let fixture = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        fixture.backgroundColor = .white
        fixture.orderFrontRegardless()
        defer { fixture.orderOut(nil) }
        var date = Date(timeIntervalSince1970: 100)
        var effect = DistractionEffect.iceFlower
        let controller = DistractionOverlayController(
            frontmostPID: { 42 },
            locate: { DistractionTargetWindow(number: fixture.windowNumber, ownerPID: $0, level: 0, frame: frame) },
            now: { date },
            chooseEffect: { effect },
            audio: DistractionAudioPlayer(enabled: { false }))
        defer { controller.hide() }
        let decision = PolicyDecision(isDistraction: true, reason: .safeByDefault)
        let samples: [(String, DistractionEffect, Double)] = [
            ("ice-06", .iceFlower, 1), ("ice-10", .iceFlower, 11),
            ("ice-18", .iceFlower, 31), ("ice-24", .iceFlower, 51),
            ("lights-bright", .dimBright, 0), ("lights-mid", .dimBright, 2),
            ("lights-dark", .dimBright, 4), ("lights-bright-again", .dimBright, 8),
        ]
        controller.show(decision: decision)
        for sample in samples {
            if effect != sample.1 {
                controller.hide()
                date = Date(timeIntervalSince1970: 100)
                effect = sample.1
                controller.show(decision: decision)
            }
            date = Date(timeIntervalSince1970: 100 + sample.2)
            controller.updateFrame()
            guard let surface = controller.surface,
                let bitmap = surface.bitmapImageRepForCachingDisplay(in: surface.bounds) else { continue }
            surface.cacheDisplay(in: surface.bounds, to: bitmap)
            let image = NSImage(size: frame.size)
            image.lockFocus()
            NSColor.white.setFill()
            CGRect(origin: .zero, size: frame.size).fill()
            ("Weekend reading" as NSString).draw(at: CGPoint(x: 60, y: 535), withAttributes: [
                .font: NSFont.systemFont(ofSize: 42, weight: .bold), .foregroundColor: NSColor.black])
            for row in 0..<11 {
                NSColor(white: 0.86, alpha: 1).setFill()
                CGRect(x: 60, y: 100 + row * 34, width: row % 3 == 0 ? 580 : 760, height: 6).fill()
            }
            if let cgImage = bitmap.cgImage {
                NSImage(cgImage: cgImage, size: frame.size).draw(
                    in: CGRect(origin: .zero, size: frame.size), from: .zero, operation: .sourceOver, fraction: 1)
            }
            image.unlockFocus()
            if let data = image.tiffRepresentation,
                let png = NSBitmapImageRep(data: data)?.representation(using: .png, properties: [:]) {
                try png.write(to: directory.appendingPathComponent(sample.0 + ".png"))
            }
            print("RENDER \(sample.0) flowers=\(surface.flowerCount) veil=\(surface.dimOpacity)")
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.15))
        let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
        func position(_ number: Int) -> Int? {
            windows.firstIndex { ($0[kCGWindowNumber as String] as? NSNumber)?.intValue == number }
        }
        guard let overlay = controller.window,
            let a = position(overlay.windowNumber), let b = position(fixture.windowNumber) else {
            throw NSError(
                domain: "DistractionVisualCheck",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "WindowServer did not expose the test windows"])
        }
        print("LAYER overlayAboveTarget=\(a < b) clickThrough=\(overlay.ignoresMouseEvents)")
        precondition(a < b && overlay.ignoresMouseEvents, "Overlay must be above target without intercepting input")
    }
}
#endif
