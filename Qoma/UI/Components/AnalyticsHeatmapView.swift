import SwiftUI

struct AnalyticsHeatmapView: View {
    let cells: [AnalyticsHeatmapCell]
    @Binding var selectedDate: Date

    private var weeks: [[AnalyticsHeatmapCell]] {
        self.cells.chunked(into: 7)
    }

    private let cellSpacing: CGFloat = 5
    private let minimumCellSize: CGFloat = 12
    private let maximumCellSize: CGFloat = 17

    private let colors: [Color] = [
        Color(red: 235 / 255, green: 238 / 255, blue: 240 / 255),
        Color(red: 223 / 255, green: 234 / 255, blue: 240 / 255),
        Color(red: 196 / 255, green: 220 / 255, blue: 230 / 255),
        Color(red: 154 / 255, green: 191 / 255, blue: 207 / 255),
        Color(red: 113 / 255, green: 156 / 255, blue: 174 / 255),
        Color(red: 82 / 255, green: 115 / 255, blue: 134 / 255),
    ]

    var body: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Focus Activity").font(.system(size: 23, design: .serif))
                    Spacer()
                    Text("Choose a day").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                QyubeInkDivider()
                GeometryReader { geometry in
                    let cellSize = self.cellSize(for: geometry.size.width)
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal) {
                            HStack(alignment: .top, spacing: self.cellSpacing) {
                                ForEach(self.weeks, id: \.first?.id) { week in
                                    VStack(spacing: self.cellSpacing) {
                                        ForEach(week) { cell in self.cellButton(cell, size: cellSize) }
                                        Text(self.monthLabel(week)).font(.system(size: 9)).foregroundStyle(.secondary)
                                            .frame(height: 14).fixedSize()
                                    }
                                    .frame(width: cellSize)
                                    .id(week.first?.id)
                                }
                            }
                            .padding(3)
                        }
                        .qyubeHorizontalScrollIndicator()
                        .onAppear { proxy.scrollTo(self.weeks.last?.first?.id, anchor: .trailing) }
                    }
                }
                .frame(height: 7 * self.maximumCellSize + 6 * self.cellSpacing + 14 + 6)
                HStack(spacing: 5) {
                    Text("Less")
                    ForEach(0..<self.colors.count, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 2).fill(self.colors[level]).frame(width: 12, height: 12)
                    }
                    Text("More focus")
                    Spacer()
                    Button("First day") {
                        self.selectedDate = self.cells.first?.date ?? Calendar.current.startOfDay(for: Date())
                    }
                        .buttonStyle(.plain).foregroundStyle(Color.qyubeAccent)
                }
                .font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
    }

    private func monthLabel(_ week: [AnalyticsHeatmapCell]) -> String {
        guard let day = week.first?.date else { return "" }
        if day == self.cells.first?.date {
            return day.formatted(.dateTime.month(.abbreviated))
        }
        return week.first { Calendar.current.component(.day, from: $0.date) == 1 }?
            .date.formatted(.dateTime.month(.abbreviated)) ?? ""
    }

    private func cellSize(for availableWidth: CGFloat) -> CGFloat {
        let weekCount = CGFloat(max(self.weeks.count, 1))
        let availableForCells = availableWidth - 6 - (weekCount - 1) * self.cellSpacing
        return min(self.maximumCellSize, max(self.minimumCellSize, availableForCells / weekCount))
    }

    private func cellButton(_ cell: AnalyticsHeatmapCell, size: CGFloat) -> some View {
        let selected = Calendar.current.isDate(cell.date, inSameDayAs: self.selectedDate)
        let future = Calendar.current.startOfDay(for: cell.date) > Calendar.current.startOfDay(for: Date())
        return Button { self.selectedDate = Calendar.current.startOfDay(for: cell.date) } label: {
            RoundedRectangle(cornerRadius: 3)
                .fill(self.colors[min(max(cell.intensityLevel, 0), self.colors.count - 1)])
                .frame(width: size, height: size)
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
