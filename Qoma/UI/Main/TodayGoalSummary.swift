import SwiftUI

struct TodayGoalSummary: View {
    let focusedSeconds: TimeInterval
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(QyubeFormat.duration(focusedSeconds)).font(.title2).monospacedDigit()
            Text("Focused today").font(.callout).foregroundStyle(.secondary)
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
    }
}
