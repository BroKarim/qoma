import SwiftUI

struct AnalyticsBreakdownView: View {
    let todayApps: [AnalyticsBreakdownItem]
    let todayDomains: [AnalyticsBreakdownItem]
    let weekApps: [AnalyticsBreakdownItem]
    let weekDomains: [AnalyticsBreakdownItem]
    @State private var selectedRange: BreakdownRange = .today

    enum BreakdownRange: String, CaseIterable {
        case today = "Today"
        case week = "7 Days"
    }

    var body: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Breakdown",
                    subtitle: "See which apps and sites take most of your tracked focus time.")

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
                        if self.visibleApps.isEmpty {
                            Text("No app data in this range")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(self.visibleApps.prefix(5)) { item in
                                BreakdownRow(item: item)
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top Websites")
                            .font(.headline)
                        if self.visibleDomains.isEmpty {
                            Text("No website data in this range")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(self.visibleDomains.prefix(5)) { item in
                                BreakdownRow(item: item)
                            }
                        }
                    }
                }
            }
        }
    }

    private var visibleApps: [AnalyticsBreakdownItem] {
        switch self.selectedRange {
        case .today:
            self.todayApps
        case .week:
            self.weekApps
        }
    }

    private var visibleDomains: [AnalyticsBreakdownItem] {
        switch self.selectedRange {
        case .today:
            self.todayDomains
        case .week:
            self.weekDomains
        }
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
