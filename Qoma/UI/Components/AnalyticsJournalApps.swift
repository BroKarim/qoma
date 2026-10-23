import SwiftUI

struct AnalyticsJournalApps: View {
    let apps: [AnalyticsBreakdownItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            AnalyticsJournalHeading(title: "Top apps", detail: "TRACKED TIME")
            if apps.isEmpty {
                Text("No app activity recorded on this day.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(apps) { app in
                    HStack(spacing: 9) {
                        AnalyticsIconView(
                            type: .app(bundleID: app.bundleID ?? app.name, iconData: app.iconData), size: 26)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(app.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text(app.displayDuration)
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundStyle(Color.qyubeAccent)
                                    .monospacedDigit()
                                    .fixedSize()
                            }
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.qyubeSelection)
                                    Capsule().fill(Color.qyubeAccent.opacity(0.7))
                                        .frame(width: geometry.size.width * min(1, max(0, app.percentage / 100)))
                                }
                            }
                            .frame(height: 3)
                            .accessibilityHidden(true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

\n