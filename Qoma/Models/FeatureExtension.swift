import SwiftUI

protocol FeatureExtension: Identifiable {
    var id: String { get }
    var title: String { get }
    var description: String { get }
    var systemImage: String { get }
    var settingsKey: String { get }
    var defaultValue: Bool { get }

    func collapsedSize() -> CGSize
    func expandedSize() -> CGSize

    @ViewBuilder
    func collapsedView(
        theme: FloatingTheme,
        onTap: @escaping () -> Void
    ) -> AnyView

    @ViewBuilder
    func expandedView(
        theme: FloatingTheme,
        onCollapse: @escaping () -> Void,
        onFocusChange: @escaping (Bool) -> Void
    ) -> AnyView

    @ViewBuilder
    func analyticsSection() -> AnyView?
}
