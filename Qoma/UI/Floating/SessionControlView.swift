import SwiftUI

/// The same title and controls appear on the floating timer and in the menu bar fallback.
struct SessionControlView: View {
    let title: String
    let isPaused: Bool
    let onTogglePause: () -> Void
    let onEdit: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.custom("GeistPixel-Regular", size: 24))
                .foregroundStyle(Color.qyubeInk)
                .lineLimit(3)
                .minimumScaleFactor(0.1)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .accessibilityLabel(title)

            HStack(spacing: 4) {
                control("edit", label: "Edit active session", action: onEdit)
                control(isPaused ? "play" : "pause", label: isPaused ? "Resume session" : "Pause session", action: onTogglePause)
                control("stop", label: "End session", action: onStop)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(
            width: 200,
            height: 110)
    }

    private func control(_ asset: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image("FloatingWatercolor-\(asset)")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 44)
                .frame(width: 42, height: 40)
                .clipped()
                .contentShape(Rectangle())
        }
        .help(label)
        .accessibilityLabel(label)
    }
}


struct PixelSessionControlView: View {
    let title: String
    let isPaused: Bool
    let onTogglePause: () -> Void
    let onEdit: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            control("edit", label: "Edit active session", action: onEdit)
            control(isPaused ? "play" : "pause", label: isPaused ? "Resume session" : "Pause session", action: onTogglePause)
            control("stop", label: "End session", action: onStop)
        }
        .frame(width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
               height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)
        .help(title)
    }

    private func control(_ asset: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image("FloatingWatercolor-\(asset)").resizable()
                .scaledToFit().frame(width: 24, height: 24)
                .frame(width: 36, height: 36).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}
