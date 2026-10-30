import SwiftUI

struct QyubeSettingsMenuPopover: View {
    let onSettings: () -> Void
    let onManageSubscription: () -> Void
    let onSignOut: () -> Void
    let canSignOut: Bool
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            QyubeSettingsMenuItem(title: "Settings", image: "QyubeMenuSettings", action: self.onSettings)
            QyubeSettingsMenuItem(title: "Manage subscription", image: "QyubeMenuSubscription", action: self.onManageSubscription)
            if canSignOut {
                QyubeSettingsMenuItem(title: "Sign out", image: "QyubeMenuSignOut", action: self.onSignOut)
            }
            QyubeSettingsMenuItem(title: "Help", image: "QyubeMenuHelp") {}
            QyubeSettingsMenuItem(title: "Give feedback", image: "QyubeMenuFeedback") {}

            // QyubeInkDivider().frame(height: 3).padding(.horizontal, 6).padding(.vertical, 1)
            QyubeSettingsMenuItem(title: "Quit", image: "QyubeMenuQuit", action: self.onQuit)
        }
        .padding(4)
        .frame(width: 168)
        .background(Color.qyubeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            QyubeInkBorder().stroke(Color.qyubeMenuInk.opacity(0.8), lineWidth: 1.0)
                .padding(1)
                .allowsHitTesting(false)
        }
        .foregroundStyle(Color.qyubeMenuInk)
        .environment(\.colorScheme, .light)
    }
}

private struct QyubeSettingsMenuItem: View {
    let title: String
    let image: String
    var action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 7) {
                Image(self.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)
                Text(self.title)
                    .font(.system(size: 10.5, weight: .medium))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
            .frame(height: 26)
            .contentShape(QyubeInkBorder())
            .background {
                if self.isHovered {
                    QyubeInkBorder().fill(Color.qyubeSelection.opacity(0.72))
                }
            }
            .overlay {
                if self.isHovered {
                    QyubeInkBorder().stroke(Color.qyubeAccent.opacity(0.3), lineWidth: 0.7)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { self.isHovered = $0 }
        .accessibilityLabel(self.title)
    }
}
