import SwiftUI

struct QyubeCompactHeader: View {
    let onToday: () -> Void
    let onAnalytics: () -> Void
    let onCatalog: () -> Void
    let onSettings: () -> Void
    let onManageSubscription: () -> Void
    let onSignOut: () -> Void
    let canSignOut: Bool
    let onQuit: () -> Void
    @State private var isSettingsPopoverPresented = false

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
                Button("Settings", systemImage: "gearshape") {
                    self.isSettingsPopoverPresented.toggle()
                }
                    .labelStyle(.iconOnly)
                    .frame(width: 24, height: 30)
                    .help("More options")
                    .popover(isPresented: self.$isSettingsPopoverPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                        QyubeSettingsMenuPopover(
                            onSettings: {
                                self.isSettingsPopoverPresented = false
                                self.onSettings()
                            },
                            onManageSubscription: {
                                self.isSettingsPopoverPresented = false
                                self.onManageSubscription()
                            },
                            onSignOut: {
                                self.isSettingsPopoverPresented = false
                                self.onSignOut()
                            },
                            canSignOut: self.canSignOut,
                            onQuit: {
                                self.isSettingsPopoverPresented = false
                                self.onQuit()
                            })
                            .presentationBackground(.clear)
                            .preferredColorScheme(.light)
                    }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.qyubeMenuInk)
        }
    }
}
