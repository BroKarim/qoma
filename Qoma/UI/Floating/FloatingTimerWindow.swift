import SwiftUI

struct FloatingTimerView: View {
    @ObservedObject var timer: TimerReadoutModel
    let onTogglePause: () -> Bool
    let onEdit: () -> Void
    let onStop: () -> Void

    @AppStorage(AppConstants.FloatingThemeSettings.selectedThemeKey)
    private var selectedThemeID = AppConstants.FloatingThemeSettings.defaultThemeID
    @AppStorage(AppConstants.FloatingThemeSettings.liquidGlassKey)
    private var liquidGlass = false

    @State private var isHovered = false
    @State private var pointerInside = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var blink = false
    @State private var actionError: String?

    private var showingControls: Bool { isHovered }

    var body: some View {
        Group {
            if showingControls {
                PixelSessionControlView(
                    title: timer.taskTitle,
                    isPaused: timer.isPaused,
                    onTogglePause: {
                        if !onTogglePause() { actionError = "Could not save the change." } else {
                            actionError = nil
                        }
                    },
                    onEdit: onEdit,
                    onStop: onStop)
            } else {
                VStack(spacing: 2) {
                    Text(QyubeFormat.countdown(timer.remainingTime))
                        .font(.system(
                            size: AppConstants.FloatingLayoutSettings.timerOnlyFontSize,
                            weight: .medium,
                            design: .rounded).monospacedDigit())
                        .foregroundStyle(FloatingTheme.from(id: selectedThemeID).textColor)
                        .lineLimit(1)

                }
                .frame(
                    width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
                    height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)
                .contentShape(Rectangle())
                .opacity(timer.isPaused && blink && !reduceMotion ? 0.35 : 1)
                .animation(timer.isPaused && !reduceMotion ? .easeInOut(duration: 1).repeatForever(autoreverses: true) : nil, value: blink)
                .onChange(of: timer.isPaused, initial: true) { blink = timer.isPaused }
                .onDisappear { blink = false }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(timer.isPaused ? "Paused, time remaining" : "Time remaining")
                .accessibilityValue(QyubeFormat.countdown(timer.remainingTime))
                .accessibilityAction(named: timer.isPaused ? "Resume session" : "Pause session") {
                    if !onTogglePause() { actionError = "Could not save the change." }
                }
                .accessibilityAction(named: "Edit session", onEdit)
                .accessibilityAction(named: "Stop session", onStop)
            }
        }
        .background {
            if #available(macOS 26.0, *), liquidGlass {
                RoundedRectangle(cornerRadius: 16).fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16).fill(.white)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.qyubeLine, lineWidth: 1))
        .shadow(color: .black.opacity(0.13), radius: 12, y: 5)
        .help(timer.taskTitle)
        .onHover { pointerInside = $0; if $0 { isHovered = true } }
        .task(id: pointerInside) {
            guard !pointerInside else { return }
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            isHovered = false
        }
        .alert("Could not pause or resume", isPresented: Binding(
            get: { actionError != nil },
            set: { if !$0 { actionError = nil } })) {
            Button("OK") { actionError = nil }
        } message: {
            Text(actionError ?? "Try again.")
        }
        .environment(\.colorScheme, .light)
    }
}
