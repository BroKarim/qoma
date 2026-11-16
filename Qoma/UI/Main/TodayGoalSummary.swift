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
                        .font(.custom("GeistPixel-Regular", size: 22, relativeTo: .title2)).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .frame(width: max(0, geometry.size.width - 78), alignment: .leading)
                        .padding(.top, 12)
                    GoalFishingProgress(progress: self.revealed ? self.progress : 0)

                }
            }
            .frame(height: 81)
            Text(self.goalSeconds > 0 ? "Focus Goal" : "No daily focus target")
                .font(.custom("GeistPixel-Regular", size: 13, relativeTo: .callout)).foregroundStyle(Color.qyubeAccent)
        }
        .padding(14)
        .background {
            GeometryReader { geometry in
                Image("TodayHarbor").resizable().interpolation(.none)
                    .frame(width: geometry.size.width, height: geometry.size.height).clipped()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .qyubeInkSurface(
            fill: .clear,
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
            ZStack(alignment: .topLeading) {
                Capsule().fill(Color.qyubeAccent.opacity(0.09))
                    .overlay(Capsule().stroke(Color.qyubeAccent.opacity(0.25), lineWidth: 0.5))
                    .frame(height: 8).offset(y: 73)
                Capsule().fill(Color.qyubeAccent)
                    .frame(width: width * self.progress, height: 8).offset(y: 73)

            }
        }
        .accessibilityHidden(true)
    }
}
