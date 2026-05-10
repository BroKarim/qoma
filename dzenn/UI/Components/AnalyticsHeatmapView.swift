import SwiftUI

struct AnalyticsHeatmapView: View {
    let cells: [AnalyticsHeatmapCell]
    @Binding var selectedDate: Date

    private let intensityColors: [Color] = [
        Color(red: 0.20, green: 0.21, blue: 0.22),
        Color(red: 0.28, green: 0.31, blue: 0.32),
        Color(red: 0.34, green: 0.42, blue: 0.39),
        Color(red: 0.44, green: 0.55, blue: 0.48),
        Color(red: 0.58, green: 0.71, blue: 0.58),
        Color(red: 0.74, green: 0.84, blue: 0.68),
    ]
    private let rowSpacing: CGFloat = 3
    private let columnSpacing: CGFloat = 3

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    var body: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                self.header

                if self.weekColumns.isEmpty {
                    Text("No focus history yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    GeometryReader { proxy in
                        let metrics = self.gridMetrics(for: proxy.size.width)

                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top, spacing: self.columnSpacing) {
                                ForEach(Array(self.weekColumns.enumerated()), id: \.offset) { _, week in
                                    VStack(spacing: self.rowSpacing) {
                                        ForEach(week, id: \.id) { cell in
                                            self.heatmapCell(cell, metrics: metrics)
                                        }
                                    }
                                    .frame(width: metrics.columnWidth)
                                }
                            }

                            self.monthAxis(metrics: metrics)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                    .frame(height: self.gridHeight)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Activity")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)

            Spacer(minLength: 16)

            if let selectedCell = self.selectedCell {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Self.dayFormatter.string(from: selectedCell.date))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.82))

                    Text("\(Int(selectedCell.focusSeconds / 60)) min focus")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var weekColumns: [[AnalyticsHeatmapCell]] {
        self.cells.chunked(into: 7)
    }

    private var gridHeight: CGFloat {
        let rows = 7
        let cellSize: CGFloat = 12
        let monthAxisHeight: CGFloat = 20
        return (CGFloat(rows) * cellSize) + (CGFloat(rows - 1) * self.rowSpacing) + monthAxisHeight
    }

    private var selectedCell: AnalyticsHeatmapCell? {
        self.cells.first { Calendar.current.isDate($0.date, inSameDayAs: self.selectedDate) }
    }

    private func monthAxis(metrics: GridMetrics) -> some View {
        HStack(alignment: .center, spacing: self.columnSpacing) {
            ForEach(Array(self.weekColumns.enumerated()), id: \.offset) { index, week in
                Text(self.monthLabel(for: week, index: index) ?? "")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary.opacity(0.78))
                    .frame(width: metrics.columnWidth, alignment: .leading)
            }
        }
    }

    private func heatmapCell(_ cell: AnalyticsHeatmapCell, metrics: GridMetrics) -> some View {
        let isSelected = Calendar.current.isDate(cell.date, inSameDayAs: self.selectedDate)

        return Button {
            self.selectedDate = cell.date
        } label: {
            RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                .fill(self.intensityColors[cell.intensityLevel])
                .frame(width: metrics.cellSize, height: metrics.cellSize)
                .overlay(
                    RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                        .stroke(
                            isSelected
                                ? Color(red: 0.56, green: 0.71, blue: 0.58)
                                : Color.black.opacity(0.18),
                            lineWidth: isSelected ? 1.8 : 0.8))
                .shadow(
                    color: isSelected ? Color(red: 0.56, green: 0.71, blue: 0.58).opacity(0.22) : .clear,
                    radius: 6,
                    y: 1)
        }
        .buttonStyle(.plain)
        .frame(width: metrics.columnWidth, alignment: .center)
        .help("\(self.formatDate(cell.date)): \(Int(cell.focusSeconds / 60))m focus")
    }

    private func monthLabel(for week: [AnalyticsHeatmapCell], index: Int) -> String? {
        guard let firstDay = week.first?.date else { return nil }

        if index == 0 {
            return Self.monthFormatter.string(from: firstDay)
        }

        guard let previousWeek = self.weekColumns[safe: index - 1],
              let previousDay = previousWeek.first?.date else {
            return Self.monthFormatter.string(from: firstDay)
        }

        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: firstDay)
        let previousMonth = calendar.component(.month, from: previousDay)
        if currentMonth != previousMonth {
            return Self.monthFormatter.string(from: firstDay)
        }

        return nil
    }

    private func formatDate(_ date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    private func gridMetrics(for width: CGFloat) -> GridMetrics {
        let safeWidth = max(width, 320)
        let columnCount = max(CGFloat(self.weekColumns.count), 1)
        let totalSpacing = CGFloat(max(self.weekColumns.count - 1, 0)) * self.columnSpacing
        let columnWidth = (safeWidth - totalSpacing) / columnCount
        let cellSize = min(12, max(10, columnWidth * 0.6))

        return GridMetrics(
            cellSize: cellSize,
            columnWidth: max(columnWidth, cellSize),
            cornerRadius: min(3, max(2, cellSize * 0.2)))
    }
}

private struct GridMetrics {
    let cellSize: CGFloat
    let columnWidth: CGFloat
    let cornerRadius: CGFloat
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }

    subscript(safe index: Int) -> Element? {
        guard self.indices.contains(index) else { return nil }
        return self[index]
    }
}
