import SwiftUI

struct AnalyticsEmptyStateView: View {
    var message: String = "No data yet"
    var subtitle: String = "Start a focus session to begin tracking your activity."

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(message)
                .font(.headline)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
