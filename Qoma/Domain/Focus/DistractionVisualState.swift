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
        return index < initial ? 0 : Double((index - initial) / batch + 1) * 10
    }

    /// Pose changes share the overlay clock, rather than the interrupted fishing clock.
    static func penguinFrame(effect: DistractionEffect, elapsed: TimeInterval, reduceMotion: Bool) -> Int {
        guard !reduceMotion, elapsed.isFinite else { return 0 }
        let time = max(0, elapsed)
        switch effect {
        case .dimBright:
            let cycle = dimCycle(elapsed: time)
            let duration = max(3, 8 - Double(cycle.index) * 0.5)
            let click = duration * (cycle.phase < 0.425 ? 0.15 : 0.70)
            // Drawing 6 is the press, exactly on each light-switch sound beat.
            let drawingTime = cycle.phase * duration - click + 0.5
            return drawingTime >= 0 && drawingTime < 1 ? min(11, Int(drawingTime * 12 + 0.000001)) : 0
        case .iceFlower:
            let drawingTime = time.truncatingRemainder(dividingBy: 2.8) - 0.3
            return drawingTime >= 0 && drawingTime < 1 ? min(11, Int(drawingTime * 12 + 0.000001)) : 0
        case .snowstorm:
            let drawingTime = time.truncatingRemainder(dividingBy: 4) - 0.3
            guard drawingTime >= 0 else { return 0 }
            if drawingTime < 0.5 { return min(5, Int(drawingTime * 12 + 0.000001)) }
            if drawingTime < 1.5 { return 6 }
            if drawingTime < 1.5 + 5.0 / 12 { return min(11, 7 + Int((drawingTime - 1.5) * 12 + 0.000001)) }
            return 0
        }
    }

    static func penguinLift(effect: DistractionEffect, elapsed: TimeInterval, reduceMotion: Bool) -> Double {
        guard effect == .iceFlower, !reduceMotion, elapsed.isFinite else { return 0 }
        let drawingTime = max(0, elapsed).truncatingRemainder(dividingBy: 2.8) - 0.3
        guard drawingTime > 1.0 / 3, drawingTime < 0.75 else { return 0 }
        return sin((drawingTime - 1.0 / 3) / (0.75 - 1.0 / 3) * .pi) * 10
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
        return min(1, max(0, min((phase - 0.15) / transition, (0.70 - phase) / transition)))
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
            let marker = reduceMotion ? 0 : min(5, Int(max(0, elapsed) / 10))
            defer { lastMarker = marker }
            return marker != lastMarker ? .freeze : nil
        case .dimBright:
            let cycle = DistractionMotion.dimCycle(elapsed: elapsed)
            let marker = cycle.index * 2 + (cycle.phase >= 0.15 ? 1 : 0) + (cycle.phase >= 0.70 ? 1 : 0)
            defer { lastMarker = marker }
            guard !reduceMotion, let lastMarker, marker != lastMarker else { return nil }
            return .lightSwitch
        case .snowstorm:
            // No wind recording is bundled yet; do not substitute an unrelated cue.
            return nil
        }
    }
}
