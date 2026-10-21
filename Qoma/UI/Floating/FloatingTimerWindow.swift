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
    @State private var controlsPinned = false
    @State private var confirmingStop = false
    @State private var actionError: String?

    private var showingControls: Bool { isHovered || controlsPinned || confirmingStop }

    var body: some View {
        Group {
            if showingControls {
                SessionControlView(
                    title: timer.taskTitle,
                    isPaused: timer.isPaused,
                    onTogglePause: {
                        if !onTogglePause() { actionError = "Could not save the change." } else {
                            actionError = nil
                        }
                    },
                    onEdit: onEdit,
                    onStop: { controlsPinned = true; confirmingStop = true })
            } else {
                VStack(spacing: 2) {
                    Text(QyubeFormat.countdown(timer.remainingTime))
                        .font(.system(
                            size: AppConstants.FloatingLayoutSettings.timerOnlyFontSize,
                            weight: .medium,
                            design: .serif).monospacedDigit())
                        .foregroundStyle(FloatingTheme.from(id: selectedThemeID).textColor)
                        .lineLimit(1)
                    if timer.isPaused {
                        Text("PAUSED")
                            .font(.caption2.weight(.semibold))
                            .tracking(1.3)
                            .foregroundStyle(Color.qyubeInterrupted)
                    }
                }
                .frame(
                    width: AppConstants.FloatingLayoutSettings.timerOnlyWidth,
                    height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)
                .contentShape(Rectangle())
                .onTapGesture { controlsPinned = true }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(timer.isPaused ? "Paused, time remaining" : "Time remaining")
                .accessibilityValue(QyubeFormat.countdown(timer.remainingTime))
                .accessibilityAction(named: "Show session controls") { controlsPinned = true }
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
        .onHover { isHovered = $0; if $0 { controlsPinned = false } }
        .alert("End this session?", isPresented: $confirmingStop) {
            Button("End session", role: .destructive, action: onStop)
            Button("Keep focusing", role: .cancel) { controlsPinned = false }
        } message: {
            Text("Your focused time will be saved as an interrupted session.")
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
