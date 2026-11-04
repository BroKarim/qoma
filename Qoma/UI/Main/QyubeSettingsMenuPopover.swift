import AppKit
import SwiftUI

struct QyubeSettingsMenuPopover: View {
    let onSettings: () -> Void
    let onAccountPurchases: () -> Void
    let onSignOut: () async -> String?
    let canSignOut: Bool
    let showTrialReassurance: Bool
    let onQuit: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingSignOut = false
    @State private var isSigningOut = false
    @State private var signOutError: String?

    var body: some View {
        Group {
            if isConfirmingSignOut {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sign out of Qyube?")
                        .font(.system(size: 12, weight: .semibold))
                    Text("You’ll need to sign in again to use Qyube on this Mac.")
                        .font(.system(size: 10.5))
                    if showTrialReassurance {
                        Text("Signing out won’t reset your trial.")
                            .font(.system(size: 9.5))
                            .foregroundStyle(.secondary)
                    }
                    if let signOutError {
                        Text(signOutError)
                            .font(.system(size: 9.5))
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(spacing: 6) {
                        Button("Stay signed in", role: .cancel) {
                            self.isConfirmingSignOut = false
                        }
                        .keyboardShortcut(.cancelAction)
                        .buttonStyle(.bordered)
                        Button(self.isSigningOut ? "Signing out…" : "Sign out", role: .destructive) {
                            Task {
                                self.isSigningOut = true
                                self.signOutError = await self.onSignOut()
                                self.isSigningOut = false
                                if self.signOutError == nil { self.dismiss() }
                            }
                        }
                        .disabled(self.isSigningOut)
                        .buttonStyle(.borderedProminent)
                        .tint(Color.qyubeMenuInk)
                    }
                }
                .padding(10)
                .frame(width: 236, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    QyubeSettingsMenuItem(title: "Settings", image: "QyubeMenuSettings", action: self.onSettings)
                    QyubeSettingsMenuItem(title: "Account & purchases", image: "QyubeMenuSubscription", action: self.onAccountPurchases)
                    if canSignOut {
                        QyubeSettingsMenuItem(title: "Sign out", image: "QyubeMenuSignOut") {
                            self.signOutError = nil
                            self.isConfirmingSignOut = true
                        }
                    }
                    QyubeSettingsMenuItem(title: "Help", image: "QyubeMenuHelp") {
                        NSWorkspace.shared.open(SupportLinks.help)
                    }
                    QyubeSettingsMenuItem(title: "Give feedback", image: "QyubeMenuFeedback") {
                        NSWorkspace.shared.open(SupportLinks.feedback)
                    }

                    QyubeSettingsMenuItem(title: "Quit", image: "QyubeMenuQuit", action: self.onQuit)
                }
            }
        }
        .padding(4)
        .frame(width: self.isConfirmingSignOut ? 244 : 168)
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
