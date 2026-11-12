import AppKit

final class DistractionEffectView: NSView {
    var occludedRegions: [CGRect] = [] {
        didSet { if oldValue != occludedRegions { needsDisplay = true } }
    }
    private(set) var flowerCount = 0
    private(set) var snowCount = 0
    private(set) var dimOpacity = 0.0
    private var state: DistractionVisualState?
    private var elapsed: TimeInterval = 0
    private var reduceMotion = false
    private var layoutSize = CGSize.zero
    private var sprites: [DistractionSprite] = []
    private static let flowers = (1...6).compactMap { NSImage(named: "CrystalBloom\($0)") }
    private static let snow = (1...6).compactMap { NSImage(named: "DistractionSnow\($0)") }
    private static let wind = NSImage(named: "DistractionWind")
    private static let snowbank = NSImage(named: "DistractionSnowbank")

    override var isOpaque: Bool { false }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func render(state: DistractionVisualState, elapsed: TimeInterval, reduceMotion: Bool) {
        let time = reduceMotion ? 0 : max(0, elapsed)
        let area = bounds.width * bounds.height
        let count = state.effect == .iceFlower
            ? DistractionMotion.iceFlowerCount(elapsed: time, area: area) : 0
        let snowCount = state.effect == .snowstorm ? 18 + Int(min(40, time) * 0.3) : 0
        let opacity = state.effect == .dimBright
            ? (reduceMotion ? 0.8 : 0.85 * DistractionMotion.dimStrength(elapsed: time)) : 0
        let changed = self.state != state || self.reduceMotion != reduceMotion || layoutSize != bounds.size
            || flowerCount != count || self.snowCount != snowCount || dimOpacity != opacity
        let animating = !reduceMotion && (state.effect == .snowstorm || state.effect == .iceFlower)
        // Regenerate only when seed or geometry changes; positions stay fixed between frames.
        if self.state?.seed != state.seed || layoutSize != bounds.size {
            sprites = DistractionSprite.make(
                seed: state.seed,
                size: bounds.size,
                count: max(30, DistractionMotion.iceFlowerCapacity(area: area)))
        }
        self.state = state
        self.elapsed = time
        self.reduceMotion = reduceMotion
        layoutSize = bounds.size
        flowerCount = count
        self.snowCount = snowCount
        dimOpacity = opacity
        if changed || animating { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.clear(dirtyRect)
        context.saveGState()
        defer { context.restoreGState() }
        context.addPath(CGPath(roundedRect: bounds, cornerWidth: 10, cornerHeight: 10, transform: nil))
        context.clip()
        for rect in occludedRegions {
            let path = CGMutablePath()
            path.addRect(bounds)
            path.addRect(rect)
            context.addPath(path)
            context.clip(using: .evenOdd)
        }
        if dimOpacity > 0 {
            context.setFillColor(NSColor.black.withAlphaComponent(dimOpacity).cgColor)
            context.fill(bounds)
        }
        switch state?.effect {
        case .iceFlower: drawFlowers(context)
        case .snowstorm: drawSnowstorm(context)
        default: break
        }
    }

    private func drawFlowers(_ context: CGContext) {
        guard !Self.flowers.isEmpty else { return }
        context.interpolationQuality = .none
        let area = bounds.width * bounds.height
        for (index, sprite) in sprites.prefix(flowerCount).enumerated() {
            let born = DistractionMotion.iceFlowerBirth(index: index, area: area)
            let growth = reduceMotion ? 1 : min(1, max(0, (elapsed - born) / 0.85))
            let eased = growth * growth * (3 - 2 * growth)
            guard eased > 0 else { continue }
            let center = CGPoint(x: bounds.width * sprite.x, y: bounds.height * sprite.y)
            let motion = DistractionMotion.crystalBloom(index: index, age: max(0, elapsed - born), reduceMotion: reduceMotion)
            draw(
                Self.flowers[index % Self.flowers.count],
                at: center,
                width: sprite.width * (0.8 + 0.2 * eased),
                rotation: sprite.rotation + motion.rotation,
                opacity: eased * motion.opacity,
                context: context)
        }
    }

    private func drawSnowstorm(_ context: CGContext) {
        guard !Self.snow.isEmpty else { return }
        for (index, sprite) in sprites.prefix(snowCount).enumerated() {
            let travel: CGFloat = reduceMotion ? 0 : CGFloat(elapsed) * (0.055 + CGFloat(index % 4) * 0.008)
            let x = (sprite.x - travel).truncatingRemainder(dividingBy: 1)
            let y = (sprite.y - travel * 0.35).truncatingRemainder(dividingBy: 1)
            let center = CGPoint(
                x: (x < 0 ? x + 1 : x) * (bounds.width + 48) - 24,
                y: (y < 0 ? y + 1 : y) * (bounds.height + 48) - 24)
            draw(
                Self.snow[index % Self.snow.count],
                at: center,
                width: 16 + sprite.width * 0.18,
                rotation: sprite.rotation,
                opacity: 0.95,
                context: context)
        }
        if let wind = Self.wind, !reduceMotion {
            for index in 0..<2 {
                let beat = (elapsed / 4 + Double(index) * 0.5).truncatingRemainder(dividingBy: 1)
                let width = min(420, bounds.width * 0.55)
                let center = CGPoint(
                    x: bounds.width * (1.25 - beat * 1.5),
                    y: bounds.height * (index == 0 ? 0.36 : 0.72))
                draw(
                    wind,
                    at: center,
                    width: width,
                    rotation: 0.05,
                    opacity: sin(beat * .pi) * 0.65,
                    context: context)
            }
        }
        if let bank = Self.snowbank {
            let height = min(64, bounds.height * 0.1) * (reduceMotion ? 0.6 : 0.6 + 0.4 * min(1, elapsed / 40))
            // Repeat at natural proportions; resizing a window never stretches the painted snow.
            let width = height * bank.size.width / bank.size.height
            guard width > 0 else { return }
            var x: CGFloat = 0
            while x < bounds.width {
                bank.draw(
                    in: CGRect(x: x, y: -2, width: width, height: height),
                    from: .zero,
                    operation: .sourceOver,
                    fraction: 1)
                x += width * 0.95
            }
        }
    }

    private func draw(
        _ image: NSImage,
        at center: CGPoint,
        width: CGFloat,
        rotation: CGFloat,
        opacity: Double,
        context: CGContext
    ) {
        context.saveGState()
        defer { context.restoreGState() }
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: rotation)
        let height = width * image.size.height / image.size.width
        image.draw(
            in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height),
            from: .zero,
            operation: .sourceOver,
            fraction: opacity)
    }
}

private struct DistractionSprite {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let rotation: CGFloat

    static func make(seed: UInt64, size: CGSize, count: Int) -> [Self] {
        var random = DistractionRandom(value: seed)
        let aspect = max(0.25, size.width / max(1, size.height))
        let columns = max(1, Int(ceil(sqrt(CGFloat(count) * aspect))))
        let rows = Int(ceil(Double(count) / Double(columns)))
        var cells = Array(0..<(columns * rows))
        for i in stride(from: cells.count - 1, through: 1, by: -1) {
            cells.swapAt(i, Int(random.unit() * CGFloat(i + 1)))
        }
        return cells.prefix(count).map { cell in
            Self(
                x: (CGFloat(cell % columns) + 0.15 + random.unit() * 0.7) / CGFloat(columns),
                y: (CGFloat(cell / columns) + 0.15 + random.unit() * 0.7) / CGFloat(rows),
                width: 65 + random.unit() * 55,
                rotation: (random.unit() - 0.5) * 1.4)
        }
    }
}

private struct DistractionRandom {
    var value: UInt64
    mutating func unit() -> CGFloat {
        value &+= 0x9E3779B97F4A7C15
        var z = value
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return CGFloat(Double((z ^ (z >> 31)) >> 11) / Double(1 << 53))
    }
}
