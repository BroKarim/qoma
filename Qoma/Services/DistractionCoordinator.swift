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
    private var monitoredPolicy: SessionPolicy?
    private var detourStartTime: Date?
    private var totalDetourSeconds: TimeInterval = 0
    var onDecision: ((PolicyDecision) -> Void)?

    init(monitor: ForegroundActivityMonitor) {
        self.monitor = monitor
    }

    func start(policy: SessionPolicy) {
        guard monitoredPolicy != policy || !monitor.isMonitoring else { return }
        cancellables.removeAll()
        monitor.stopMonitoring()
        monitoredPolicy = policy
        monitor.$currentActivity
            .sink { [weak self] activity in
                if let activity {
                    self?.evaluate(activity, against: policy)
                } else {
                    self?.clearCurrentActivity()
                }
            }
            .store(in: &cancellables)
        monitor.startMonitoring(policy: policy)
    }

    func stop() {
        cancellables.removeAll()
        monitor.stopMonitoring()
        monitoredPolicy = nil
        currentDecision = nil
        isDistractionActive = false
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
        // qyube itself must stay available for pausing and ending a session.
        let decision = activity.bundleID == Bundle.main.bundleIdentifier
            ? PolicyDecision(isDistraction: false, reason: .safeByDefault)
            : FocusPolicyEvaluator.evaluate(activity, against: policy)
        let wasDistraction = isDistractionActive
        currentDecision = decision
        isDistractionActive = decision.isDistraction

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

    private func clearCurrentActivity() {
        guard isDistractionActive else { return }
        let decision = PolicyDecision(isDistraction: false, reason: .safeByDefault)
        if let start = detourStartTime {
            totalDetourSeconds += Date().timeIntervalSince(start)
        }
        detourStartTime = nil
        currentDecision = decision
        isDistractionActive = false
        onDecision?(decision)
    }
}
