import SwiftUI

struct CoveBucketView: View {
    let events: () -> [CatchEvent]
    let previouslyCaughtKinds: Set<String>
    let onCatalog: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let catches = events()
            let groups = Dictionary(grouping: catches, by: \.kindID)
            let discoveries = Set(groups.keys).subtracting(previouslyCaughtKinds).count

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("This session")
                        .font(.system(size: 20, weight: .semibold))
                    Text("\(catches.count) catches · \(groups.count) species")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.qyubeInk.opacity(0.65))
                        .monospacedDigit()
                }

                Divider()

                if catches.isEmpty {
                    Text("Waiting for the first catch")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.qyubeInk.opacity(0.65))
                        .frame(maxWidth: .infinity, minHeight: 64)
                } else {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 12) {
                            ForEach(groups.keys.sorted(), id: \.self) { kindID in
                                HStack(spacing: 6) {
                                    QyubeCatchArt(kindID: kindID)
                                        .frame(width: 48, height: 44)
                                    Text("×\(groups[kindID]?.count ?? 0)")
                                        .font(.system(size: 15, weight: .medium))
                                        .monospacedDigit()
                                }
                                .frame(width: 94, height: 64)
                                .help(CatalogDefinitions.kind(id: kindID)?.name ?? kindID)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("\(CatalogDefinitions.kind(id: kindID)?.name ?? kindID), \(groups[kindID]?.count ?? 0) catches")
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.viewAligned)
                    .frame(height: 64)
                }

                Divider()

                if discoveries > 0 {
                    Label(discoveries == 1 ? "1 new discovery" : "\(discoveries) new discoveries",
                          systemImage: "sparkles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.qyubeAccent)
                }
                if catches.contains(where: { !$0.isBanked }) {
                    Text("Saved permanently after 5 minutes of active focus.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.qyubeInk.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: onCatalog) {
                    Text("Open Catalog")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.qyubeSidebar, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.qyubeLine))
                        .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .frame(width: 310)
            .foregroundStyle(Color.qyubeInk)
            .background(Color.qyubeBackground)
            .environment(\.colorScheme, .light)
        }
    }
}
