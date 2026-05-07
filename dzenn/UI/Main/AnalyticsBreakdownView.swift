import SwiftUI

struct AnalyticsBreakdownView: View {
    let apps: [AnalyticsBreakdownItem]
    let domains: [AnalyticsBreakdownItem]
    @State private var selectedRange: BreakdownRange = .today

    enum BreakdownRange: String, CaseIterable {
        case today = "Today"
        case week = "7 Days"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Range", selection: $selectedRange) {
                ForEach(BreakdownRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Apps")
                        .font(.headline)
                    if apps.isEmpty {
                        Text("No app data yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(apps.prefix(5)) { item in
                            BreakdownRow(item: item)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Websites")
                        .font(.headline)
                    if domains.isEmpty {
                        Text("No website data yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(domains.prefix(5)) { item in
                            BreakdownRow(item: item)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct BreakdownRow: View {
    let item: AnalyticsBreakdownItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.name)
                    .font(.subheadline)
                Spacer()
                Text(item.displayDuration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(String(format: "%.0f%%", item.percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
            }

            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.accentColor.opacity(0.6))
                    .frame(width: geometry.size.width * (item.percentage / 100.0))
                    .frame(height: 4)
                    .cornerRadius(2)
            }
            .frame(height: 4)
        }
        .padding(.vertical, 4)
    }
}
