import SwiftUI

struct AnalyticsHeatmapView: View {
    let cells: [AnalyticsHeatmapCell]
    @Binding var selectedDate: Date

    private var weeks: [[AnalyticsHeatmapCell]] {
        self.cells.chunked(into: 7)
    }

    private let colors: [Color] = [
        Color(white: 0.92), Color(red: 0.85, green: 0.89, blue: 0.84),
        Color(red: 0.74, green: 0.81, blue: 0.73), Color(red: 0.62, green: 0.73, blue: 0.62),
        Color(red: 0.48, green: 0.63, blue: 0.51), Color(red: 0.33, green: 0.48, blue: 0.37),
    ]

    var body: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Focus Activity").font(.system(size: 23, design: .serif))
                    Spacer()
                    Text("Choose a day").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Divider()
                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 5) {
                            ForEach(self.weeks, id: \.first?.id) { week in
                                VStack(spacing: 5) {
                                    ForEach(week) { cell in self.cellButton(cell) }
                                    Text(self.monthLabel(week)).font(.system(size: 9)).foregroundStyle(.secondary)
                                        .frame(height: 14).fixedSize()
                                }
                                .frame(width: 17)
                                .id(week.first?.id)
                            }
                        }
                        .padding(3)
                    }
                    .onAppear { proxy.scrollTo(self.weeks.last?.first?.id, anchor: .trailing) }
                }
                HStack(spacing: 5) {
                    Text("Less")
                    ForEach(0..<self.colors.count, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2).fill(self.colors[level]).frame(width: 12, height: 12)
                    }
                    Text("More focus")
                    Spacer()
                    Button("Today") { self.selectedDate = Calendar.current.startOfDay(for: Date()) }
                        .buttonStyle(.plain).foregroundStyle(Color.qyubeAccent)
                }
                .font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
    }

    private func monthLabel(_ week: [AnalyticsHeatmapCell]) -> String {
        guard let day = week.first?.date else { return "" }
        let isFirst = day == self.cells.first?.date
        let startsMonth = week.contains { Calendar.current.component(.day, from: $0.date) == 1 }
        return isFirst || startsMonth ? (week.last?.date ?? day).formatted(.dateTime.month(.abbreviated)) : ""
    }

    private func cellButton(_ cell: AnalyticsHeatmapCell) -> some View {
        let selected = Calendar.current.isDate(cell.date, inSameDayAs: self.selectedDate)
        let future = Calendar.current.startOfDay(for: cell.date) > Calendar.current.startOfDay(for: Date())
        return Button { self.selectedDate = Calendar.current.startOfDay(for: cell.date) } label: {
            RoundedRectangle(cornerRadius: 3)
                .fill(self.colors[min(max(cell.intensityLevel, 0), self.colors.count - 1)])
                .frame(width: 17, height: 17)
                .overlay(RoundedRectangle(cornerRadius: 3)
                    .stroke(selected ? Color.qyubeAccent : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain).disabled(future).opacity(future ? 0.3 : 1)
        .accessibilityLabel(
            cell.date.formatted(date: .complete, time: .omitted) + ", "
                + QyubeFormat.duration(cell.focusSeconds) + ", \(cell.sessionCount) sessions")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .help("\(cell.date.formatted(date: .abbreviated, time: .omitted)) · \(QyubeFormat.duration(cell.focusSeconds))")
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }

    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
