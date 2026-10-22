import SwiftUI

struct MenuBarSessionPopover: View {
    @ObservedObject var coordinator: SessionCoordinator
    let onEdit: () -> Void
    let onStop: () -> Void

    @State private var confirmingStop = false
    @State private var actionError: String?

    var body: some View {
        Group {
            if coordinator.isActive || coordinator.isPaused {
                SessionControlView(
                    title: coordinator.currentTaskTitle,
                    isPaused: coordinator.isPaused,
                    onTogglePause: togglePause,
                    onEdit: onEdit,
                    onStop: { confirmingStop = true })
                    .frame(
                        width: 200,
                        height: 110)
            } else if case let .failed(message) = coordinator.finalizationState {
                VStack(spacing: 12) {
                    Text(message).font(.callout).multilineTextAlignment(.center)
                    Button("Retry saving") { coordinator.retryFinalization() }
                        .font(.callout.weight(.semibold))
                }
                .padding(14)
                .frame(width: 260, height: 130)
            } else if coordinator.finalizationState == .saving {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("Saving session…").font(.callout)
                }
                .frame(width: 260, height: 130)
            } else {
                Text("Open Qyube to start a session")
                    .font(.callout)
                    .frame(
                        width: 200,
                        height: 110)
            }
        }
        .foregroundStyle(Color.qyubeInk)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.qyubeLine, lineWidth: 1))
        .environment(\.colorScheme, .light)
        .alert("End this session?", isPresented: $confirmingStop) {
            Button("End session", role: .destructive, action: onStop)
            Button("Keep focusing", role: .cancel) {}
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
    }

    private func togglePause() {
        let wasPaused = coordinator.isPaused
        if wasPaused { coordinator.resumeSession() } else { coordinator.pauseSession() }
        if wasPaused == coordinator.isPaused { actionError = "Could not save the change." }
    }
}
