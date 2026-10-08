import Foundation
import OSLog

/// Pure-ish engine for the catch sequence and banking boundary.
/// UI animation is driven by events, not by this engine's frame state.
final class CatchEngine {
    enum Phase: Equatable {
        case waiting
        case bite
        case reeling(kindID: String)
        case depositing(kindID: String)
    }

    private let rollKind: () -> String
    private let biteWait: () -> TimeInterval
    private let reelTime: () -> TimeInterval
    private var phase: Phase = .waiting
    private var depositedThisSession = 0

    init(
        rollKind: @escaping () -> String = CatchEngine.defaultRoll,
        biteWait: @escaping () -> TimeInterval = { .random(in: 6...10) },
        reelTime: @escaping () -> TimeInterval = { .random(in: 0.9...1.5) }
    ) {
        self.rollKind = rollKind
        self.biteWait = biteWait
        self.reelTime = reelTime
    }

    var currentPhase: Phase { phase }

    /// Start the next waiting period. Returns the duration until the bite cue.
    @discardableResult
    func scheduleNextBite() -> TimeInterval {
        phase = .waiting
        let duration = biteWait()
        return duration
    }

    /// Called by UI when the bite cue fires. Rolls identity and begins reeling.
    @discardableResult
    func beginReel() -> (kindID: String, duration: TimeInterval) {
        let kindID = rollKind()
        phase = .reeling(kindID: kindID)
        return (kindID, reelTime())
    }

    /// Called by UI when the catch reaches the bucket.
    /// Returns the stored event and whether it was banked.
    func deposit(
        sessionID: UUID,
        accountID: String,
        activeSeconds: TimeInterval,
        now: Date = Date()
    ) -> (event: CatchEvent, banked: Bool)? {
        guard case .reeling(let kindID) = phase else { return nil }

        phase = .depositing(kindID: kindID)
        depositedThisSession += 1

        let banked = activeSeconds >= CatchEngine.bankThresholdSeconds
        let event = CatchEvent(
            sessionID: sessionID,
            accountID: accountID,
            kindID: kindID,
            depositedAt: now,
            bankedAt: banked ? now : nil
        )

        phase = .waiting
        return (event, banked)
    }

    /// Cancel an in-flight catch. No event is produced.
    func cancelInFlight() {
        switch phase {
        case .reeling, .depositing:
            phase = .waiting
        default:
            break
        }
    }

    static let bankThresholdSeconds: TimeInterval = 300 // 5 minutes

    static func kind(for roll: Double, oceanFindIndex: Int = 0) -> String {
        switch roll {
        case 0..<0.55:
            return "anchovy"
        case 0.55..<0.80:
            return "perch"
        case 0.80..<0.92:
            return "trout"
        case 0.92..<0.97:
            return "salmon"
        case 0.97..<0.99:
            return "narwhal"
        default:
            return ["stick", "pebble", "shell"][abs(oceanFindIndex) % 3]
        }
    }

    static let defaultRoll: () -> String = {
        kind(for: Double.random(in: 0...1), oceanFindIndex: Int.random(in: 0..<3))
    }
}
