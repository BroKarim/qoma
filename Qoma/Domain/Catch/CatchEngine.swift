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

    private let customRollKind: (() -> String)?
    private let biteWait: () -> TimeInterval
    private let reelTime: () -> TimeInterval
    private var phase: Phase = .waiting
    private var plannedReelDuration: TimeInterval = 1
    private var pendingEventID: UUID?

    init(
        rollKind: (() -> String)? = nil,
        biteWait: @escaping () -> TimeInterval = { .random(in: CatchRarityRules.intervalSeconds) },
        reelTime: @escaping () -> TimeInterval = { .random(in: 0.9...1.5) }
    ) {
        self.customRollKind = rollKind
        self.biteWait = biteWait
        self.reelTime = reelTime
    }

    var currentPhase: Phase { phase }
    var currentReelDuration: TimeInterval { plannedReelDuration }

    /// Start the next waiting period. Returns the duration until the bite cue.
    @discardableResult
    func scheduleNextBite() -> TimeInterval {
        phase = .waiting
        plannedReelDuration = reelTime()
        return max(0.01, biteWait() - plannedReelDuration)
    }

    /// Called by UI when the bite cue fires. Rolls identity and begins reeling.
    @discardableResult
    func beginReel(pity: CatchPityState = .init()) -> (kindID: String, eventID: UUID, duration: TimeInterval) {
        let kindID = customRollKind?() ?? CatchRarityRules.roll(pity: pity)
        let eventID = pendingEventID ?? UUID()
        pendingEventID = eventID
        phase = .reeling(kindID: kindID)
        return (kindID, eventID, plannedReelDuration)
    }

    func restoreInFlight(kindID: String, eventID: UUID, duration: TimeInterval) {
        pendingEventID = eventID
        plannedReelDuration = max(0, duration)
        phase = .reeling(kindID: kindID)
    }

    /// Called by UI when the catch reaches the bucket.
    /// Returns the stored event and whether it was banked.
    func deposit(
        sessionID: UUID,
        accountID: String,
        activeSeconds: TimeInterval,
        eventID: UUID? = nil,
        now: Date = Date()
    ) -> (event: CatchEvent, banked: Bool)? {
        let kindID: String
        switch phase {
        case .reeling(let current), .depositing(let current): kindID = current
        case .waiting, .bite: return nil
        }

        phase = .depositing(kindID: kindID)
        let banked = activeSeconds >= CatchEngine.bankThresholdSeconds
        let event = CatchEvent(
            id: eventID ?? pendingEventID ?? UUID(),
            sessionID: sessionID,
            accountID: accountID,
            kindID: kindID,
            depositedAt: now,
            bankedAt: banked ? now : nil
        )

        return (event, banked)
    }

    func confirmDeposit() {
        guard case .depositing = phase else { return }
        phase = .waiting
        pendingEventID = nil
    }

    /// Cancel an in-flight catch. No event is produced.
    func cancelInFlight() {
        switch phase {
        case .reeling, .depositing:
            phase = .waiting
            pendingEventID = nil
        default:
            break
        }
    }

    static let bankThresholdSeconds: TimeInterval = 300 // 5 minutes

}
