#if DEBUG
import AppKit
import ImageIO
import UniformTypeIdentifiers

/// Actual AppKit surfaces and controller, with a private fixture and clock; no focus records.
@MainActor
enum DistractionVisualCheck {
    static func writeCrystalClip(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let view = DistractionEffectView(frame: CGRect(x: 0, y: 0, width: 720, height: 480))
        let window = NSWindow(contentRect: view.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = view
        defer { window.contentView = nil }
        let state = DistractionVisualState(effect: .iceFlower, startedAt: Date(), seed: 7, ownerPID: 42)
        let url = directory.appendingPathComponent("crystal-bloom.gif")
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, 200, nil)
        else { throw CocoaError(.fileWriteUnknown) }
        CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        for tick in 0..<200 {
            try autoreleasepool {
                view.render(state: state, elapsed: 51 + Double(tick) / 20, reduceMotion: false)
                guard let overlay = view.bitmapImageRepForCachingDisplay(in: view.bounds),
                      let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 720, pixelsHigh: 480,
                        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
                else { throw CocoaError(.fileWriteUnknown) }
                view.cacheDisplay(in: view.bounds, to: overlay)
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
                NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.18, alpha: 1).setFill()
                view.bounds.fill()
                for row in 0..<9 {
                    NSColor(white: 0.35, alpha: 1).setFill()
                    CGRect(x: 30, y: 35 + row * 50, width: row.isMultiple(of: 2) ? 570 : 660, height: 7).fill()
                }
                if let image = overlay.cgImage {
                    NSImage(cgImage: image, size: view.bounds.size).draw(
                        in: view.bounds, from: .zero, operation: .sourceOver, fraction: 1)
                }
                NSGraphicsContext.restoreGraphicsState()
                guard let cgImage = bitmap.cgImage else { throw CocoaError(.fileWriteUnknown) }
                CGImageDestinationAddImage(destination, cgImage, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.05]] as CFDictionary)
                if tick == 0 { try bitmap.representation(using: .png, properties: [:])?.write(to: directory.appendingPathComponent("crystal-bloom.png")) }
            }
        }
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    }

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
            ("ice-start", .iceFlower, 1), ("ice-growing", .iceFlower, 11),
            ("ice-dense", .iceFlower, 31), ("ice-full", .iceFlower, 51),
            ("lights-bright", .dimBright, 0), ("lights-mid", .dimBright, 2),
            ("lights-dark", .dimBright, 4), ("lights-bright-again", .dimBright, 8),
            ("snow-start", .snowstorm, 1), ("snow-full", .snowstorm, 41),
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
            print("RENDER \(sample.0) flowers=\(surface.flowerCount) snow=\(surface.snowCount) veil=\(surface.dimOpacity)")
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

        // Measures CPU drawing in this debug fixture, not overall GPU usage or battery drain.
        if let surface = controller.surface,
           let bitmap = surface.bitmapImageRepForCachingDisplay(in: surface.bounds),
           let state = controller.state {
            let start = ProcessInfo.processInfo.systemUptime
            for tick in 0..<120 {
                surface.render(state: state, elapsed: 41 + Double(tick) / 30, reduceMotion: false)
                surface.cacheDisplay(in: surface.bounds, to: bitmap)
            }
            let milliseconds = (ProcessInfo.processInfo.systemUptime - start) * 1_000 / 120
            print("STORM averageDrawMs=\(milliseconds) size=900x650 frames=120")
        }
        controller.hide()
        try DistractionPolishVisualCheck.write(to: directory.appendingPathComponent("polish"))
    }
}
#endif
