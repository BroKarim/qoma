import SwiftUI

struct InsightView: View {
    let accountID: String = "local"

    private var history: [FocusSession] {
        SessionRepository.shared.loadHistory(accountID: accountID)
    }

    private var bankedCatches: [CatchEvent] {
        CatchRepository.shared.listBanked(accountID: accountID)
    }

    private var totalFocusMinutes: Int {
        Int(history.reduce(0) { $0 + $1.actualActiveSeconds } / 60)
    }

    private var completedCount: Int {
        history.filter { $0.status == .completed }.count
    }

    private var interruptedCount: Int {
        history.filter { $0.status == .interrupted }.count
    }

    private var catchCount: Int {
        bankedCatches.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Insight")
                .font(.system(size: 24, weight: .semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                InsightCard(title: "Focus time", value: "\(totalFocusMinutes) min")
                InsightCard(title: "Completed", value: "\(completedCount)")
                InsightCard(title: "Interrupted", value: "\(interruptedCount)")
                InsightCard(title: "Catches", value: "\(catchCount)")
            }

            if !history.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent sessions")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    ForEach(history.suffix(5).reversed()) { session in
                        HStack {
                            Text(session.taskTitle.isEmpty ? "Focus session" : session.taskTitle)
                                .font(.system(size: 12))
                            Spacer()
                            Text("\(Int(session.actualActiveSeconds / 60)) min")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }
}

private struct InsightCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .semibold))
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.06))
        )
    }
}

