import SwiftUI

struct AnalyticsConsentSheet: View {
    let onDecision: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color.qyubeAccent)
                .accessibilityHidden(true)
            Text("Help you reflect on your focus?")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            Text("qyube can record the apps you use during a focus session, and websites when browser access is enabled. This activity stays on this Mac. You can change this choice in Settings.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Allow activity tracking") { decide(true) }
                .buttonStyle(.borderedProminent)
                .tint(.qyubeAccent)
                .frame(maxWidth: .infinity)
            Button("Keep it off") { decide(false) }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
        .padding(28)
        .frame(width: 420)
        .accessibilityElement(children: .contain)
        .interactiveDismissDisabled()
    }

    private func decide(_ enabled: Bool) {
        AppConstants.AnalyticsSettings.isAnalyticsEnabled = enabled
        onDecision(enabled)
        dismiss()
    }
}
