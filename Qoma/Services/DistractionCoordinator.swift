import Foundation
import Combine

/// Bridges foreground activity → policy decision → visual cue.
/// Does not own session clock or catch engine.
@MainActor
final class DistractionCoordinator: ObservableObject {
    @Published private(set) var isDistractionActive = false
    @Published private(set) var currentDecision: PolicyDecision?

    private let monitor: ForegroundActivityMonitor
    private var cancellables = Set<AnyCancellable>()
    private var detourStartTime: Date?
    private var totalDetourSeconds: TimeInterval = 0
    var onDecision: ((PolicyDecision) -> Void)?

    init(monitor: ForegroundActivityMonitor) {
        self.monitor = monitor
    }

    func start(policy: SessionPolicy) {
        monitor.startMonitoring()
        monitor.$currentActivity
            .compactMap { $0 }
            .sink { [weak self] activity in
                self?.evaluate(activity, against: policy)
            }
            .store(in: &cancellables)
    }

    func stop() {
        monitor.stopMonitoring()
        cancellables.removeAll()
        isDistractionActive = false
        currentDecision = nil
        detourStartTime = nil
    }

    func resetDetour() {
        detourStartTime = nil
        totalDetourSeconds = 0
    }

    var currentDetourSeconds: TimeInterval {
        guard isDistractionActive, let start = detourStartTime else { return totalDetourSeconds }
        return totalDetourSeconds + Date().timeIntervalSince(start)
    }

    private func evaluate(_ activity: ForegroundActivity, against policy: SessionPolicy) {
        let decision = FocusPolicyEvaluator.evaluate(activity, against: policy)
        let wasDistraction = isDistractionActive
        isDistractionActive = decision.isDistraction
        currentDecision = decision

        if decision.isDistraction {
            if detourStartTime == nil {
                detourStartTime = Date()
            }
        } else if wasDistraction {
            if let start = detourStartTime {
                totalDetourSeconds += Date().timeIntervalSince(start)
            }
            detourStartTime = nil
        }

        if wasDistraction != decision.isDistraction {
            onDecision?(decision)
        }
    }
}
