import SwiftUI

struct AnalyticsTimelineView: View {
    let entries: [AnalyticsTimelineEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity Timeline")
                .font(.headline)

            if entries.isEmpty {
                Text("No activity recorded for this day.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(entries) { entry in
                            TimelineRow(entry: entry)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding()
    }
}

struct TimelineRow: View {
    let entry: AnalyticsTimelineEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .trailing, spacing: 0) {
                Text(entry.timeLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatDuration(entry.seconds))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: entry.kind == .app ? "macwindow" : "network")
                        .foregroundColor(entry.kind == .app ? .blue : .purple)
                    Text(entry.name)
                        .font(.subheadline)
                }

                if let detail = entry.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds / 60)
        if mins >= 60 {
            return "\(mins / 60)h \(mins % 60)m"
        }
        return "\(mins)m"
    }
}
