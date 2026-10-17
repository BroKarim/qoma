import SwiftUI

struct CatchTimelineRowView: View {
    let event: CatchEvent
    let isLast: Bool

    private var name: String {
        CatalogDefinitions.kind(id: self.event.kindID)?.name ?? "Unknown find"
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(self.isLast ? Color.clear : Color.qyubeLine)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .padding(.top, 12)
                Circle()
                    .fill(Color.qyubeAccent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 7)
            }
            .frame(width: 10)

            Text(self.event.depositedAt, format: .dateTime.hour().minute())
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            QyubeCatchArt(kindID: self.event.kindID)
                .frame(width: 36, height: 30)
                .padding(5)
                .qyubeInkSurface(fill: .qyubeBackground, stroke: .qyubeLine, lineWidth: 0.7)

            Text(self.name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 54)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(self.name), caught at " + self.event.depositedAt.formatted(.dateTime.hour().minute()))
    }
}
