import SwiftUI
import Combine

struct AnalyticsBreakdownView: View {
    let date: Date
    let apps: [AnalyticsBreakdownItem]
    let domains: [AnalyticsBreakdownItem]
    @State private var automationStatus = AutomationStatus()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }()

    var body: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionHeading(
                    title: "Daily Breakdown",
                    subtitle: "Top apps and websites for \(Self.dayFormatter.string(from: self.date)).")

                if !self.automationStatus.hasAutomationAccess && self.domains.isEmpty {
                    self.websiteTrackingDisabledView
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        BreakdownColumn(
                            title: "Top Apps",
                            icon: "macwindow",
                            items: self.apps,
                            emptyMessage: "No app activity on this day.")

                        BreakdownColumn(
                            title: "Top Websites",
                            icon: "network",
                            items: self.domains,
                            emptyMessage: "No website activity on this day.")
                    }
                }
            }
        }
        .onAppear {
            self.automationStatus.refresh()
        }
    }

    @ViewBuilder
    private var websiteTrackingDisabledView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Website tracking disabled")
                .font(.headline)

            Text("Dzenn needs Automation permission to track Safari and Chrome tabs. Without this, only app names will be recorded.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                self.automationStatus.openSystemSettings()
            }) {
                HStack {
                    Image(systemName: "gearshape")
                    Text("Open System Settings")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .padding()
    }
}

private class AutomationStatus: ObservableObject {
    @Published var hasAutomationAccess = false

    func refresh() {
        let status = AXIsProcessTrusted()
        hasAutomationAccess = status
    }

    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }
}

private struct BreakdownColumn: View {
    let title: String
    let icon: String
    let items: [AnalyticsBreakdownItem]
    let emptyMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(self.title, systemImage: self.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            if self.items.isEmpty {
                Text(self.emptyMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(self.items) { item in
                        BreakdownRow(item: item)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.025)))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

private struct BreakdownRow: View {
    let item: AnalyticsBreakdownItem

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(self.item.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer(minLength: 12)

                Text(self.item.displayDuration)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.06))

                    Capsule(style: .continuous)
                        .fill(Color.green.opacity(0.8))
                        .frame(width: max(proxy.size.width * CGFloat(self.item.percentage / 100), 10))
                }
            }
            .frame(height: 7)

            Text("\(Int(self.item.percentage.rounded()))% of tracked time")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
