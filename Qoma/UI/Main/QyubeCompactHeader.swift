import SwiftUI

struct QyubeCompactHeader: View {
    let onToday: () -> Void
    let onAnalytics: () -> Void
    let onCatalog: () -> Void
    let onSettings: () -> Void

    var body: some View {
        QyubeInkHeader(title: "qyube", titleAction: self.onToday) {
            HStack(spacing: 4) {
                Button("Analytics", systemImage: "chart.bar.xaxis", action: self.onAnalytics)
                    .labelStyle(.iconOnly)
                    .frame(width: 24, height: 30)
                    .help("Analytics")
                Button("Catalog", systemImage: "archivebox", action: self.onCatalog)
                    .labelStyle(.iconOnly)
                    .frame(width: 24, height: 30)
                    .help("Catalog")
                Button("Settings", systemImage: "gearshape", action: self.onSettings)
                    .labelStyle(.iconOnly)
                    .frame(width: 24, height: 30)
                    .help("Settings")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.qyubeMenuInk)
        }
    }
}
