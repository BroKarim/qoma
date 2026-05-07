import SwiftUI

struct AnalyticsHeatmapView: View {
    let cells: [AnalyticsHeatmapCell]

    private let intensityColors: [Color] = [
        Color.gray.opacity(0.15),
        Color.green.opacity(0.3),
        Color.green.opacity(0.5),
        Color.green.opacity(0.7),
        Color.green.opacity(0.85),
        Color.green,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 30 Days")
                .font(.headline)

            let columns = Array(cells.chunked(into: 7))
            VStack(spacing: 2) {
                ForEach(columns.indices, id: \.self) { colIndex in
                    HStack(spacing: 2) {
                        ForEach(columns[colIndex], id: \.id) { cell in
                            Rectangle()
                                .fill(intensityColors[cell.intensityLevel])
                                .frame(width: 16, height: 16)
                                .cornerRadius(2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                                )
                                .help("\(formatDate(cell.date)): \(Int(cell.focusSeconds / 60))m focus")
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                ForEach(0..<5, id: \.self) { level in
                    Rectangle()
                        .fill(intensityColors[level])
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                }
                Text("More")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
