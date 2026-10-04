import AppKit
import SpriteKit

/// A 140 pt transparent stage; the shared floe occupies 118 pt of its width.
/// Positions are stage points, independent of Retina scale and window magnification.
final class CompanionScene: SKScene {
    static let stageSize = CGSize(width: 140, height: 140)
    private(set) var playback = CompanionPlayback()
    var onHidden: (() -> Void)?
    var reduceMotion = false {
        didSet { self.render() }
    }

    private let puppet = SKNode()
    private let head = SKSpriteNode(imageNamed: "CompanionHead")
    private let torso = SKSpriteNode(imageNamed: "CompanionTorso")
    private let feet = SKSpriteNode(imageNamed: "CompanionFeet")
    private let leftFlipper = SKSpriteNode(imageNamed: "CompanionFlipperLeft")
    private let rightFlipper = SKSpriteNode(imageNamed: "CompanionFlipperRight")
    private let rod = SKSpriteNode(imageNamed: "CompanionRod")
    private let restingPose = SKSpriteNode(imageNamed: "CompanionPoseSleeping")
    private let bowPose = SKSpriteNode(imageNamed: "CompanionPoseLightsBow")
    private let floe = SKSpriteNode(imageNamed: "CompanionFloe")
    private let bucket = SKSpriteNode(imageNamed: "CompanionBucket")
    private let catchSprite = SKSpriteNode(imageNamed: "CompanionFish")
    private let sleepMarks = SKSpriteNode(imageNamed: "CompanionSleepMarks")
    private let biteMark = SKSpriteNode(imageNamed: "CompanionBite")
    private let splash = SKSpriteNode(imageNamed: "CompanionSplash")
    private let line = SKShapeNode()
    private let fishTexture = SKTexture(imageNamed: "CompanionFish")
    private let sleepTexture = SKTexture(imageNamed: "CompanionPoseSleeping")
    private let hopTexture = SKTexture(imageNamed: "CompanionPoseHop")
    private let lightsUpTexture = SKTexture(imageNamed: "CompanionPoseLightsUp")
    private let lightsBowTexture = SKTexture(imageNamed: "CompanionPoseLightsBow")
    private let completeTexture = SKTexture(imageNamed: "CompanionPoseCompleted")
    private var steamPuffs: [SKShapeNode] = []
    private var distractionVisual: DistractionVisualState?
    private var lastTime: TimeInterval?
    private var motionTime: TimeInterval = 0
    private var built = false

    override init() {
        super.init(size: Self.stageSize)
        backgroundColor = .clear
        scaleMode = .aspectFit
        self.buildScene()
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func startSession() {
        self.playback.start()
        self.distractionVisual = nil
        self.lastTime = nil
        self.motionTime = 0
        isPaused = false
        self.render()
    }

    func setSessionPaused(_ value: Bool) {
        self.playback.setPaused(value); self.render()
    }

    func setDistracted(_ value: Bool) {
        if !value { self.distractionVisual = nil }
        self.playback.setDistracted(value); self.render()
    }

    func setDistractionVisual(_ visual: DistractionVisualState?) {
        self.distractionVisual = visual
        self.playback.setDistracted(visual != nil)
        self.render()
    }

    func completeSession() {
        self.playback.complete(); self.render()
    }

    func stopSession(activeSeconds: TimeInterval) {
        self.playback.stop(activeSeconds: activeSeconds); self.render()
    }

    func biteNow() {
        self.playback.biteNow(); self.render()
    }

    func shutDown() {
        self.onHidden = nil
        self.distractionVisual = nil
        self.playback.dismiss()
        isPaused = true
        self.lastTime = nil
    }

    override func update(_ currentTime: TimeInterval) {
        defer { lastTime = currentTime }
        guard let lastTime else { self.render(); return }
        // Don't fast-forward visual catches after a suspended/hidden app or display sleep.
        self.advanceAnimation(by: min(0.1, max(0, currentTime - lastTime)))
    }

    /// Also used by the deterministic visual verification harness.
    func advanceAnimation(by delta: TimeInterval) {
        let previous = self.playback.phase
        self.playback.advance(by: delta)
        self.motionTime += delta
        self.render()
        if previous != .hidden, self.playback.phase == .hidden { self.onHidden?() }
    }

    private func configure(
        _ sprite: SKSpriteNode, size: CGSize, position: CGPoint, z: CGFloat, parent: SKNode? = nil)
    {
        sprite.size = size
        sprite.position = position
        sprite.zPosition = z
        sprite.texture?.filteringMode = .linear
        (parent ?? self).addChild(sprite)
    }

    private func buildScene() {
        guard !self.built else { return }
        self.built = true
        self.floe.name = "floe"
        self.bucket.name = "bucket"
        self.catchSprite.name = "catch"
        self.configure(self.floe, size: CGSize(width: 118, height: 52), position: CGPoint(x: 70, y: 30), z: 0)
        self.configure(self.bucket, size: CGSize(width: 25, height: 26), position: CGPoint(x: 113, y: 47), z: 12)
        self.puppet.position = CGPoint(x: 65, y: 47)
        self.puppet.zPosition = 3
        addChild(self.puppet)
        self.configure(self.feet, size: CGSize(width: 43, height: 8), position: .zero, z: 5, parent: self.puppet)
        self.configure(
            self.torso,
            size: CGSize(width: 45, height: 34),
            position: CGPoint(x: 0, y: 17.5),
            z: 1,
            parent: self.puppet)
        self.configure(
            self.head,
            size: CGSize(width: 46, height: 41),
            position: CGPoint(x: 0, y: 31),
            z: 3,
            parent: self.puppet)
        self.head.anchorPoint = CGPoint(x: 0.5, y: 0.15)
        self.configure(
            self.leftFlipper,
            size: CGSize(width: 14, height: 27),
            position: CGPoint(x: -19, y: 33),
            z: 4,
            parent: self.puppet)
        self.configure(
            self.rightFlipper,
            size: CGSize(width: 14, height: 29),
            position: CGPoint(x: 19, y: 33),
            z: 7,
            parent: self.puppet)
        self.leftFlipper.anchorPoint = CGPoint(x: 0.65, y: 0.88)
        self.rightFlipper.anchorPoint = CGPoint(x: 0.25, y: 0.9)
        self.configure(
            self.rod,
            size: CGSize(width: 46, height: 43),
            position: CGPoint(x: 6, y: 14),
            z: 6,
            parent: self.puppet)
        self.rod.anchorPoint = CGPoint(x: 0.95, y: 0.05)
        self.configure(self.restingPose, size: CGSize(width: 130, height: 130), position: CGPoint(x: 65, y: 47), z: 4)
        self.restingPose.anchorPoint = CGPoint(x: 0.5, y: 62.0 / 512)
        self.configure(self.bowPose, size: CGSize(width: 130, height: 130), position: CGPoint(x: 65, y: 47), z: 5)
        self.bowPose.anchorPoint = self.restingPose.anchorPoint
        self.bowPose.texture = self.lightsBowTexture
        self.bowPose.isHidden = true
        for index in 0..<3 {
            let puff = SKShapeNode(ellipseOf: CGSize(width: 5 + CGFloat(index), height: 4 + CGFloat(index)))
            puff.fillColor = NSColor(white: 0.36, alpha: 0.65)
            puff.strokeColor = NSColor(white: 0.24, alpha: 0.7)
            puff.lineWidth = 0.6
            puff.zPosition = 11
            puff.isHidden = true
            addChild(puff)
            self.steamPuffs.append(puff)
        }
        self.configure(self.catchSprite, size: CGSize(width: 10, height: 6), position: .zero, z: 10)
        self.configure(self.sleepMarks, size: CGSize(width: 16, height: 12), position: CGPoint(x: 103, y: 66), z: 10)
        self.configure(self.biteMark, size: CGSize(width: 4, height: 10), position: CGPoint(x: 82, y: 122), z: 10)
        self.configure(self.splash, size: CGSize(width: 10, height: 8), position: CGPoint(x: 20, y: 32), z: 1)
        self.line.strokeColor = NSColor(white: 0.22, alpha: 0.8)
        self.line.lineWidth = 0.55
        self.line.zPosition = 2
        addChild(self.line)
        self.render()
    }

    private func render() {
        guard self.built else { return }
        let phase = self.playback.phase
        let progress = CGFloat(playback.progress)
        let time = CGFloat(playback.phaseTime)
        let breath = self.reduceMotion ? 0 : sin(CGFloat(self.motionTime) * 1.6)
        let active = phase != .hidden
        self.floe.isHidden = !active
        self.bucket.isHidden = !active
        self.puppet.isHidden = !active
        self.puppet.position = CGPoint(x: 65, y: 47)
        self.puppet.zRotation = 0
        self.puppet.setScale(1)
        self.torso.yScale = 1 + breath * 0.012
        self.head.position = CGPoint(x: 0, y: 31 + breath * 0.35)
        self.head.zRotation = breath * 0.012
        self.leftFlipper.zRotation = -0.7 + breath * 0.018
        self.rightFlipper.zRotation = -0.95 + breath * 0.022
        self.rod.zRotation = 0.35 + breath * 0.013
        self.rod.isHidden = false
        self.restingPose.isHidden = true
        self.restingPose.position = CGPoint(x: 65, y: 47)
        self.restingPose.zRotation = 0
        self.restingPose.alpha = 1
        self.restingPose.setScale(1)
        self.bowPose.isHidden = true
        self.bowPose.position = self.restingPose.position
        self.bowPose.alpha = 0
        self.steamPuffs.forEach { $0.isHidden = true }
        self.sleepMarks.isHidden = true
        self.biteMark.isHidden = phase != .bite
        self.splash.isHidden = true
        self.catchSprite.isHidden = true
        self.catchSprite.alpha = 1
        self.catchSprite.zRotation = 0
        self.catchSprite.setScale(1)
        self.catchSprite.texture = self.fishTexture
        self.catchSprite.size = CGSize(width: 11, height: 6)
        var waterPoint = CGPoint(x: 20, y: 31)
        self.line.isHidden = !active

        switch phase {
        case .hidden:
            self.puppet.isHidden = true
        case .starting:
            self.rod.isHidden = true
            self.line.isHidden = true
            if !self.reduceMotion {
                self.puppet.position.x -= (1 - self.smooth(progress)) * 23
                self.puppet.position.y += sin(progress * .pi) * 12
            }
        case .casting:
            if !self.reduceMotion {
                self.rod.zRotation = -0.13 + 0.48 * self.smooth(progress) - sin(progress * .pi) * 0.9
                self.rightFlipper.zRotation = -1.2 + 0.25 * self.smooth(progress) - sin(progress * .pi) * 0.3
                self.head.zRotation = -0.06 * (1 - self.smooth(progress)) - sin(progress * .pi) * 0.04
                waterPoint = self.mix(CGPoint(x: 46, y: 72), waterPoint, self.smooth(progress))
            }
        case .fishing: break
        case .bite:
            if !self.reduceMotion {
                self.rod.zRotation = 0.35 + sin(progress * .pi) * 0.1
                self.head.zRotation = -0.06
            }
            self.splash.isHidden = self.reduceMotion
        case .pulling:
            waterPoint = self.renderPull(progress: progress, time: time, waterPoint: waterPoint)
        case .deposit:
            waterPoint = self.renderDeposit(progress: progress)
        case .sleeping:
            self.showPose(self.sleepTexture)
            if !self.reduceMotion { self.restingPose.yScale = 1 + breath * 0.01 }
            self.sleepMarks.isHidden = false
            self.sleepMarks.position = CGPoint(x: 101, y: 65 + (self.reduceMotion ? 0 : sin(time * 1.4) * 1.4))
            self.sleepMarks.alpha = self.reduceMotion ? 0.7 : 0.65 + 0.2 * sin(time * 1.4)
        case .distracted:
            self.renderDistraction(time: time)
        case .completed:
            self.showPose(self.completeTexture)
            if !self.reduceMotion { self.restingPose.yScale = 1 + breath * 0.006 }
        case .releasing:
            self.renderRelease(progress: progress)
        }

        if !self.line.isHidden {
            let tip = self.rod.convert(CGPoint(x: -self.rod.size.width * 0.9, y: self.rod.size.height * 0.9), to: self)
            let path = CGMutablePath()
            path.move(to: tip)
            path.addQuadCurve(to: waterPoint, control: CGPoint(x: tip.x - 2, y: (tip.y + waterPoint.y) / 2))
            self.line.path = path
        }
    }

    private func renderPull(progress: CGFloat, time: CGFloat, waterPoint: CGPoint) -> CGPoint {
        if !self.reduceMotion {
            let tug = sin(time * 7) * 0.025
            self.puppet.zRotation = -0.045 * self.smooth(progress) + tug
            self.rod.zRotation = 0.35 - 0.48 * self.smooth(progress) + tug
            self.rightFlipper.zRotation -= 0.25 * self.smooth(progress)
            self.head.zRotation = 0.045
        }
        guard progress > 0.65 else { return waterPoint }
        let rise = self.smooth((progress - 0.65) / 0.35)
        let point = self.reduceMotion ? CGPoint(x: 29, y: 86) : self.mix(waterPoint, CGPoint(x: 29, y: 86), rise)
        self.catchSprite.isHidden = false
        self.catchSprite.position = point
        if self.reduceMotion { self.catchSprite.alpha = rise }
        return point
    }

    private func renderDistraction(time: CGFloat) {
        switch self.distractionVisual?.effect ?? .iceFlower {
        case .iceFlower:
            self.showPose(self.hopTexture)
            if !self.reduceMotion {
                let hop = max(0, sin(time * .pi * 1.7))
                self.restingPose.position.y += hop * 8
                self.restingPose.zRotation = sin(time * 3.1) * 0.025
            }
            for (index, puff) in self.steamPuffs.enumerated() {
                let travel = self.reduceMotion
                    ? 0 : (time * 15 + CGFloat(index) * 5).truncatingRemainder(dividingBy: 17)
                puff.position = CGPoint(
                    x: 58 + CGFloat(index) * 10 + (self.reduceMotion ? 0 : sin(time * 2 + CGFloat(index)) * 2),
                    y: 113 + travel)
                puff.alpha = self.reduceMotion ? 0.55 : 0.72 * (1 - travel / 19)
                puff.isHidden = false
            }
        case .dimBright:
            self.showPose(self.lightsUpTexture)
            let elapsed = Date().timeIntervalSince(self.distractionVisual?.startedAt ?? Date())
            let strength: CGFloat = self.reduceMotion
                ? 0.55 : CGFloat(DistractionMotion.dimStrength(elapsed: elapsed))
            self.restingPose.alpha = 1 - strength
            self.bowPose.alpha = strength
            self.bowPose.isHidden = false
        }
    }

    private func renderDeposit(progress: CGFloat) -> CGPoint {
        self.catchSprite.isHidden = false
        self.catchSprite.position = self.quadratic(
            CGPoint(x: 29, y: 86), CGPoint(x: 81, y: 175), CGPoint(x: 113, y: 52), progress)
        self.catchSprite.zRotation = self.reduceMotion ? 0 : -progress * 0.5
        // Bucket z-order occludes the catch only as it lands.
        if !self.reduceMotion {
            self.rod.zRotation = -0.13 - sin(progress * .pi) * 0.6
            self.rightFlipper.zRotation = -1.2 - sin(progress * .pi) * 0.3
            self.head.zRotation = -0.06 * progress
        } else {
            self.catchSprite.position = CGPoint(x: 113, y: 60)
            self.catchSprite.alpha = 1 - progress
        }
        return self.catchSprite.position
    }

    private func renderRelease(progress: CGFloat) {
        self.showPose(self.completeTexture)
        guard self.playback.releasedCatches > 0 else { return }
        self.catchSprite.isHidden = false
        self.catchSprite.texture = self.fishTexture
        self.catchSprite.position = self.quadratic(
            CGPoint(x: 113, y: 57), CGPoint(x: 68, y: 89), CGPoint(x: 20, y: 30), progress)
        self.catchSprite.alpha = progress > 0.8 ? (1 - progress) / 0.2 : 1
        if self.reduceMotion {
            self.catchSprite.position = CGPoint(x: 20, y: 30)
            self.catchSprite.alpha = 1 - progress
        }
        self.splash.isHidden = self.reduceMotion || progress < 0.8
    }

    private func showPose(_ texture: SKTexture) {
        self.puppet.isHidden = true
        self.line.isHidden = true
        self.restingPose.isHidden = false
        self.restingPose.texture = texture
    }

    private func smooth(_ value: CGFloat) -> CGFloat {
        value * value * (3 - 2 * value)
    }

    private func mix(_ first: CGPoint, _ second: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: first.x + (second.x - first.x) * t, y: first.y + (second.y - first.y) * t)
    }

    private func quadratic(_ start: CGPoint, _ control: CGPoint, _ end: CGPoint, _ t: CGFloat) -> CGPoint {
        let first = self.mix(start, control, t)
        let second = self.mix(control, end, t)
        return self.mix(first, second, t)
    }
}
