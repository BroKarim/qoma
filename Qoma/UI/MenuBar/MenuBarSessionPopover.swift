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
                sessionPlayer
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
        .background(Color.qyubeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.qyubeMenuInk, lineWidth: 1))
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

    private var sessionPlayer: some View {
        let total = max(1, TimeInterval(coordinator.snapshot?.draft.plannedMinutes ?? 0) * 60)
        let elapsed = min(total, max(0, total - coordinator.remainingTime))
        return VStack(spacing: 0) {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image("MenuBarSessionLogo")
                        .resizable().scaledToFit()
                        .frame(width: 30, height: 30)
                        .accessibilityHidden(true)
                    Text(coordinator.currentTaskTitle)
                        .font(.custom("Arial", fixedSize: 12))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .help(coordinator.currentTaskTitle)
                }
                VStack(spacing: 3) {
                    GeometryReader { geometry in
                        Capsule().fill(Color.qyubeAccent.opacity(0.18))
                            .overlay(alignment: .leading) {
                                Capsule().fill(Color.qyubeAccent)
                                    .frame(width: geometry.size.width * elapsed / total)
                            }
                    }
                    .frame(height: 4)
                    .accessibilityLabel("Session progress")
                    .accessibilityValue("\(Int(elapsed / total * 100)) percent")
                    HStack {
                        Text(QyubeFormat.countdown(elapsed))
                        Spacer()
                        Text(QyubeFormat.countdown(total))
                    }
                    .font(.custom("Arial", fixedSize: 9).monospacedDigit())
                    .foregroundStyle(Color.qyubeAccent)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 76)
            HStack(spacing: 0) {
                playerControl("pencil", label: "Edit active session", action: onEdit)
                playerControl(coordinator.isPaused ? "play.fill" : "pause.fill",
                              label: coordinator.isPaused ? "Resume session" : "Pause session", action: togglePause)
                playerControl("stop", label: "End session") { confirmingStop = true }
            }
            .frame(height: 34)
            .background(Color.qyubeMenuInk)
        }
        .frame(width: 200, height: 110)
    }

    private func playerControl(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.qyubeBackground)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }

    private func togglePause() {
        let wasPaused = coordinator.isPaused
        if wasPaused { coordinator.resumeSession() } else { coordinator.pauseSession() }
        if wasPaused == coordinator.isPaused { actionError = "Could not save the change." }
    }
}
