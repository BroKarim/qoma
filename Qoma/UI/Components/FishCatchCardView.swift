import SwiftUI

struct FishCatchCardView: View {
    let summary: DailyCatchSummary

    private var kind: CatalogDefinitions.Kind? {
        CatalogDefinitions.kind(id: self.summary.kindID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottom) {
                QyubeInkBorder()
                    .fill(Color.qyubeLine.opacity(0.7))
                    .frame(height: 7)
                    .padding(.horizontal, 6)
                QyubeCatchArt(kindID: self.summary.kindID)
                    .frame(maxWidth: .infinity)
                    .frame(height: 76)
                    .padding(.bottom, 4)
            }

            Text(self.kind?.name ?? "Unknown find")
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .lineLimit(1)

            HStack(spacing: 6) {
                Circle()
                    .fill(self.kind?.rarity.color ?? Color.secondary)
                    .frame(width: 7, height: 7)
                Text(self.kind?.rarity.rawValue.capitalized ?? "Uncatalogued")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text("× \(self.summary.events.count)")
                    .font(.system(size: 16, design: .serif))
                    .monospacedDigit()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 154, maxHeight: 154, alignment: .topLeading)
        .qyubeInkSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(self.kind?.name ?? "Unknown find"), "
                + "\(self.kind?.rarity.rawValue.capitalized ?? "uncatalogued"), "
                + "\(self.summary.events.count) caught")
    }
}
