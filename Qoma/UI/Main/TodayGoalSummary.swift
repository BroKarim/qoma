import SwiftUI

struct TodayGoalSummary: View {
    let focusedSeconds: TimeInterval
    @AppStorage("qyube.dailyFocusGoal.hours") private var goalHours = 2
    @AppStorage("qyube.dailyFocusGoal.minutes") private var goalMinutes = 0

    private var goalSeconds: TimeInterval {
        TimeInterval(self.goalHours * 60 + self.goalMinutes) * 60
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 10) {
                Text("DAILY FOCUS GOAL")
                    .font(.caption.weight(.medium))
                    .tracking(1.4)
                    .foregroundStyle(Color.qyubeAccent)
                Text(QyubeFormat.duration(self.focusedSeconds))
                    .font(.title2)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(
                    self.goalSeconds > 0
                        ? "of \(QyubeFormat.duration(self.goalSeconds)) today"
                        : "No daily focus target")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if self.goalSeconds > 0 {
                    ProgressView(value: min(self.focusedSeconds, self.goalSeconds), total: self.goalSeconds)
                        .tint(Color.qyubeAccent)
                        .accessibilityLabel("Daily focus goal progress")
                        .accessibilityValue("\(Int(min(self.focusedSeconds / self.goalSeconds, 1) * 100)) percent")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            QyubeMenuBarPenguin()
                .frame(width: 82, height: 88)
                .accessibilityHidden(true)
        }
        .padding(12)
        .qyubeInkSurface(fill: .white.opacity(0.74), stroke: Color.qyubeMenuInk.opacity(0.72), lineWidth: 1)
    }
}
