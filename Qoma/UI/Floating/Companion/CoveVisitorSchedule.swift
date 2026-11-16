import Foundation

struct CoveVisitorSchedule {
    enum Kind: CaseIterable { case gull, seal }
    private(set) var kind: Kind?
    private(set) var elapsed: TimeInterval = 0
    private var wait: TimeInterval
    private var duration: TimeInterval = 15
    private let interval: () -> TimeInterval

    init(interval: @escaping () -> TimeInterval = { .random(in: 480...900) }) {
        self.interval = interval
        wait = interval()
    }

    mutating func advance(by delta: TimeInterval, active: Bool, canArrive: Bool) {
        guard active, delta.isFinite, delta > 0 else { return }
        if kind != nil {
            elapsed += delta
            if elapsed >= duration {
                kind = nil
                wait = interval()
                elapsed = 0
            }
        } else {
            wait = max(0, wait - delta)
            if wait == 0, canArrive {
                kind = Kind.allCases.randomElement()
                duration = .random(in: 10...20)
                elapsed = 0
            }
        }
    }

    var visibility: Double { min(1, elapsed / 2, max(0, (duration - elapsed) / 2)) }
}
