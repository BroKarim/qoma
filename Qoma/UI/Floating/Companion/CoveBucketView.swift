import SwiftUI

struct CoveBucketView: View {
    let events: () -> [CatchEvent]
    let previouslyCaughtKinds: Set<String>
    let onCatalog: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let catches = events()
            let groups = Dictionary(grouping: catches, by: \.kindID)
            VStack(alignment: .leading, spacing: 12) {
                Text("This session").font(.headline)
                Text("\(catches.count) catches · \(groups.count) species")
                    .font(.subheadline).foregroundStyle(.secondary)
                let discoveries = Set(groups.keys).subtracting(previouslyCaughtKinds).count
                if discoveries > 0 {
                    Text("\(discoveries) new discoveries").font(.caption).foregroundStyle(Color.qyubeAccent)
                }
                if catches.isEmpty {
                    Text("Waiting for the first catch").foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [.init(.adaptive(minimum: 62))], spacing: 10) {
                            ForEach(groups.keys.sorted(), id: \.self) { kindID in
                                VStack(spacing: 4) {
                                    QyubeCatchArt(kindID: kindID).frame(width: 44, height: 36)
                                    Text("×\(groups[kindID]?.count ?? 0)").font(.caption)
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("\(CatalogDefinitions.kind(id: kindID)?.name ?? kindID), \(groups[kindID]?.count ?? 0) catches")
                            }
                        }
                    }.frame(maxHeight: 180)
                }
                if catches.contains(where: { !$0.isBanked }) {
                    Text("Saved permanently after 5 minutes of active focus.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button("Open Catalog", action: onCatalog)
            }.padding(16).frame(width: 250).background(Color.qyubeBackground)
        }
    }
}
