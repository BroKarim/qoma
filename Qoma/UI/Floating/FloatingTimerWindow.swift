import SwiftUI

struct FloatingTimerView: View {
    @ObservedObject var timer: TimerReadoutModel

    @AppStorage(AppConstants.FloatingThemeSettings.opacityKey)
    private var floatingOpacity: Double = AppConstants.FloatingThemeSettings.defaultOpacity
    @AppStorage(AppConstants.FloatingThemeSettings.selectedThemeKey)
    private var selectedThemeID: String = AppConstants.FloatingThemeSettings.defaultThemeID
    @AppStorage(AppConstants.FloatingThemeSettings.liquidGlassKey)
    private var liquidGlass = false

    private let panelShape = RoundedRectangle(cornerRadius: 13, style: .continuous)

    var body: some View {
        panel
            .environment(\.colorScheme, .light)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Time remaining")
            .accessibilityValue(format(timer.remainingTime))
    }

    @ViewBuilder private var panel: some View {
        if #available(macOS 26.0, *), liquidGlass {
            timerContent
                .glassEffect(.regular, in: panelShape)
        } else {
            timerContent
                .background(softPanelBackground)
                .clipShape(panelShape)
        }
    }

    private var timerContent: some View {
        Text(format(timer.remainingTime))
            .font(.system(size: AppConstants.FloatingLayoutSettings.timerOnlyFontSize,
                          weight: .medium, design: .serif).monospacedDigit())
            .foregroundStyle(FloatingTheme.from(id: selectedThemeID).textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
                   height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)
    }

    private var softPanelBackground: some View {
        let opacity = min(AppConstants.FloatingThemeSettings.maxOpacity,
                          max(AppConstants.FloatingThemeSettings.minOpacity, floatingOpacity))
        return panelShape
            .fill(LinearGradient(colors: [.white, Color(white: 0.97)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(panelShape.strokeBorder(Color.black.opacity(0.10), lineWidth: 0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.07), lineWidth: 0.7)
                    .padding(3)
            )
            .opacity(opacity)
    }

    private func format(_ time: TimeInterval) -> String {
        let total = max(0, Int(time.rounded(.down)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
