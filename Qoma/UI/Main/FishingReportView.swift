import SwiftUI

struct FishingReportView: View {
    let session: FocusSession
    let catches: [CatchEvent]
    let onStartAgain: () -> Void
    let onGoHome: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(session.status == .completed ? "Session complete" : "Session ended")
                .font(.system(size: 28, weight: .semibold))

            VStack(spacing: 8) {
                Text(session.taskTitle)
                    .font(.system(size: 17, weight: .medium))
                Text("\(Int(session.actualActiveSeconds / 60)) minutes focused")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            if catches.isEmpty {
                Text(session.status == .completed && session.actualActiveSeconds < 300
                     ? "No catches this time."
                     : "No catches landed.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64))], spacing: 16) {
                    ForEach(catches) { event in
                        CatchReportCell(event: event)
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Start again", action: onStartAgain)
                    .buttonStyle(.borderedProminent)
                Button("Home", action: onGoHome)
                    .buttonStyle(.bordered)
            }
        }
        .padding(32)
        .frame(minWidth: 420, minHeight: 360)
    }
}

private struct CatchReportCell: View {
    let event: CatchEvent

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(event.kindID)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                )
        }
    }
}

