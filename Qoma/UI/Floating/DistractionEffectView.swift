import AppKit

final class DistractionEffectView: NSView {
    var occludedRegions: [CGRect] = [] {
        didSet { if oldValue != occludedRegions { needsDisplay = true } }
    }
    private(set) var flowerCount = 0
    private(set) var dimOpacity = 0.0
    private var state: DistractionVisualState?
    private var elapsed: TimeInterval = 0
    private var reduceMotion = false
    private var flowers: [IceFlowerSpec] = []
    private var lastGrowth = -1.0

    override var isOpaque: Bool { false }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func render(state: DistractionVisualState, elapsed: TimeInterval, reduceMotion: Bool) {
        let count = state.effect == .iceFlower ? DistractionMotion.iceFlowerCount(elapsed: elapsed) : 0
        let opacity = state.effect == .dimBright
            ? (reduceMotion ? 0.25 : 0.35 * DistractionMotion.dimStrength(elapsed: elapsed)) : 0
        let latestBirth = min(50, floor(max(0, elapsed) / 10) * 10)
        let growth = reduceMotion ? 1 : min(1, max(0, (elapsed - latestBirth) / 0.85))
        let changed = self.state != state || self.reduceMotion != reduceMotion
            || flowerCount != count || dimOpacity != opacity || (count > 0 && lastGrowth != growth)
        if self.state?.seed != state.seed { flowers = IceFlowerSpec.make(seed: state.seed) }
        self.state = state
        self.elapsed = elapsed
        self.reduceMotion = reduceMotion
        flowerCount = count
        dimOpacity = opacity
        lastGrowth = growth
        if changed { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill(using: .copy)
        NSBezierPath(roundedRect: bounds, xRadius: 10, yRadius: 10).addClip()
        for rect in occludedRegions {
            let path = CGMutablePath()
            path.addRect(bounds)
            path.addRect(rect)
            NSGraphicsContext.current?.cgContext.addPath(path)
            NSGraphicsContext.current?.cgContext.clip(using: .evenOdd)
        }
        if dimOpacity > 0 {
            NSColor.black.withAlphaComponent(dimOpacity).setFill()
            bounds.fill()
        }
        let scale = min(1.45, max(0.75, sqrt(bounds.width * bounds.height) / 850))
        for (index, flower) in flowers.prefix(flowerCount).enumerated() {
            let born = index < 6 ? 0 : Double((index - 6) / 4 + 1) * 10
            let growth = reduceMotion ? 1 : min(1, max(0, (elapsed - born) / 0.85))
            guard growth > 0 else { continue }
            let eased = growth * growth * (3 - 2 * growth)
            let center = CGPoint(x: bounds.width * flower.x, y: bounds.height * flower.y)
            let path = flower.path(center: center, radius: flower.radius * scale * (0.8 + 0.2 * eased))
            NSColor(calibratedRed: 0.8, green: 0.95, blue: 1, alpha: 0.55 * eased).setStroke()
            path.lineWidth = 2.8 * scale
            path.stroke()
            NSColor(calibratedRed: 0.28, green: 0.7, blue: 0.9, alpha: 0.9 * eased).setStroke()
            path.lineWidth = 1.15 * scale
            path.stroke()
        }
    }
}

private struct IceFlowerSpec {
    let x: CGFloat
    let y: CGFloat
    let radius: CGFloat
    let rotation: CGFloat

    static func make(seed: UInt64) -> [Self] {
        var random = IceRandom(value: seed)
        var cells = Array(0..<24)
        for i in stride(from: cells.count - 1, through: 1, by: -1) {
            cells.swapAt(i, Int(random.unit() * CGFloat(i + 1)))
        }
        return cells.map { cell in
            Self(
                x: (CGFloat(cell % 6) + 0.3 + random.unit() * 0.4) / 6,
                y: (CGFloat(cell / 6) + 0.3 + random.unit() * 0.4) / 4,
                radius: 35 + random.unit() * 17,
                rotation: random.unit() * .pi)
        }
    }

    func path(center: CGPoint, radius: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        func point(_ distance: CGFloat, _ angle: CGFloat, from origin: CGPoint) -> CGPoint {
            CGPoint(x: origin.x + cos(angle) * distance, y: origin.y + sin(angle) * distance)
        }
        func stroke(_ a: CGPoint, _ b: CGPoint) { path.move(to: a); path.line(to: b) }
        for arm in 0..<6 {
            let angle = rotation + CGFloat(arm) * .pi / 3
            stroke(center, point(radius, angle, from: center))
            for tier in 0..<5 {
                let fraction = 0.24 + CGFloat(tier) * 0.14
                let joint = point(radius * fraction, angle, from: center)
                let branchLength = radius * (0.27 - CGFloat(tier) * 0.025)
                for direction: CGFloat in [-1, 1] {
                    let branch = angle + direction * .pi / 3
                    stroke(joint, point(branchLength, branch, from: joint))
                    if tier < 3 {
                        let twig = point(branchLength * 0.6, branch, from: joint)
                        stroke(twig, point(branchLength * 0.42, angle, from: twig))
                    }
                }
            }
        }
        return path
    }
}

private struct IceRandom {
    var value: UInt64
    mutating func unit() -> CGFloat {
        value &+= 0x9E3779B97F4A7C15
        var z = value
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return CGFloat(Double((z ^ (z >> 31)) >> 11) / Double(1 << 53))
    }
}
