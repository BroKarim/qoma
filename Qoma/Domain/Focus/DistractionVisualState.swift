import Foundation

enum DistractionEffect: CaseIterable, Equatable {
    case iceFlower
    case dimBright
    case snowstorm
}

/// Shared clock for the window overlay and the independent penguin panel.
struct DistractionVisualState: Equatable {
    let effect: DistractionEffect
    let startedAt: Date
    let seed: UInt64
    let ownerPID: pid_t
}

enum DistractionMotion {
    /// Slow, linear turns indicate an ongoing distraction; alternate directions avoid a spinning field.
    static func crystalBloom(index: Int, age: TimeInterval, reduceMotion: Bool) -> (rotation: Double, opacity: Double) {
        guard !reduceMotion else { return (0, 1) }
        let period = Double(48 + (index % 3) * 12)
        let direction = index.isMultiple(of: 2) ? 1.0 : -1.0
        let rotation = direction * max(0, age).truncatingRemainder(dividingBy: period) / period * 2 * .pi
        let shimmer = (sin(max(0, age) * 2 * .pi / 8 + Double(index)) + 1) / 2
        return (rotation, 0.94 + shimmer * 0.06)
    }

    static let bloomBreathTime = 0.5
    static let bloomBatchInterval = 10.0
    static let lightOffPhase = 0.15
    static let lightOnPhase = 0.70

    static func iceFlowerCapacity(area: Double) -> Int {
        min(180, max(24, Int(max(0, area) / 5_000)))
    }

    static func iceFlowerCount(elapsed: TimeInterval, area: Double = 900 * 650) -> Int {
        let capacity = iceFlowerCapacity(area: area)
        let initial = Int(ceil(Double(capacity) * 0.25))
        let batch = Int(ceil(Double(capacity) * 0.15))
        return min(capacity, initial + min(5, Int(max(0, elapsed) / 10)) * batch)
    }

    static func iceFlowerBirth(index: Int, area: Double) -> TimeInterval {
        let capacity = iceFlowerCapacity(area: area)
        let initial = Int(ceil(Double(capacity) * 0.25))
        let batch = Int(ceil(Double(capacity) * 0.15))
        return bloomBreathTime + (index < initial ? 0 : Double((index - initial) / batch + 1) * bloomBatchInterval)
    }

    /// Pose changes share the overlay clock, rather than the interrupted fishing clock.
    static func penguinFrame(effect: DistractionEffect, elapsed: TimeInterval, reduceMotion: Bool) -> Int {
        guard !reduceMotion, elapsed.isFinite else { return effect == .iceFlower ? 2 : 0 }
        let time = max(0, elapsed)
        switch effect {
        case .dimBright:
            let cycle = dimCycle(elapsed: time)
            let duration = max(3, 8 - Double(cycle.index) * 0.5)
            let off = (cycle.phase - lightOffPhase) * duration
            let on = (cycle.phase - lightOnPhase) * duration
            if on >= -0.25 {
                return min(11, 9 + Int(floor(on * 12 + 0.000001)))
            }
            if off >= -0.25 {
                return min(5, 3 + Int(floor(off * 12 + 0.000001)))
            }
            return 0
        case .iceFlower:
            let age = time.truncatingRemainder(dividingBy: bloomBatchInterval)
            let standing = time >= bloomBatchInterval ? 2 : 0
            return max(standing, min(10, Int(age * 12 + 0.000001)))
        case .snowstorm:
            let drawingTime = time.truncatingRemainder(dividingBy: 4) - 0.3
            guard drawingTime >= 0 else { return 0 }
            if drawingTime < 0.5 { return min(5, Int(drawingTime * 12 + 0.000001)) }
            if drawingTime < 1.5 { return 6 }
            if drawingTime < 1.5 + 5.0 / 12 { return min(11, 7 + Int((drawingTime - 1.5) * 12 + 0.000001)) }
            return 0
        }
    }

    /// A complete bright → dim → bright cycle. Duration decreases only at cycle boundaries.
    static func dimPhase(elapsed: TimeInterval) -> Double {
        dimCycle(elapsed: elapsed).phase
    }

    static func dimCycle(elapsed: TimeInterval) -> (index: Int, phase: Double) {
        var remaining = max(0, elapsed)
        var duration = 8.0
        var index = 0
        while duration > 3 {
            if remaining < duration { return (index, remaining / duration) }
            remaining -= duration
            duration = max(3, duration - 0.5)
            index += 1
        }
        return (index + Int(remaining / 3), remaining.truncatingRemainder(dividingBy: 3) / 3)
    }

    static func dimStrength(elapsed: TimeInterval) -> Double {
        let phase = dimPhase(elapsed: elapsed)
        let duration = max(3, 8 - Double(dimCycle(elapsed: elapsed).index) * 0.5)
        let transition = 0.15 / duration
        return min(1, max(0, min((phase - lightOffPhase) / transition, (lightOnPhase - phase) / transition + 1)))
    }
}

enum DistractionSoundCue: Equatable {
    case freeze, lightSwitch
}

/// Emits one sound per visible batch / brightness transition, never once per frame.
struct DistractionSoundCursor {
    private var lastMarker: Int?

    mutating func advance(
        effect: DistractionEffect, elapsed: TimeInterval, reduceMotion: Bool
    ) -> DistractionSoundCue? {
        switch effect {
        case .iceFlower:
            guard reduceMotion || elapsed >= DistractionMotion.bloomBreathTime else { return nil }
            let marker = reduceMotion ? 0 : min(5, Int((elapsed - DistractionMotion.bloomBreathTime) / DistractionMotion.bloomBatchInterval))
            defer { lastMarker = marker }
            return marker != lastMarker ? .freeze : nil
        case .dimBright:
            let cycle = DistractionMotion.dimCycle(elapsed: elapsed)
            let marker = cycle.index * 2 + (cycle.phase >= DistractionMotion.lightOffPhase ? 1 : 0) + (cycle.phase >= DistractionMotion.lightOnPhase ? 1 : 0)
            defer { lastMarker = marker }
            guard !reduceMotion, let lastMarker, marker != lastMarker else { return nil }
            return .lightSwitch
        case .snowstorm:
            // No wind recording is bundled yet; do not substitute an unrelated cue.
            return nil
        }
    }
}
