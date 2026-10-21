import SwiftUI

struct SessionOutcomeView: View {
    let session: FocusSession
    let catches: [CatchEvent]
    let onBreak: () -> Void
    let onRepeat: () -> Bool
    let onDone: () -> Void
    let onReview: () -> Void

    @State private var repeatFailed = false

    var body: some View {
        VStack(spacing: 9) {
            Text("Nice work")
                .font(.system(size: 25, weight: .semibold, design: .serif))
            Text(session.taskTitle.isEmpty ? "Focus session" : session.taskTitle)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.tail)
            Text("\(QyubeFormat.duration(session.actualActiveSeconds)) focused · \(catches.count) catches")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !catches.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(catches.prefix(5))) { event in
                        QyubeCatchArt(kindID: event.kindID).frame(width: 30, height: 25)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(catches.count) catches from this session")
            }
            Button("BREAK 5 MIN", action: onBreak)
                .buttonStyle(.plain)
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity).frame(height: 34)
                .foregroundStyle(.white).background(Color.qyubeAccent, in: RoundedRectangle(cornerRadius: 8))
            Button("REPEAT SESSION") {
                if !onRepeat() { repeatFailed = true }
            }
            .buttonStyle(.plain)
            .font(.callout.weight(.semibold))
            .frame(maxWidth: .infinity).frame(height: 32)
            .qyubeInkSurface(fill: .white, stroke: .qyubeAccent)
            Button("Done", action: onDone)
                .buttonStyle(.plain)
                .font(.callout)
                .foregroundStyle(Color.qyubeAccent)
            if repeatFailed {
                Button("Could not repeat. Review session in Today", action: onReview)
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(Color.qyubeInterrupted)
            }
        }
        .foregroundStyle(Color.qyubeInk)
        .padding(16)
        .frame(width: 280, height: 280)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.qyubeLine, lineWidth: 1))
        .environment(\.colorScheme, .light)
    }
}

struct BreakPanelView: View {
    @ObservedObject var readout: TimerReadoutModel
    let finished: Bool
    let onSkip: () -> Void
    let onRepeat: () -> Bool
    let onDone: () -> Void
    let onReview: () -> Void

    @State private var repeatFailed = false

    var body: some View {
        VStack(spacing: 11) {
            Text(finished ? "Break finished" : "Break")
                .font(.system(size: 23, weight: .semibold, design: .serif))
            if finished {
                Text("Ready when you are.")
                    .font(.callout).foregroundStyle(.secondary)
                Button("REPEAT SESSION") {
                    if !onRepeat() { repeatFailed = true }
                }
                .buttonStyle(.plain)
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity).frame(height: 36)
                .foregroundStyle(.white).background(Color.qyubeAccent, in: RoundedRectangle(cornerRadius: 8))
                Button("Done", action: onDone).buttonStyle(.plain)
                if repeatFailed {
                    Button("Review session in Today", action: onReview)
                        .buttonStyle(.plain).font(.caption)
                }
            } else {
                Text(QyubeFormat.countdown(readout.breakRemaining))
                    .font(.system(size: 42, weight: .medium, design: .serif).monospacedDigit())
                Button("Skip break", action: onSkip)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.qyubeAccent)
            }
        }
        .foregroundStyle(Color.qyubeInk)
        .padding(16)
        .frame(width: 260, height: 190)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.qyubeLine, lineWidth: 1))
        .environment(\.colorScheme, .light)
    }
}
