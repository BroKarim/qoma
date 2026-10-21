import SwiftUI

/// The same title and controls appear on the floating timer and in the menu bar fallback.
struct SessionControlView: View {
    let title: String
    let isPaused: Bool
    let onTogglePause: () -> Void
    let onEdit: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.qyubeInk)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(title)

            HStack(spacing: 18) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 82 / 255, green: 115 / 255, blue: 134 / 255))
                        .frame(width: 34, height: 34)
                        .background(Color(red: 220 / 255, green: 232 / 255, blue: 237 / 255), in: Circle())
                }
                .help("Edit active session")
                .accessibilityLabel("Edit active session")

                Button(action: onTogglePause) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 82 / 255, green: 115 / 255, blue: 134 / 255))
                        .frame(width: 34, height: 34)
                        .background(Color(red: 220 / 255, green: 232 / 255, blue: 237 / 255), in: Circle())
                }
                .help(isPaused ? "Resume session" : "Pause session")
                .accessibilityLabel(isPaused ? "Resume session" : "Pause session")

                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.qyubeInterrupted)
                        .frame(width: 34, height: 34)
                        .background(Color.qyubeLine.opacity(0.45), in: Circle())
                }
                .help("End session")
                .accessibilityLabel("End session")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .frame(
            width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
            height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)
    }
}
