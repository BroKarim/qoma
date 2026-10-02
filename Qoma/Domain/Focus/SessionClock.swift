import Foundation

/// Injectable clock for a single focus session.
/// Keeps deadline absolutes so wake/background does not drift.
final class SessionClock {
    typealias Now = () -> Date

    private let now: Now
    private(set) var startTime: Date
    private(set) var deadline: Date
    private(set) var accumulatedActiveSeconds: TimeInterval
    private(set) var pausedAt: Date?

    init(
        plannedDuration: TimeInterval,
        startTime: Date = Date(),
        accumulatedActiveSeconds: TimeInterval = 0,
        pausedAt: Date? = nil,
        now: @escaping Now = Date.init
    ) {
        self.now = now
        self.startTime = startTime
        self.deadline = startTime.addingTimeInterval(plannedDuration)
        self.accumulatedActiveSeconds = accumulatedActiveSeconds
        self.pausedAt = pausedAt
    }

    convenience init(
        plannedMinutes: Int,
        startTime: Date = Date(),
        accumulatedActiveSeconds: TimeInterval = 0,
        pausedAt: Date? = nil,
        now: @escaping Now = Date.init
    ) {
        self.init(
            plannedDuration: TimeInterval(plannedMinutes) * 60,
            startTime: startTime,
            accumulatedActiveSeconds: accumulatedActiveSeconds,
            pausedAt: pausedAt,
            now: now
        )
    }

    /// Remaining time. Zero when past deadline.
    var remaining: TimeInterval {
        let current = now()
        if let pausedAt {
            return max(0, deadline.timeIntervalSince(pausedAt))
        }
        return max(0, deadline.timeIntervalSince(current))
    }

    /// True if the deadline has passed.
    var isDue: Bool {
        remaining <= 0
    }

    /// Active seconds excluding pause time.
    var activeSeconds: TimeInterval {
        let current = now()
        if pausedAt != nil {
            return accumulatedActiveSeconds
        }
        return accumulatedActiveSeconds + max(0, current.timeIntervalSince(startTime))
    }

    /// Elapsed wall-clock seconds since start.
    var elapsedWallClockSeconds: TimeInterval {
        max(0, now().timeIntervalSince(startTime))
    }

    var isPaused: Bool { pausedAt != nil }

    var currentDeadline: Date { deadline }

    func pause() {
        guard pausedAt == nil else { return }
        let current = now()
        accumulatedActiveSeconds += max(0, current.timeIntervalSince(startTime))
        pausedAt = current
    }

    func resume() {
        guard let paused = pausedAt else { return }
        let drift = now().timeIntervalSince(paused)
        deadline = deadline.addingTimeInterval(drift)
        startTime = now()
        pausedAt = nil
    }

    /// Call when app relaunches with a stored snapshot. Returns true if the session
    /// became due while the process was not running.
    @discardableResult
    func reconcileAfterWake() -> Bool {
        guard pausedAt == nil else { return false }
        return isDue
    }
}
