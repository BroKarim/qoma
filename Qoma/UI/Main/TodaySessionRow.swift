import SwiftUI

struct TodaySessionRow: View {
    let title: String
    let detail: String
    let status: SessionStatus

    private var statusTitle: String {
        switch self.status {
        case .active: "In progress"
        case .paused: "Paused"
        case .completed: "Completed"
        case .interrupted: "Interrupted"
        }
    }

    private var statusColor: Color {
        self.status == .interrupted ? .qyubeInterrupted : .qyubeAccent
    }

    private var statusSymbol: String {
        switch self.status {
        case .active: "timer"
        case .paused: "pause.circle"
        case .completed: "checkmark.circle"
        case .interrupted: "xmark.circle"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: self.statusSymbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(self.statusColor)
                .frame(width: 30, height: 30)
                .background(self.statusColor.opacity(0.1), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(self.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(spacing: 5) {
                    Text(self.statusTitle)
                        .foregroundStyle(self.statusColor)
                    Text("·").foregroundStyle(.tertiary)
                    Text(self.detail).foregroundStyle(.secondary)
                }
                .font(.caption)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .qyubeInkSurface(fill: .white.opacity(0.58), stroke: Color.qyubeAccent.opacity(0.32), lineWidth: 0.8)
        .accessibilityElement(children: .combine)
    }
}
