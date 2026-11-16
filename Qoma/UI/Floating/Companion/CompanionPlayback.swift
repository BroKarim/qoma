import Foundation

/// UI-only timeline. Decorative catches never write to Catalog or analytics.
struct CompanionPlayback {
    enum Phase: String, CaseIterable {
        case hidden, starting, fishing, bite, pulling, deposit, casting
        case sleeping, distracted, completed, releasing
    }

    private(set) var phase: Phase = .hidden
    private(set) var phaseTime: TimeInterval = 0
    private(set) var phaseDuration: TimeInterval = 1
    private(set) var depositedCatches = 0
    private(set) var releasedCatches = 0
    private(set) var catchIsTree = false
    private(set) var completedVisualCatches = 0
    private(set) var isSessionActive = false
    private(set) var isPaused = false
    private(set) var isDistracted = false
    private let biteWait: () -> TimeInterval
    private let reelTime: () -> TimeInterval

    init(
        biteWait: @escaping () -> TimeInterval = { .random(in: 6...10) },
        reelTime: @escaping () -> TimeInterval = { .random(in: 1.4...1.6) })
    {
        self.biteWait = biteWait
        self.reelTime = reelTime
    }

    var progress: Double {
        min(1, self.phaseTime / max(self.phaseDuration, 0.001))
    }

    var catchFrame: Int {
        switch phase {
        case .bite: min(2, Int(progress * 3))
        case .pulling: min(11, 3 + Int(progress * 16))
        case .completed: 11
        default: 0
        }
    }

    var movementFrame: Int { min(11, Int(progress * 12)) }

    mutating func start() {
        self.depositedCatches = 0
        self.releasedCatches = 0
        self.completedVisualCatches = 0
        self.catchIsTree = false
        self.isSessionActive = true
        self.isPaused = false
        self.isDistracted = false
        self.enter(.starting, duration: 0.65)
    }

    mutating func setPaused(_ paused: Bool) {
        guard self.isSessionActive, self.isPaused != paused else { return }
        self.isPaused = paused
        if paused { self.enter(.sleeping) } else if self.isDistracted { self.enter(.distracted) } else {
            self.enter(.casting, duration: 0.55)
        }
    }

    mutating func setDistracted(_ distracted: Bool) {
        guard self.isSessionActive, self.isDistracted != distracted else { return }
        self.isDistracted = distracted
        guard !self.isPaused else { return }
        if distracted { self.enter(.distracted) } else { self.enter(.casting, duration: 0.55) }
    }

    mutating func complete() {
        guard self.isSessionActive else { return }
        self.isSessionActive = false
        self.isPaused = false
        self.isDistracted = false
        self.enter(.completed)
    }

    mutating func stop(activeSeconds: TimeInterval) {
        guard self.phase != .hidden, self.phase != .releasing else { return }
        self.isSessionActive = false
        self.isPaused = false
        self.isDistracted = false
        self.releasedCatches = activeSeconds < 300 ? self.depositedCatches : 0
        if activeSeconds < 300 { self.depositedCatches = 0 }
        self.enter(.releasing, duration: self.releasedCatches > 0 ? 1.1 : 0.45)
    }

    mutating func dismiss() {
        self.isSessionActive = false
        self.enter(.hidden)
    }

    mutating func recordCatch(kindID: String) {
        guard isSessionActive else { return }
        depositedCatches += 1
        catchIsTree = CatalogDefinitions.kind(id: kindID)?.isFish == false
    }

    /// Debug preview only: shorten the current idle wait without awarding a catch.
    mutating func biteNow() {
        guard self.phase == .fishing else { return }
        self.enter(.bite, duration: 0.22)
    }

    mutating func advance(by delta: TimeInterval) {
        guard delta.isFinite, delta > 0 else { return }
        var remaining = delta
        while remaining > 0 {
            switch self.phase {
            case .hidden: return
            case .sleeping, .distracted, .completed:
                self.phaseTime += remaining
                return
            default: break
            }
            let step = min(remaining, max(0, phaseDuration - self.phaseTime))
            self.phaseTime += step
            remaining -= step
            guard self.phaseTime >= self.phaseDuration else { return }
            switch self.phase {
            case .starting: self.enter(.casting, duration: 0.55)
            case .casting: self.enter(.fishing, duration: max(0.1, self.biteWait()))
            case .fishing: self.enter(.bite, duration: 0.22)
            case .bite: self.enter(.pulling, duration: max(0.1, self.reelTime()))
            case .pulling: self.enter(.deposit, duration: 1.2)
            case .deposit:
                // Visual cycle only; rewards arrive from persisted catch events.
                self.completedVisualCatches += 1
                self.enter(.casting, duration: 0.55)
            case .releasing: self.enter(.hidden)
            default: return
            }
        }
    }

    private mutating func enter(_ phase: Phase, duration: TimeInterval = 1) {
        self.phase = phase
        self.phaseTime = 0
        self.phaseDuration = duration
    }
}
