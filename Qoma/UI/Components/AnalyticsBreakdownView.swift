import SwiftUI

struct AnalyticsBreakdownView: View {
    let date: Date
    let apps: [AnalyticsBreakdownItem]
    let domains: [AnalyticsBreakdownItem]
    let showsDomains: Bool
    @ObservedObject private var permissions = AnalyticsPermissionsManager.shared

    var body: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                SettingsSectionHeading(
                    title: "Daily Breakdown",
                    subtitle: "Where your focus went on \(self.date.formatted(.dateTime.day().month(.wide))).")
                QyubeInkDivider()
                if self.showsDomains {
                    HStack(alignment: .top, spacing: 24) {
                        self.column("Top Apps", items: self.apps, empty: "No app activity on this day.")
                        QyubeInkDivider(axis: .vertical).frame(width: 2)
                        VStack(alignment: .leading, spacing: 12) {
                            self.column("Top Websites", items: self.domains, empty: "No website activity on this day.")
                            if self.domains.isEmpty, self.permissions.automationPermissionStatus != .granted {
                                Text("Website tracking needs Automation permission. App activity works without it.")
                                    .font(.system(size: 11)).foregroundStyle(.secondary)
                                Button("Open Automation Settings") { self.permissions.openSystemPreferences() }
                                    .font(.system(size: 11))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    self.column("Top Apps", items: self.apps, empty: "No app activity on this day.")
                }
            }
        }
    }

    private func column(_ title: String, items: [AnalyticsBreakdownItem], empty: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.system(size: 21, design: .serif))
            if items.isEmpty {
                Text(empty).font(.system(size: 12)).foregroundStyle(.secondary).padding(.vertical, 20)
            } else {
                ForEach(items) { item in
                    VStack(spacing: 9) {
                        HStack(spacing: 10) {
                            AnalyticsIconView(
                                type: item.isWebsite
                                    ? .website(domain: item.name, iconData: item.iconData)
                                    : .app(bundleID: item.bundleID ?? item.name, iconData: item.iconData),
                                size: 26)
                            Text(item.name).font(.system(size: 12)).lineLimit(1).truncationMode(.middle)
                            Spacer(minLength: 4)
                            Text(item.displayDuration).font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                        GeometryReader { geometry in
                            Capsule().fill(Color.qyubeLine.opacity(0.5))
                            Capsule().fill(Color.qyubeAccent.opacity(0.65))
                                .frame(width: geometry.size.width * min(1, max(0, item.percentage / 100)))
                        }.frame(height: 6)
                    }.accessibilityElement(children: .combine)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
