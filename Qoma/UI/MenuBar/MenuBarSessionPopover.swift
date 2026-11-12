import SwiftUI

struct MenuBarSessionPopover: View {
    @ObservedObject var coordinator: SessionCoordinator
    let onEdit: () -> Void
    let onStop: () -> Void

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
        .foregroundStyle(Color.qyubeMenuInk)
        .background(Color.qyubeBackground)
        .clipShape(QyubeInkBorder())
        .overlay(QyubeInkBorder().stroke(Color.qyubeMenuInk, lineWidth: 1.2).allowsHitTesting(false))
        .environment(\.colorScheme, .light)
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
            VStack(spacing: 3) {
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
                        QyubeInkBorder().fill(Color.qyubeBackground)
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(red: 88 / 255, green: 143 / 255, blue: 149 / 255))
                                    .frame(width: geometry.size.width * elapsed / total)
                            }
                            .clipShape(QyubeInkBorder())
                            .overlay(QyubeInkBorder().stroke(Color.qyubeMenuInk, lineWidth: 1))
                    }
                    .frame(height: 9)
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
                playerControl("stop", label: "End session", action: onStop)
            }
            .frame(height: 34)
            .background(Color.qyubeMenuInk)
            .overlay(alignment: .top) {
                QyubeInkDivider().frame(height: 2)
            }
        }
        .frame(width: 200, height: 110)
    }

    private func playerControl(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SessionInkIcon(symbol: symbol)
                .stroke(Color.qyubeBackground, style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round))
                .frame(width: 17, height: 17)
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

private struct SessionInkIcon: Shape {
    let symbol: String

    func path(in rect: CGRect) -> Path {
        var path = Path()
        func stroke(_ points: [CGPoint], closed: Bool = false) {
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: first.x * rect.width, y: first.y * rect.height))
            for point in points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * rect.width, y: point.y * rect.height))
            }
            if closed { path.closeSubpath() }
        }
        switch symbol {
        case "pencil":
            stroke([.init(x: 0.17, y: 0.81), .init(x: 0.23, y: 0.60), .init(x: 0.69, y: 0.13), .init(x: 0.84, y: 0.27), .init(x: 0.38, y: 0.75)], closed: true)
            stroke([.init(x: 0.61, y: 0.23), .init(x: 0.75, y: 0.37)])
        case "pause.fill":
            stroke([.init(x: 0.32, y: 0.18), .init(x: 0.30, y: 0.80)])
            stroke([.init(x: 0.69, y: 0.20), .init(x: 0.70, y: 0.81)])
        case "play.fill":
            stroke([.init(x: 0.30, y: 0.16), .init(x: 0.79, y: 0.50), .init(x: 0.28, y: 0.82)], closed: true)
        default:
            stroke([.init(x: 0.24, y: 0.21), .init(x: 0.77, y: 0.23),
                    .init(x: 0.79, y: 0.77), .init(x: 0.23, y: 0.79)], closed: true)
        }
        return path
    }
}
