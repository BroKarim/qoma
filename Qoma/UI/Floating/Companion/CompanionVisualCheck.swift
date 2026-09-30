#if DEBUG
import AppKit
import SpriteKit

/// Opt-in render check, run in a separate Debug app process with --companion-snapshots <directory>.
/// It uses bundled textures and the actual renderer; no monitoring or session persistence is started.
@MainActor
enum CompanionVisualCheck {
    static func write(to directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 280, height: 280))
        view.allowsTransparency = true
        let window = NSWindow(contentRect: view.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = view
        let scene = CompanionScene()
        view.presentScene(scene)
        view.isPaused = true
        let samples: [(String, (CompanionScene) -> Void)] = [
            ("01-fishing", { $0.startSession(); $0.advanceAnimation(by: 1.21) }),
            ("02-bite", { $0.biteNow() }),
            ("03-pulling", { $0.advanceAnimation(by: 1.4) }),
            ("04-deposit", {
                // Reel duration is randomized. Advance until the continuous deposit begins.
                while $0.playback.phase != .deposit {
                    $0.advanceAnimation(by: 0.01)
                }
                $0.advanceAnimation(by: 0.2)
            }),
            ("05-sleeping", { $0.setSessionPaused(true) }),
            ("06-distracted", { $0.setSessionPaused(false); $0.setDistracted(true); $0.advanceAnimation(by: 0.18) }),
            ("07-completed", { $0.completeSession() }),
            ("08-releasing", {
                $0.startSession(); $0.advanceAnimation(by: 1.21); $0.biteNow()
                while $0.playback.depositedCatches == 0 {
                    $0.advanceAnimation(by: 0.01)
                }
                $0.stopSession(activeSeconds: 60); $0.advanceAnimation(by: 0.6)
            }),
        ]
        let board = NSImage(size: CGSize(width: 800, height: 540))
        board.lockFocus()
        NSColor(white: 0.93, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: 800, height: 540).fill()
        for (index, sample) in samples.enumerated() {
            sample.1(scene)
            guard let texture = view.texture(from: scene, crop: CGRect(origin: .zero, size: CompanionScene.stageSize))
            else {
                throw NSError(
                    domain: "CompanionVisualCheck",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "SpriteKit could not render \(sample.0)"])
            }
            let image = texture.cgImage()
            let bitmap = NSBitmapImageRep(cgImage: image)
            try bitmap.representation(using: .png, properties: [:])!
                .write(to: directory.appendingPathComponent("\(sample.0).png"))
            let x = CGFloat(index % 4) * 200
            let y = CGFloat(1 - index / 4) * 270
            let rendered = NSImage(cgImage: image, size: CompanionScene.stageSize)
            rendered.draw(in: CGRect(x: x + 30, y: y + 110, width: 140, height: 140))
            // A second miniature on a dark background catches alpha fringes.
            NSColor(white: 0.14, alpha: 1).setFill()
            NSRect(x: x + 50, y: y + 10, width: 100, height: 90).fill()
            rendered.draw(in: CGRect(x: x + 65, y: y + 18, width: 70, height: 70))
            (sample.0 as NSString).draw(at: CGPoint(x: x + 40, y: y + 96), withAttributes: [
                .font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.black,
            ])
        }
        board.unlockFocus()
        let boardBitmap = NSBitmapImageRep(data: board.tiffRepresentation!)!
        try boardBitmap.representation(using: .png, properties: [:])!
            .write(to: directory.appendingPathComponent("contact-sheet.png"))
        scene.shutDown()
        view.presentScene(nil)
        window.contentView = nil
    }
}
#endif
