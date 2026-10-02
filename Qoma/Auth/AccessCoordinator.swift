import Foundation
import Combine

/// Abstract entitlement / access coordination.
/// Concrete implementations hide backend/StoreKit details from the rest of the app.
protocol AccessCoordinatorProtocol: Sendable {
    var accessState: AnyPublisher<AccessState, Never> { get }
    func refreshAccess() async -> AccessState
    func canStartSession() -> Bool
}

/// Local-only stub used until backend integration is wired.
@MainActor
final class AccessCoordinator: ObservableObject, AccessCoordinatorProtocol {
    static let shared = AccessCoordinator()

    @Published private(set) var state: AccessState = .readyForFirstSession

    var accessState: AnyPublisher<AccessState, Never> {
        $state.eraseToAnyPublisher()
    }

    func refreshAccess() async -> AccessState {
        state
    }

    func canStartSession() -> Bool {
        switch state {
        case .readyForFirstSession, .trialing, .paid:
            return true
        case .signedOut, .cardRequired, .expired, .paymentIssue, .unknown:
            return false
        }
    }

    func setState(_ state: AccessState) {
        self.state = state
    }
}
