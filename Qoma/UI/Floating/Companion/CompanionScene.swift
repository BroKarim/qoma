import AppKit
import SpriteKit

/// Whole pixel-art poses keep the face and belly continuous at desktop scale.
final class CompanionScene: SKScene {
    static let stageSize = CGSize(width: 164, height: 180)
    private(set) var playback = CompanionPlayback()
    var onHidden: (() -> Void)?
    var reduceMotion = false { didSet { render() } }
    var visualNow: () -> Date = Date.init

    // Contact and ripple locations are measured on the combined ice/water artwork.
    private let seatedOrigin = CGPoint(x: 72, y: 27)
    private var waterPoint: CGPoint {
        actors.convert(CGPoint(x: 63.95, y: 55.85), from: self)
    }
    private let bucketOrigin = CGPoint(x: 119, y: 38)
    private let characterHeight: CGFloat = 100
    private let character = SKSpriteNode()
    private let floe = SKSpriteNode(imageNamed: "PixelIslandV1")
    private let actors = SKNode()
    private let swimmingFish = (0..<3).map { _ in SKSpriteNode(imageNamed: "PixelWaterFishV1") }
    private let bucket = SKSpriteNode(imageNamed: "PixelBucketV1")
    private let catchSprite = SKSpriteNode()
    private let splash = SKSpriteNode(imageNamed: "PixelSplashV1")
    private let sleepMarks = SKSpriteNode(imageNamed: "PixelSleepV1")
    private let line = SKShapeNode()
    private var distractionVisual: DistractionVisualState?
    private var lastTime: TimeInterval?
    private var motionTime: TimeInterval = 0
    private var ambientTime: TimeInterval = 0
    private let ripple = SKShapeNode(ellipseOf: CGSize(width: 16, height: 5))
    private let snow = (0..<12).map { _ in SKSpriteNode(color: .white, size: CGSize(width: 1, height: 1)) }
    private var snowySession = false
    private var atmosphereID = ""
    private var visitors = CoveVisitorSchedule()
    private let visitor = SKNode()
    private var displayedVisitor: CoveVisitorSchedule.Kind?

    // Pixel rectangles include the complete rod, including the deposit pose's tip.
    // Coordinates are top-left image pixels; SpriteKit texture rectangles use bottom-left UVs.
    private let poses: [SKTexture] = {
        let atlas = SKTexture(imageNamed: "PixelPosesV2")
        let rectangles = [
            CGRect(x: 0, y: 0, width: 512, height: 512),
            CGRect(x: 512, y: 0, width: 512, height: 512),
            CGRect(x: 1024, y: 0, width: 512, height: 512),
            CGRect(x: 0, y: 512, width: 512, height: 512),
            CGRect(x: 512, y: 512, width: 532, height: 512),
            CGRect(x: 1044, y: 512, width: 492, height: 512),
        ]
        return rectangles.map { rect in
            let texture = SKTexture(rect: CGRect(
                x: rect.minX / 1536, y: 1 - rect.maxY / 1024,
                width: rect.width / 1536, height: rect.height / 1024), in: atlas)
            texture.filteringMode = .nearest
            return texture
        }
    }()
    private let catches: [SKTexture] = {
        let atlas = SKTexture(imageNamed: "PixelCatchesV1")
        return (0..<4).map { index in
            let texture = SKTexture(rect: CGRect(x: CGFloat(index) / 4, y: 0, width: 0.25, height: 1), in: atlas)
            texture.filteringMode = .nearest
            return texture
        }
    }()

    private let catchFrames: [SKTexture] = {
        let atlas = SKTexture(imageNamed: "PixelCatchV2")
        return (0..<12).map { index in
            let texture = SKTexture(rect: CGRect(
                x: CGFloat(index % 4) / 4, y: CGFloat(2 - index / 4) / 3,
                width: 0.25, height: 1.0 / 3), in: atlas)
            texture.filteringMode = .nearest
            return texture
        }
    }()
    private let catchFrameOrder = [0, 1, 2, 4, 5, 3, 6, 7, 8, 9, 10, 11]
    // Each painted cell has a different margin; align the feet, not the cell edges.
    private let catchAnchors: [CGPoint] = [
        CGPoint(x: 0.604, y: 0.073), CGPoint(x: 0.605, y: 0.073),
        CGPoint(x: 0.578, y: 0.073), CGPoint(x: 0.600, y: 0.073),
        CGPoint(x: 0.617, y: 0.147), CGPoint(x: 0.613, y: 0.147),
        CGPoint(x: 0.591, y: 0.144), CGPoint(x: 0.604, y: 0.147),
        CGPoint(x: 0.604, y: 0.211), CGPoint(x: 0.604, y: 0.211),
        CGPoint(x: 0.598, y: 0.211), CGPoint(x: 0.600, y: 0.211),
    ]
    private let catchRodTips: [CGPoint] = [
        CGPoint(x: 0.26, y: 0.736), CGPoint(x: 0.266, y: 0.707),
        CGPoint(x: 0.188, y: 0.590), CGPoint(x: 0.242, y: 0.724),
        CGPoint(x: 0.221, y: 0.768), CGPoint(x: 0.211, y: 0.745),
        CGPoint(x: 0.227, y: 0.800), CGPoint(x: 0.229, y: 0.798),
        CGPoint(x: 0.242, y: 0.877), CGPoint(x: 0.247, y: 0.877),
        CGPoint(x: 0.242, y: 0.874), CGPoint(x: 0.242, y: 0.874),
    ]

    private let castFrames = CompanionScene.fishingTextures(named: "PixelCastV2")
    private let depositFrames: [SKTexture] = {
        let atlas = SKTexture(imageNamed: "PixelDepositV2")
        return (0..<12).map { index in
            // Keep the long right-facing rod in cell 6 out of the neighboring cell 7.
            let offset: CGFloat = index == 7 ? 28 : 0
            let width: CGFloat = index == 6 ? 416 : (index == 7 ? 356 : 384)
            let texture = SKTexture(rect: CGRect(
                x: (CGFloat(index % 4) * 384 + offset) / 1536,
                y: CGFloat(2 - index / 4) / 3, width: width / 1536, height: 1.0 / 3), in: atlas)
            texture.filteringMode = .nearest
            return texture
        }
    }()
    private let castAlignment: [(anchor: CGPoint, height: CGFloat)] = [
        (CGPoint(x: 0.603, y: 0.023), 103.783), (CGPoint(x: 0.618, y: 0.026), 104.236),
        (CGPoint(x: 0.574, y: 0.023), 102.888), (CGPoint(x: 0.595, y: 0.023), 103.783),
        (CGPoint(x: 0.607, y: 0.067), 103.783), (CGPoint(x: 0.630, y: 0.062), 105.619),
        (CGPoint(x: 0.620, y: 0.067), 102.888), (CGPoint(x: 0.589, y: 0.065), 100.717),
        (CGPoint(x: 0.637, y: 0.132), 102.009), (CGPoint(x: 0.632, y: 0.132), 101.574),
        (CGPoint(x: 0.577, y: 0.132), 101.144), (CGPoint(x: 0.607, y: 0.132), 102.009),
    ]
    private let depositAlignment: [(anchor: CGPoint, height: CGFloat)] = [
        (CGPoint(x: 0.591, y: 0.038), 120.556), (CGPoint(x: 0.574, y: 0.038), 112.594),
        (CGPoint(x: 0.569, y: 0.038), 116.439), (CGPoint(x: 0.557, y: 0.038), 116.439),
        (CGPoint(x: 0.514, y: 0.097), 111.023), (CGPoint(x: 0.521, y: 0.097), 111.542),
        (CGPoint(x: 0.445, y: 0.094), 115.874), (CGPoint(x: 0.335, y: 0.094), 117.010),
        (CGPoint(x: 0.589, y: 0.185), 114.211), (CGPoint(x: 0.573, y: 0.185), 113.667),
        (CGPoint(x: 0.553, y: 0.185), 114.211), (CGPoint(x: 0.548, y: 0.185), 114.760),
    ]
    private let castTips: [CGPoint] = [
        CGPoint(x: 0.169, y: 0.719), CGPoint(x: 0.221, y: 0.719),
        CGPoint(x: 0.323, y: 0.862), CGPoint(x: 0.464, y: 0.812),
        CGPoint(x: 0.503, y: 0.900), CGPoint(x: 0.438, y: 0.900),
        CGPoint(x: 0.122, y: 0.821), CGPoint(x: 0.151, y: 0.821),
        CGPoint(x: 0.091, y: 0.736), CGPoint(x: 0.232, y: 0.877),
        CGPoint(x: 0.216, y: 0.883), CGPoint(x: 0.219, y: 0.874),
    ]
    private let depositTips: [CGPoint] = [
        CGPoint(x: 0.247, y: 0.663), CGPoint(x: 0.263, y: 0.751),
        CGPoint(x: 0.357, y: 0.853), CGPoint(x: 0.391, y: 0.877),
        CGPoint(x: 0.924, y: 0.809), CGPoint(x: 0.935, y: 0.780),
        CGPoint(x: 0.978, y: 0.592), CGPoint(x: 0.871, y: 0.416),
        CGPoint(x: 0.286, y: 0.871), CGPoint(x: 0.276, y: 0.871),
        CGPoint(x: 0.232, y: 0.868), CGPoint(x: 0.216, y: 0.853),
    ]
    // Compress only the rod's outer margin; keep the seated body at its calibrated size.
    private static let shortenedRod = SKWarpGeometryGrid(columns: 2, rows: 1,
        sourcePositions: [SIMD2<Float>(0, 0), SIMD2<Float>(0.7, 0), SIMD2<Float>(1, 0),
                          SIMD2<Float>(0, 1), SIMD2<Float>(0.7, 1), SIMD2<Float>(1, 1)],
        destinationPositions: [SIMD2<Float>(0, 0), SIMD2<Float>(0.7, 0), SIMD2<Float>(0.9, 0),
                               SIMD2<Float>(0, 1), SIMD2<Float>(0.7, 1), SIMD2<Float>(0.9, 1)])

    private static func fishingTextures(named name: String) -> [SKTexture] {
        let atlas = SKTexture(imageNamed: name)
        return (0..<12).map { index in
            let texture = SKTexture(rect: CGRect(
                x: CGFloat(index % 4) / 4, y: CGFloat(2 - index / 4) / 3,
                width: 0.25, height: 1.0 / 3), in: atlas)
            texture.filteringMode = .nearest
            return texture
        }
    }

    private static let distractionFrames = fishingTextures(named: "PixelHopV2")

    init(playback: CompanionPlayback = CompanionPlayback()) {
        self.playback = playback
        super.init(size: Self.stageSize)
        backgroundColor = .clear
        scaleMode = .aspectFit
        // Keep the reference's 58 pt painted body; all fishing paths share this transform.
        actors.setScale(0.45)
        actors.position = CGPoint(x: 64, y: 45)
        addChild(actors)
        configure(floe, name: "floe", size: CGSize(width: 164, height: 164), position: CGPoint(x: 82, y: 82), z: 0)
        floe.removeFromParent()
        addChild(floe)
        ripple.strokeColor = NSColor.white.withAlphaComponent(0.5)
        ripple.lineWidth = 0.5
        ripple.zPosition = 2
        addChild(ripple)
        visitor.zPosition = 4
        addChild(visitor)
        for flake in snow { flake.zPosition = 20; addChild(flake) }
        for (index, fish) in swimmingFish.enumerated() {
            configure(fish, name: "swimmingFish-\(index)", size: CGSize(width: 13, height: 8), position: .zero, z: 1)
            fish.removeFromParent()
            addChild(fish)
            fish.alpha = 0.45
        }
        configure(bucket, name: "bucket", size: CGSize(width: 22, height: 23), position: bucketOrigin, z: 12)
        configure(character, name: "character", size: CGSize(width: characterHeight, height: characterHeight), position: seatedOrigin, z: 3)
        character.anchorPoint = CGPoint(x: 0.6, y: 0.07)
        configure(catchSprite, name: "catch", size: CGSize(width: 23, height: 31), position: .zero, z: 10)
        configure(splash, name: "splash", size: CGSize(width: 16, height: 10), position: waterPoint, z: 2)
        configure(sleepMarks, name: "sleep", size: CGSize(width: 16, height: 12), position: CGPoint(x: 94, y: 94), z: 10)
        line.strokeColor = NSColor(white: 0.22, alpha: 0.8)
        line.lineWidth = 0.6
        line.zPosition = 2
        actors.addChild(line)
        render()
    }

    required init?(coder: NSCoder) { nil }

    func startSession() {
        playback.start()
        distractionVisual = nil
        lastTime = nil
        motionTime = 0
        snowySession = Bool.random()
        visitors = CoveVisitorSchedule()
        isPaused = false
        render()
    }
    func setSessionPaused(_ value: Bool) { playback.setPaused(value); render() }
    func setDistracted(_ value: Bool) {
        if !value { distractionVisual = nil }
        playback.setDistracted(value)
        render()
    }
    func setDistractionVisual(_ visual: DistractionVisualState?) {
        distractionVisual = visual
        playback.setDistracted(visual != nil)
        render()
    }
    func completeSession() { playback.complete(); render() }
    func recordCatch(kindID: String) {
        // Persisted rewards keep their own accounting; decorative objects never award items.
        playback.recordCatch(kindID: kindID)
        render()
    }
    func stopSession(activeSeconds: TimeInterval) { playback.stop(activeSeconds: activeSeconds); render() }
    func biteNow() { playback.biteNow(); render() }
    func shutDown() {
        onHidden = nil
        distractionVisual = nil
        playback.dismiss()
        isPaused = true
        lastTime = nil
        render()
    }
    override func update(_ currentTime: TimeInterval) {
        defer { lastTime = currentTime }
        guard let lastTime else { render(); return }
        advanceAnimation(by: min(0.1, max(0, currentTime - lastTime)))
    }
    func advanceAnimation(by delta: TimeInterval) {
        guard delta.isFinite, delta > 0 else { return }
        let previous = playback.phase
        playback.advance(by: delta)
        if playback.phase != .sleeping { motionTime += delta }
        if playback.phase != .hidden { ambientTime += delta }
        visitors.advance(by: delta, active: playback.isSessionActive && !playback.isPaused,
                         canArrive: playback.phase == .fishing)
        render()
        if previous != .hidden, playback.phase == .hidden { onHidden?() }
    }

    private func configure(_ node: SKSpriteNode, name: String, size: CGSize, position: CGPoint, z: CGFloat) {
        node.name = name
        node.size = size
        node.position = position
        node.zPosition = z
        node.texture?.filteringMode = .nearest
        actors.addChild(node)
    }

    private func render() {
        let phase = playback.phase
        let p = CGFloat(playback.progress)
        let t = CGFloat(playback.phaseTime)
        let breath: CGFloat = 0
        let active = phase != .hidden
        for (index, fish) in swimmingFish.enumerated() {
            let time = reduceMotion ? 0 : CGFloat(motionTime)
            let angle = time * (0.32 + CGFloat(index) * 0.05) + CGFloat(index) * 2.1
            // The whole sprite stays within the open lower lagoon, below the snowy shelf.
            fish.position = CGPoint(x: 65 + cos(angle) * (14 + CGFloat(index) * 2),
                                    y: 37 + CGFloat(index) * 3 + sin(angle * 2) * 1.5)
            fish.xScale = reduceMotion ? 1 : tanh(sin(angle) * 5)
            fish.yScale = 1 + (reduceMotion ? 0 : sin(time * 2.5 + CGFloat(index)) * 0.04)
            fish.zRotation = reduceMotion ? 0 : cos(angle) * 0.07
            fish.isHidden = !active
        }
        floe.isHidden = !active
        bucket.isHidden = !active
        character.isHidden = !active
        character.warpGeometry = nil
        floe.alpha = 1
        bucket.alpha = 1
        bucket.setScale(1)
        character.alpha = 1
        character.position = seatedOrigin
        character.zRotation = 0
        character.xScale = 1 - breath * 0.004
        character.yScale = 1 + breath * 0.012
        catchSprite.isHidden = true
        catchSprite.alpha = 1
        catchSprite.zRotation = 0
        catchSprite.texture = catches[playback.completedVisualCatches % catches.count]
        splash.isHidden = true
        splash.position = waterPoint
        splash.alpha = 1
        sleepMarks.isHidden = true
        line.isHidden = !active
        var pose = 0
        var endpoint = waterPoint

        switch phase {
        case .hidden: break
        case .starting:
            line.isHidden = true
            if !reduceMotion {
                let settled = smooth(p)
                floe.alpha = smooth(min(1, p * 3))
                bucket.alpha = floe.alpha
                character.alpha = smooth(min(1, p * 2))
                character.position.x -= 12 * (1 - settled)
                character.position.y += sin(p * .pi) * 4
                character.yScale = 0.96 + 0.04 * settled
            }
        case .casting:
            if !reduceMotion {
                character.zRotation = sin(p * .pi) * 0.025
                if p < 0.45 { line.isHidden = true }
                endpoint = quadratic(CGPoint(x: 82, y: 103), CGPoint(x: 7, y: 100), waterPoint,
                                     smooth(min(1, max(0, (p - 0.45) / 0.55))))
                splash.isHidden = p < 0.85
                splash.alpha = sin(max(0, (p - 0.85) / 0.15) * .pi)
            }
        case .fishing:
            break
        case .bite:
            pose = 1
            if !reduceMotion {
                character.position.x -= sin(p * .pi) * 3
                character.yScale = 1 - sin(p * .pi) * 0.045
                splash.isHidden = false
            }
        case .pulling:
            // Anticipation → effort → reveal → a held, happy reward beat.
            if !reduceMotion {
                let effort = sin(min(1, p / 0.62) * .pi)
                character.zRotation = -0.025 * effort
                character.position.x += 1.2 * effort
                character.yScale = 1 - 0.035 * effort
                if p >= 0.62 {
                    let bounce = (p - 0.62) / 0.38
                    character.position.y += max(0, sin(bounce * 2 * .pi)) * 4
                }
            }
            if p >= 0.35 {
                let rise = smooth(min(1, (p - 0.35) / 0.25))
                endpoint = reduceMotion ? CGPoint(x: 24, y: 84) : mix(endpoint, CGPoint(x: 24, y: 84), rise)
                catchSprite.isHidden = false
                catchSprite.position = endpoint
                catchSprite.zRotation = reduceMotion ? 0 : sin(t * 5) * 0.12 * rise
                splash.isHidden = reduceMotion || p > 0.65
                splash.alpha = 1 - rise
            }
        case .deposit:
            catchSprite.isHidden = p >= 0.78
            let overhead = CGPoint(x: 24, y: 122)
            let landing = CGPoint(x: bucketOrigin.x, y: bucketOrigin.y - 1)
            if p < 0.25 {
                endpoint = mix(CGPoint(x: 24, y: 84), overhead, smooth(p / 0.25))
            } else if p < 0.5 {
                line.isHidden = true
                endpoint = mix(overhead, CGPoint(x: bucketOrigin.x, y: overhead.y), smooth((p - 0.25) / 0.25))
            } else {
                // Release above the head before the catch drops into the bucket.
                line.isHidden = true
                endpoint = mix(CGPoint(x: bucketOrigin.x, y: overhead.y), landing,
                               smooth(min(1, (p - 0.5) / 0.25)))
            }
            catchSprite.position = endpoint
            if reduceMotion {
                catchSprite.position = CGPoint(x: bucketOrigin.x, y: bucketOrigin.y + 11)
                catchSprite.alpha = 1 - p
            } else {
                character.zRotation = -sin(p * .pi) * 0.02
                catchSprite.zRotation = -p * 0.25
                let landingBounce = p > 0.7 ? sin(min(1, (p - 0.7) / 0.3) * .pi) : 0
                bucket.xScale = 1 + landingBounce * 0.035
                bucket.yScale = 1 - landingBounce * 0.035
            }
        case .sleeping:
            pose = 5
            line.isHidden = true
            sleepMarks.isHidden = false
            sleepMarks.alpha = reduceMotion ? 0.7 : 0.65 + 0.2 * sin(t * 1.4)
        case .distracted:
            line.isHidden = true
        case .completed:
            pose = 3
            line.isHidden = true
        case .releasing:
            pose = 4
            line.isHidden = true
            if playback.releasedCatches > 0 {
                catchSprite.isHidden = false
                catchSprite.position = reduceMotion ? waterPoint
                    : quadratic(CGPoint(x: bucketOrigin.x, y: bucketOrigin.y + 9), CGPoint(x: 68, y: 89), waterPoint, p)
                catchSprite.alpha = 1 - p
            }
        }
        character.texture = poses[pose]
        let width = characterHeight * (pose == 4 ? 532.0 / 512 : (pose == 5 ? 492.0 / 512 : 1))
        character.size = CGSize(width: width, height: characterHeight)
        if phase == .distracted {
            let effect = distractionVisual?.effect ?? .iceFlower
            let elapsed = distractionVisual.map { visualNow().timeIntervalSince($0.startedAt) } ?? playback.phaseTime
            character.size = CGSize(width: 128, height: 128)
            character.anchorPoint = CGPoint(x: 0.5, y: 20.0 / 256)
            let frame = DistractionMotion.penguinFrame(effect: effect, elapsed: elapsed, reduceMotion: reduceMotion)
            character.texture = Self.distractionFrames[frame]
            character.position.y += CGFloat(DistractionMotion.penguinLift(
                effect: effect, elapsed: elapsed, reduceMotion: reduceMotion))
        } else {
            character.anchorPoint = CGPoint(x: 0.6, y: 0.07)
        }
        var paintedRodTip: CGPoint?
        switch phase {
        case .starting, .fishing, .bite, .pulling, .completed:
            let frame = catchFrameOrder[reduceMotion ? 0 : playback.catchFrame]
            character.texture = catchFrames[frame]
            character.size = CGSize(width: 128, height: 1024.0 / 9)
            character.anchorPoint = catchAnchors[frame]
            paintedRodTip = catchRodTips[frame]
        case .casting:
            let order = [11, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
            let frame = order[reduceMotion ? 0 : playback.movementFrame]
            let alignment = castAlignment[frame]
            character.texture = castFrames[frame]
            character.size = CGSize(width: alignment.height * 1.125, height: alignment.height)
            character.anchorPoint = alignment.anchor
            paintedRodTip = castTips[frame]
        case .deposit, .releasing:
            let frame = reduceMotion ? 0 : (phase == .releasing ? 11 - playback.movementFrame : playback.movementFrame)
            let alignment = depositAlignment[frame]
            let cellWidth: CGFloat = frame == 6 ? 416 : (frame == 7 ? 356 : 384)
            character.texture = depositFrames[frame]
            character.size = CGSize(width: alignment.height * cellWidth / (1024.0 / 3), height: alignment.height)
            character.anchorPoint = alignment.anchor
            paintedRodTip = depositTips[frame]
            if frame == 6 || frame == 7 { character.warpGeometry = Self.shortenedRod }
        default: break
        }
        if !line.isHidden {
            // Rod-tip locations measured inside each atlas cell, in normalized bottom-left coordinates.
            let tips: [CGPoint] = [CGPoint(x: 0.17, y: 0.73), CGPoint(x: 0.10, y: 0.45),
                                   CGPoint(x: 0.10, y: 0.85), CGPoint(x: 0.13, y: 0.93),
                                   CGPoint(x: 0.95, y: 0.86), .zero]
            let normalizedTip = paintedRodTip ?? tips[pose]
            let tip = character.convert(CGPoint(
                x: (normalizedTip.x - character.anchorPoint.x) * character.size.width,
                y: (normalizedTip.y - character.anchorPoint.y) * character.size.height), to: actors)
            let path = CGMutablePath()
            path.move(to: tip)
            path.addQuadCurve(to: endpoint, control: CGPoint(x: tip.x, y: (tip.y + endpoint.y) / 2))
            line.path = path
        }
        // Painted animation already contains body motion; keep the feet and pixel proportions stable.
        character.zRotation = 0
        character.xScale = 1
        character.yScale = 1
        if phase != .distracted { character.position = seatedOrigin }
        updateEnvironment(active: active)
        updateVisitor(active: active)
    }

    private func updateVisitor(active: Bool) {
        visitor.isHidden = !active || visitors.kind == nil
        guard let kind = visitors.kind else { return }
        if displayedVisitor != kind {
            displayedVisitor = kind
            visitor.removeAllChildren()
            let rows = kind == .gull
                ? ["  WWW    ", " WWWWKOO ", "WWWWWW   ", " DDDDD   ", "  O O    "]
                : ["   DDD   ", "  DWWWD  ", " DKWKWWD ", " DWWOWWD ", "DDWWWWWDD"]
            let colors: [Character: NSColor] = [
                "W": NSColor(calibratedWhite: 0.9, alpha: 1),
                "D": NSColor(calibratedRed: 0.48, green: 0.61, blue: 0.68, alpha: 1),
                "K": NSColor(calibratedWhite: 0.2, alpha: 1),
                "O": NSColor(calibratedRed: 0.85, green: 0.56, blue: 0.3, alpha: 1),
            ]
            for (y, row) in rows.enumerated() {
                for (x, pixel) in row.enumerated() {
                    guard let color = colors[pixel] else { continue }
                    let node = SKSpriteNode(color: color, size: CGSize(width: 1.2, height: 1.2))
                    node.position = CGPoint(x: Double(x) * 1.2, y: Double(-y) * 1.2)
                    visitor.addChild(node)
                }
            }
        }
        visitor.alpha = visitors.visibility
        visitor.position = kind == .gull ? CGPoint(x: 104, y: 131) : CGPoint(x: 43, y: 46)
        if !reduceMotion, kind == .seal {
            visitor.position.y += sin(visitors.elapsed * 1.5) * 0.5
        }
    }

    private func updateEnvironment(active: Bool) {
        let time = reduceMotion ? 0 : ambientTime
        let wave = CGFloat(time.truncatingRemainder(dividingBy: 2) / 2)
        ripple.isHidden = !active || playback.phase != .fishing
        ripple.position = actors.convert(waterPoint, to: self)
        ripple.setScale(0.7 + wave * 0.8)
        ripple.alpha = reduceMotion ? 0.35 : 0.5 * (1 - wave)
        let mode = UserDefaults.standard.string(forKey: "qyube.coveAtmosphere") ?? "Auto"
        let hour = Calendar.current.component(.hour, from: visualNow())
        let night = mode == "Night" || (mode == "Auto" && (hour < 6 || hour >= 20))
        let sunset = mode == "Sunset" || (mode == "Auto" && (17..<20).contains(hour))
        let tint = night ? NSColor(calibratedRed: 0.35, green: 0.44, blue: 0.7, alpha: 1)
            : sunset ? NSColor(calibratedRed: 1, green: 0.77, blue: 0.65, alpha: 1) : .white
        let nextAtmosphere = night ? "Night" : sunset ? "Sunset" : "Morning"
        if atmosphereID != nextAtmosphere {
            atmosphereID = nextAtmosphere
            for node in [floe, character, bucket] {
                node.removeAction(forKey: "atmosphere")
                node.run(.colorize(with: tint, colorBlendFactor: night ? 0.55 : sunset ? 0.3 : 0,
                                   duration: reduceMotion ? 0 : 4), withKey: "atmosphere")
            }
        }
        for (index, flake) in snow.enumerated() {
            flake.isHidden = !active || !snowySession || reduceMotion
            let seed = Double(index)
            flake.position = CGPoint(x: 15 + (seed * 37 + sin(time * 0.3 + seed) * 4).truncatingRemainder(dividingBy: 135),
                                     y: 35 + (seed * 17 + 130 - time * 4).truncatingRemainder(dividingBy: 130))
            flake.alpha = 0.55
        }
    }

    private func smooth(_ t: CGFloat) -> CGFloat { t * t * (3 - 2 * t) }
    private func mix(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
    private func quadratic(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ t: CGFloat) -> CGPoint {
        mix(mix(a, b, t), mix(b, c, t), t)
    }
}
