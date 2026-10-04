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
        var remaining = max(0, elapsed)
        var duration = 8.0
        while duration > 3 {
            if remaining < duration { return remaining / duration }
            remaining -= duration
            duration = max(3, duration - 0.5)
        }
        return remaining.truncatingRemainder(dividingBy: 3) / 3
    }

    static func dimStrength(elapsed: TimeInterval) -> Double {
        let phase = dimPhase(elapsed: elapsed)
        let sine = sin(.pi * phase)
        return sine * sine
    }
}
