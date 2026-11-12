import SwiftUI

struct TodayGoalSummary: View {
    let focusedSeconds: TimeInterval
    @AppStorage("qyube.dailyFocusGoal.hours") private var goalHours = 2
    @AppStorage("qyube.dailyFocusGoal.minutes") private var goalMinutes = 0
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var revealed = false

    private var goalSeconds: TimeInterval {
        TimeInterval(max(0, self.goalHours * 60 + self.goalMinutes)) * 60
    }

    private var progress: Double {
        self.goalSeconds > 0 ? min(max(self.focusedSeconds / self.goalSeconds, 0), 1) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    Text("\(QyubeFormat.duration(self.focusedSeconds)) / \(QyubeFormat.duration(self.goalSeconds))")
                        .font(.title2).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .frame(width: max(0, geometry.size.width - 78), alignment: .leading)
                        .padding(.top, 12)
                    GoalFishingProgress(progress: self.revealed ? self.progress : 0)
                    Image("TodayGoalPenguin")
                        .resizable().scaledToFit()
                        .frame(width: 80, height: 80)
                        .offset(x: geometry.size.width - 80, y: 2)
                        .accessibilityHidden(true)
                }
            }
            .frame(height: 81)
            Text(self.goalSeconds > 0 ? "Focus Goal" : "No daily focus target")
                .font(.callout).foregroundStyle(Color.qyubeAccent)
        }
        .padding(14)
        .qyubeInkSurface(
            fill: Color.qyubeSelection.opacity(0.35),
            stroke: Color.qyubeMenuInk.opacity(0.72),
            lineWidth: 1)
        .animation(
            self.systemReduceMotion ? nil : .easeInOut(duration: 0.9),
            value: self.revealed ? self.progress : 0)
        .onAppear { self.revealed = true }
        .onDisappear { self.revealed = false }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Focus Goal")
        .accessibilityValue(
            "\(QyubeFormat.duration(self.focusedSeconds)) of \(QyubeFormat.duration(self.goalSeconds)), "
                + "\(Int(self.progress * 100)) percent")
    }
}

private struct GoalFishingProgress: View, Animatable {
    var progress: Double

    var animatableData: Double {
        get { self.progress }
        set { self.progress = newValue }
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let end = CGPoint(x: width * self.progress, y: 77)
            // Rod tip calibrated to the transparent TodayGoalPenguin standing asset’s 80pt frame.
            let tip = CGPoint(x: width - 72, y: 10)
            ZStack(alignment: .topLeading) {
                Capsule().fill(Color.qyubeAccent.opacity(0.09))
                    .overlay(Capsule().stroke(Color.qyubeAccent.opacity(0.25), lineWidth: 0.5))
                    .frame(height: 8).offset(y: 73)
                Capsule().fill(Color.qyubeAccent)
                    .frame(width: width * self.progress, height: 8).offset(y: 73)
                Path { path in
                    path.move(to: tip)
                    path.addCurve(
                        to: end,
                        control1: CGPoint(x: tip.x, y: 58),
                        control2: CGPoint(x: end.x, y: 52))
                }
                .stroke(Color(red: 0.53, green: 0.36, blue: 0.18), style: StrokeStyle(lineWidth: 0.65, lineCap: .round))
                Path { hook in
                    hook.move(to: CGPoint(x: end.x, y: end.y - 7))
                    hook.addLine(to: end)
                    hook.addCurve(
                        to: CGPoint(x: end.x - 4, y: end.y - 3),
                        control1: CGPoint(x: end.x, y: end.y + 3),
                        control2: CGPoint(x: end.x - 5, y: end.y + 3))
                    hook.addLine(to: CGPoint(x: end.x - 3, y: end.y - 1))
                }
                .stroke(Color.qyubeMenuInk, style: StrokeStyle(lineWidth: 0.8, lineCap: .round, lineJoin: .round))
            }
        }
        .accessibilityHidden(true)
    }
}
