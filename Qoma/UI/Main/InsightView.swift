import SwiftUI

struct InsightView: View {
    let accountID: String = "local"
    @State private var selectedPeriod: Period = .day

    private var history: [FocusSession] {
        SessionRepository.shared.loadHistory(accountID: accountID)
    }

    private var bankedCatches: [CatchEvent] {
        CatchRepository.shared.listBanked(accountID: accountID)
    }

    private var aggregator: InsightAggregator {
        InsightAggregator(history: history, catches: bankedCatches)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Insight")
                .font(.system(size: 24, weight: .semibold))

            Picker("", selection: $selectedPeriod) {
                Text("Day").tag(Period.day)
                Text("Week").tag(Period.week)
                Text("Month").tag(Period.month)
                Text("Year").tag(Period.year)
            }
            .pickerStyle(.segmented)

            switch selectedPeriod {
            case .day:
                DayInsightList(days: aggregator.daySummaries())
            case .week:
                PeriodInsightView(summary: aggregator.summary(for: .weekOfYear, value: 0))
            case .month:
                PeriodInsightView(summary: aggregator.summary(for: .month, value: 0))
            case .year:
                PeriodInsightView(summary: aggregator.summary(for: .year, value: 0))
            }

            Spacer(minLength: 0)
        }
    }

    enum Period: String, CaseIterable {
        case day, week, month, year
    }
}

private struct DayInsightList: View {
    let days: [InsightAggregator.DaySummary]

    var body: some View {
        if days.isEmpty {
            Text("No sessions yet.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(days.reversed(), id: \.date) { day in
                        DayInsightCard(day: day)
                    }
                }
            }
        }
    }
}

private struct DayInsightCard: View {
    let day: InsightAggregator.DaySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedDate)
                .font(.system(size: 13, weight: .medium))
            HStack(spacing: 16) {
                InsightMetric(label: "Focus", value: "\(Int(day.focusSeconds / 60))m")
                InsightMetric(label: "Done", value: "\(day.completedSessions)")
                InsightMetric(label: "Stopped", value: "\(day.interruptedSessions)")
                InsightMetric(label: "Catches", value: "\(day.catchCount)")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.06))
        )
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: day.date)
    }
}

private struct PeriodInsightView: View {
    let summary: InsightAggregator.PeriodSummary?

    var body: some View {
        if let summary = summary {
            VStack(alignment: .leading, spacing: 16) {
                Text(summary.period)
                    .font(.system(size: 17, weight: .semibold))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    InsightCard(title: "Focus time", value: "\(Int(summary.focusSeconds / 60)) min")
                    InsightCard(title: "Completed", value: "\(summary.completedSessions)")
                    InsightCard(title: "Interrupted", value: "\(summary.interruptedSessions)")
                    InsightCard(title: "Catches", value: "\(summary.catchCount)")
                }

                if !summary.topTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top tasks")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        ForEach(summary.topTasks, id: \.title) { task in
                            HStack {
                                Text(task.title)
                                    .font(.system(size: 12))
                                Spacer()
                                Text("\(Int(task.seconds / 60)) min")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        } else {
            Text("No data for this period.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
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

private struct InsightMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .semibold))
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
