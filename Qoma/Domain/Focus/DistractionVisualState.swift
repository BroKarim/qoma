import Foundation

enum DistractionEffect: CaseIterable, Equatable {
    case iceFlower
    case dimBright
}

/// Shared clock for the window overlay and the independent penguin panel.
struct DistractionVisualState: Equatable {
    let effect: DistractionEffect
    let startedAt: Date
    let seed: UInt64
    let ownerPID: pid_t
}

enum DistractionMotion {
    static func iceFlowerCount(elapsed: TimeInterval) -> Int {
        6 + min(18, max(0, Int(max(0, elapsed) / 10) * 4))
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
        let sine = sin(.pi * phase)
        return sine * sine
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
            let count = DistractionMotion.iceFlowerCount(elapsed: elapsed)
            defer { lastMarker = count }
            return count != lastMarker ? .freeze : nil
        case .dimBright:
            let cycle = DistractionMotion.dimCycle(elapsed: elapsed)
            let marker = cycle.index * 2 + Int((cycle.phase + 0.25) * 2)
            defer { lastMarker = marker }
            guard !reduceMotion, let lastMarker, marker != lastMarker else { return nil }
            return .lightSwitch
        }
    }
}
