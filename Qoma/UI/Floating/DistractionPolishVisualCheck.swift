#if DEBUG
import AppKit
import ImageIO
import SpriteKit
import UniformTypeIdentifiers

/// Renders only a private test window and our own sprites; no other application's pixels are read.
@MainActor
enum DistractionPolishVisualCheck {
    static func writeDrawnClips(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let samples: [(String, DistractionEffect, Double, Double)] = [
            ("lights", .dimBright, 0, 7), ("ice", .iceFlower, 0, 3), ("snow", .snowstorm, 0, 4),
        ]
        for (name, effect, offset, duration) in samples {
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 280, height: 280))
            view.allowsTransparency = true
            let window = NSWindow(contentRect: view.frame, styleMask: .borderless, backing: .buffered, defer: false)
            window.contentView = view
            let scene = CompanionScene()
            view.presentScene(scene)
            view.isPaused = true
            var date = Date(timeIntervalSince1970: 100 + offset)
            scene.visualNow = { date }
            scene.startSession()
            scene.setDistractionVisual(.init(
                effect: effect, startedAt: Date(timeIntervalSince1970: 100), seed: 1, ownerPID: 42))
            defer {
                scene.shutDown()
                view.presentScene(nil)
                window.contentView = nil
            }
            let count = Int(duration * 30)
            let url = directory.appendingPathComponent("\(name)-drawn-v3.gif")
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, count, nil)
            else { throw error("Cannot create drawn-frame preview") }
            CGImageDestinationSetProperties(destination, [
                kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0],
            ] as CFDictionary)
            var seenDrawings = Set<Int>()
            let stills = directory.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: stills, withIntermediateDirectories: true)
            for tick in 0..<count {
                try autoreleasepool {
                    let elapsed = offset + Double(tick) / 30
                    date = Date(timeIntervalSince1970: 100 + elapsed)
                    scene.advanceAnimation(by: 1.0 / 30)
                    guard let texture = view.texture(from: scene, crop: CGRect(origin: .zero, size: CompanionScene.stageSize)),
                          let bitmap = NSBitmapImageRep(
                            bitmapDataPlanes: nil, pixelsWide: 560, pixelsHigh: 280,
                            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
                    else { throw error("Cannot render drawn-frame preview") }
                    NSGraphicsContext.saveGraphicsState()
                    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
                    NSColor(white: 0.96, alpha: 1).setFill()
                    CGRect(x: 0, y: 0, width: 280, height: 280).fill()
                    NSColor(white: 0.12, alpha: 1).setFill()
                    CGRect(x: 280, y: 0, width: 280, height: 280).fill()
                    let image = texture.cgImage()
                    NSGraphicsContext.current?.cgContext.draw(image, in: CGRect(x: 12, y: 0, width: 255, height: 280))
                    NSGraphicsContext.current?.cgContext.draw(image, in: CGRect(x: 292, y: 0, width: 255, height: 280))
                    NSGraphicsContext.restoreGraphicsState()
                    guard let image = bitmap.cgImage else { throw error("Cannot encode drawn-frame preview") }
                    CGImageDestinationAddImage(destination, image, [
                        kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1.0 / 30],
                    ] as CFDictionary)
                    let drawing = DistractionMotion.penguinFrame(effect: effect, elapsed: elapsed, reduceMotion: false)
                    if seenDrawings.insert(drawing).inserted {
                        try bitmap.representation(using: .png, properties: [:])?
                            .write(to: stills.appendingPathComponent(String(format: "drawing-%02d.png", drawing)))
                    }
                }
            }
            guard CGImageDestinationFinalize(destination), seenDrawings.count == (effect == .iceFlower ? 11 : 12)
            else { throw error("Drawn preview must show every connecting drawing") }
            print("DRAWN effect=\(name) drawings=\(seenDrawings.count) renderedFrames=\(count) preview=\(url.path)")
        }
    }

    static func write(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let frame = CGRect(x: 120, y: 120, width: 720, height: 480)
        let fixture = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        fixture.backgroundColor = .white
        fixture.orderFrontRegardless()
        let panel = NSPanel(
            contentRect: CGRect(x: frame.maxX - 160, y: frame.minY + 22, width: 140, height: 140),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        let view = SKView(frame: CGRect(origin: .zero, size: CompanionScene.stageSize))
        view.allowsTransparency = true
        panel.contentView = view
        let scene = CompanionScene()
        scene.startSession()
        view.presentScene(scene)
        view.isPaused = true
        panel.orderFrontRegardless()
        var date = Date(timeIntervalSince1970: 100)
        scene.visualNow = { date }
        let controller = DistractionOverlayController(
            frontmostPID: { 42 },
            locate: { DistractionTargetWindow(number: fixture.windowNumber, ownerPID: $0, level: 0, frame: frame) },
            now: { date }, chooseEffect: { .dimBright }, audio: DistractionAudioPlayer(enabled: { false }))
        controller.onVisualStateChanged = { scene.setDistractionVisual($0) }
        defer {
            controller.hide()
            scene.shutDown()
            view.presentScene(nil)
            panel.orderOut(nil)
            fixture.orderOut(nil)
        }
        controller.show(decision: .init(isDistraction: true, reason: .safeByDefault))
        let url = directory.appendingPathComponent("lights-smooth-preview.gif")
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, 240, nil)
        else { throw error("Cannot create GIF destination") }
        CGImageDestinationSetProperties(destination, [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0],
        ] as CFDictionary)
        for tick in 0..<240 {
            try autoreleasepool {
                date = Date(timeIntervalSince1970: 100 + Double(tick) / 30)
                controller.updateFrame()
                scene.advanceAnimation(by: 1.0 / 30)
                guard let surface = controller.surface,
                      let veil = surface.bitmapImageRepForCachingDisplay(in: surface.bounds),
                      let penguin = view.texture(from: scene, crop: CGRect(origin: .zero, size: CompanionScene.stageSize)),
                      let bitmap = NSBitmapImageRep(
                        bitmapDataPlanes: nil, pixelsWide: 720, pixelsHigh: 480,
                        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
                else { throw error("Cannot render fixture frame") }
                surface.cacheDisplay(in: surface.bounds, to: veil)
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
                NSColor(white: 0.95, alpha: 1).setFill()
                CGRect(origin: .zero, size: frame.size).fill()
                ("Weekend reading" as NSString).draw(at: CGPoint(x: 35, y: 385), withAttributes: [
                    .font: NSFont.systemFont(ofSize: 32, weight: .bold), .foregroundColor: NSColor.black,
                ])
                for row in 0..<8 {
                    NSColor(white: 0.77, alpha: 1).setFill()
                    CGRect(x: 35, y: 50 + row * 35, width: 650, height: 4).fill()
                }
                if let image = veil.cgImage {
                    NSGraphicsContext.current?.cgContext.draw(image, in: CGRect(origin: .zero, size: frame.size))
                }
                NSGraphicsContext.current?.cgContext.draw(penguin.cgImage(), in: CGRect(
                    x: panel.frame.minX - frame.minX, y: panel.frame.minY - frame.minY, width: 140, height: 140))
                NSGraphicsContext.restoreGraphicsState()
                guard let image = bitmap.cgImage else { throw error("Cannot encode fixture frame") }
                CGImageDestinationAddImage(destination, image, [
                    kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1.0 / 30],
                ] as CFDictionary)
                if tick == 60 || tick == 120 {
                    try bitmap.representation(using: .png, properties: [:])?
                        .write(to: directory.appendingPathComponent(tick == 60 ? "lights-press.png" : "lights-dark-silhouette.png"))
                }
            }
        }
        guard CGImageDestinationFinalize(destination) else { throw error("Cannot finalize GIF") }
        print("POLISH preview=\(url.path) frames=240 noRectangularCutouts=\(controller.surface?.occludedRegions.isEmpty == true)")
    }

    private static func error(_ message: String) -> NSError {
        NSError(domain: "DistractionPolishVisualCheck", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
#endif
