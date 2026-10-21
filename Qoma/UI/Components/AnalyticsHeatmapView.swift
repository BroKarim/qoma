import SwiftUI

struct AnalyticsHeatmapView: View {
    let cells: [AnalyticsHeatmapCell]
    @Binding var selectedDate: Date
    @State private var gridWidth: CGFloat = 0

    private var weeks: [[AnalyticsHeatmapCell]] {
        self.cells.chunked(into: 7)
    }

    private let minimumCellSize: CGFloat = 8
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
        VStack(alignment: .leading, spacing: 10) {
            self.legend
            GeometryReader { geometry in
                self.grid(availableWidth: max(0, geometry.size.width - 30))
            }
            .frame(height: self.gridHeight)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { self.gridWidth = $0 }
        }
    }

    private var legend: some View {
        HStack(spacing: 5) {
            Spacer()
            Text("Less focus")
            ForEach(0..<self.colors.count, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2).fill(self.colors[level]).frame(width: 12, height: 12)
            }
            Text("More focus")
        }
        .font(.system(size: 10, design: .serif)).foregroundStyle(.secondary)
    }

    private func grid(availableWidth: CGFloat) -> some View {
        let spacing = self.cellSpacing(for: availableWidth)
        let cellSize = self.cellSize(for: availableWidth, spacing: spacing)
        let contentWidth = CGFloat(self.weeks.count) * (cellSize + spacing) - spacing + 6
        return HStack(alignment: .top, spacing: 6) {
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(0..<7) { row in
                    Text(self.weekdayLabel(row))
                        .font(.system(size: 9, design: .serif))
                        .foregroundStyle(.secondary)
                        .frame(height: cellSize)
                }
            }.frame(width: 24).padding(.top, 3).accessibilityHidden(true)
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(self.weeks, id: \.first?.id) { week in
                            VStack(spacing: spacing) {
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
                .scrollIndicators(contentWidth > availableWidth + 0.5 ? .visible : .hidden)
                .onAppear { proxy.scrollTo(self.weeks.last?.first?.id, anchor: .trailing) }
            }
        }
    }

    private func weekdayLabel(_ row: Int) -> String {
        guard let date = self.weeks.first?[safe: row]?.date else { return "" }
        return date.formatted(.dateTime.weekday(.abbreviated))
    }

    private var gridHeight: CGFloat {
        let width = max(0, self.gridWidth - 30)
        let spacing = self.cellSpacing(for: width)
        let size = self.cellSize(for: width, spacing: spacing)
        let contentWidth = CGFloat(self.weeks.count) * (size + spacing) - spacing + 6
        return 7 * size + 7 * spacing + 20 + (contentWidth > width + 0.5 ? 12 : 0)
    }

    private func monthLabel(_ week: [AnalyticsHeatmapCell]) -> String {
        return week.first { Calendar.current.component(.day, from: $0.date) == 1 }?
            .date.formatted(.dateTime.month(.abbreviated)) ?? ""
    }

    private func cellSpacing(for availableWidth: CGFloat) -> CGFloat {
        min(5, max(2, (availableWidth - 6) / CGFloat(max(self.weeks.count, 1)) * 0.22))
    }

    private func cellSize(for availableWidth: CGFloat, spacing: CGFloat) -> CGFloat {
        let weekCount = CGFloat(max(self.weeks.count, 1))
        let availableForCells = availableWidth - 6 - (weekCount - 1) * spacing
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
