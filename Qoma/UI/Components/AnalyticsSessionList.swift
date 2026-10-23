import SwiftUI

struct AnalyticsSessionList: View {
    let sessions: [FocusSessionRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AnalyticsJournalHeading(title: "Sessions", detail: "\(sessions.count) sessions")
            if sessions.isEmpty {
                Text("A quiet day. Your focus sessions will appear here.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(sessions) { session in
                        HStack(spacing: 9) {
                            Text(session.startedAt.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Color.qyubeAccent)
                                .frame(width: 48, alignment: .leading)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title(for: session))
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(2)
                                Label(session.completed ? "Completed" : "Interrupted",
                                      systemImage: session.completed ? "checkmark.circle" : "minus.circle")
                                    .font(.system(size: 9))
                                    .foregroundStyle(session.completed ? Color.qyubeAccent : Color.qyubeInterrupted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text(QyubeFormat.duration(session.actualFocusSeconds))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .fixedSize()
                        }
                        .padding(.vertical, 11)
                        .accessibilityElement(children: .combine)
                        if session.id != sessions.last?.id {
                            QyubeInkDivider().frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .qyubeInkSurface(fill: .white.opacity(0.65), stroke: Color.qyubeAccent.opacity(0.2), lineWidth: 0.7)
            }
        }
    }

    private func title(for session: FocusSessionRecord) -> String {
        guard let title = session.taskTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else { return "Focus session" }
        return title
    }
}
