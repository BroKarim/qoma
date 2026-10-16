import SwiftUI

struct CatchTimelineView: View {
    let events: [CatchEvent]

    private var latestFirst: [CatchEvent] {
        self.events.sorted {
            $0.depositedAt == $1.depositedAt
                ? $0.id.uuidString > $1.id.uuidString
                : $0.depositedAt > $1.depositedAt
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Catch timeline")
                .font(.system(size: 22, design: .serif))
            Text("Latest first")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(self.latestFirst) { event in
                        CatchTimelineRowView(event: event, isLast: event.id == self.latestFirst.last?.id)
                    }
                }
            }
            .qyubeScrollIndicator()
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 340, maxHeight: 340, alignment: .topLeading)
        .background(Color.qyubeCardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.qyubeLine, lineWidth: 0.7))
    }
}
