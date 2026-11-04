import SwiftUI

struct TodayGoalSummary: View {
    let focusedSeconds: TimeInterval
    @AppStorage("qyube.dailyFocusGoal.hours") private var goalHours = 2
    @AppStorage("qyube.dailyFocusGoal.minutes") private var goalMinutes = 0
    @AppStorage("qyube.reduceMotionOverride") private var reduceMotion = false
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
                        .frame(width: max(0, geometry.size.width - 96), alignment: .leading)
                        .padding(.top, 12)
                    GoalFishingProgress(progress: self.revealed ? self.progress : 0)
                    Image("TodayGoalPenguin")
                        .resizable().scaledToFit()
                        .frame(width: 100, height: 100)
                        .offset(x: geometry.size.width - 100, y: -2)
                        .accessibilityHidden(true)
                }
            }
            .frame(height: 105)
            Text(self.goalSeconds > 0 ? "Focus Goal" : "No daily focus target")
                .font(.callout).foregroundStyle(Color.qyubeAccent)
        }
        .padding(14)
        .qyubeInkSurface(
            fill: Color.qyubeSelection.opacity(0.35),
            stroke: Color.qyubeMenuInk.opacity(0.72),
            lineWidth: 1)
        .animation(
            self.systemReduceMotion || self.reduceMotion ? nil : .easeInOut(duration: 0.9),
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
            let end = CGPoint(x: 4 + max(0, width - 8) * self.progress, y: 101)
            // Rod tip calibrated to the transparent TodayGoalPenguin asset's 100pt frame.
            let tip = CGPoint(x: width - 89, y: 14)
            ZStack(alignment: .topLeading) {
                Capsule().fill(Color.qyubeAccent.opacity(0.09))
                    .overlay(Capsule().stroke(Color.qyubeAccent.opacity(0.25), lineWidth: 0.5))
                    .frame(height: 8).offset(y: 97)
                Capsule().fill(Color.qyubeAccent)
                    .frame(width: width * self.progress, height: 8).offset(y: 97)
                Path { path in
                    path.move(to: tip)
                    path.addCurve(
                        to: end,
                        control1: CGPoint(x: tip.x, y: 78),
                        control2: CGPoint(x: end.x, y: 64))
                }
                .stroke(Color(red: 0.53, green: 0.36, blue: 0.18), style: StrokeStyle(lineWidth: 0.65, lineCap: .round))
            }
        }
        .accessibilityHidden(true)
    }
}
