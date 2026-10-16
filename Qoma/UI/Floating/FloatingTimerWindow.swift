import SwiftUI

struct FloatingTimerView: View {
    @ObservedObject var timer: TimerReadoutModel

    @AppStorage(AppConstants.FloatingThemeSettings.selectedThemeKey)
    private var selectedThemeID: String = AppConstants.FloatingThemeSettings.defaultThemeID
    @AppStorage(AppConstants.FloatingThemeSettings.liquidGlassKey)
    private var liquidGlass = false

    private let panelShape = RoundedRectangle(cornerRadius: 13, style: .continuous)

    var body: some View {
        self.panel
            .environment(\.colorScheme, .light)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Time remaining")
            .accessibilityValue(self.format(self.timer.remainingTime))
    }

    @ViewBuilder private var panel: some View {
        if #available(macOS 26.0, *), self.liquidGlass {
            self.timerContent
                .glassEffect(.regular, in: self.panelShape)
        } else {
            self.timerContent
                .background(self.softPanelBackground)
                .clipShape(self.panelShape)
        }
    }

    private var timerContent: some View {
        Text(self.format(self.timer.remainingTime))
            .font(.system(
                size: AppConstants.FloatingLayoutSettings.timerOnlyFontSize,
                weight: .medium,
                design: .serif).monospacedDigit())
            .foregroundStyle(FloatingTheme.from(id: self.selectedThemeID).textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(
                width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
                height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)
    }

    private var softPanelBackground: some View {
        self.panelShape
            .fill(LinearGradient(
                colors: [.white, Color(white: 0.97)],
                startPoint: .top,
                endPoint: .bottom))
            .overlay(self.panelShape.strokeBorder(Color.black.opacity(0.10), lineWidth: 0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.07), lineWidth: 0.7)
                    .padding(3))
    }

    private func format(_ time: TimeInterval) -> String {
        let total = max(0, Int(time.rounded(.down)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
