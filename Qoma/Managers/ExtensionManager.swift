import Combine
import SwiftUI

@MainActor
final class ExtensionManager: ObservableObject {
    static let shared = ExtensionManager()

    @Published private(set) var registered: [any FeatureExtension] = []
    @Published private(set) var activeExtension: (any FeatureExtension)?

    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func register(_ extension: any FeatureExtension) {
        guard !registered.contains(where: { $0.id == `extension`.id }) else { return }
        registered.append(`extension`)

        let key = `extension`.settingsKey
        let defaultValue = `extension`.defaultValue

        UserDefaults.standard.register(defaults: [key: defaultValue])

        UserDefaults.standard.publisher(for: key)
            .sink { [weak self] _ in
                self?.updateActiveExtension()
            }
            .store(in: &cancellables)

        updateActiveExtension()
    }

    func isEnabled(_ extension: any FeatureExtension) -> Bool {
        UserDefaults.standard.bool(forKey: `extension`.settingsKey)
    }

    func setEnabled(_ extension: any FeatureExtension, enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: `extension`.settingsKey)
    }

    func binding(for extension: any FeatureExtension) -> Binding<Bool> {
        Binding(
            get: { [weak self] in
                self?.isEnabled(`extension`) ?? `extension`.defaultValue
            },
            set: { [weak self] value in
                self?.setEnabled(`extension`, enabled: value)
            }
        )
    }

    private func updateActiveExtension() {
        activeExtension = registered.first { isEnabled($0) }
    }
}

extension UserDefaults {
    func publisher(for key: String) -> AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification, object: self)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
