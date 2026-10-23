import SwiftUI

struct AnalyticsCatchGrid: View {
    let events: [CatchEvent]
    private let columns = [GridItem(.adaptive(minimum: 52, maximum: 72), spacing: 7)]

    var body: some View {
        let groups = DailyCatchSummary.groups(for: events).sorted {
            let left = rarityOrder($0.kindID)
            let right = rarityOrder($1.kindID)
            return left == right ? $0.kindID < $1.kindID : left < right
        }
        VStack(alignment: .leading, spacing: 10) {
            AnalyticsJournalHeading(title: "Daily catches", detail: "\(events.count) catches")
            if groups.isEmpty {
                Label("No catches on this day.", systemImage: "water.waves")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                LazyVGrid(columns: columns, spacing: 7) {
                    ForEach(groups) { group in
                        let kind = CatalogDefinitions.kind(id: group.kindID)
                        let rarityColor = kind?.rarity.color ?? Color.qyubeAccent
                        QyubeCatchArt(kindID: group.kindID)
                            .padding(6)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(rarityColor.opacity(0.23), in: RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(rarityColor.opacity(0.3), lineWidth: 0.7)
                            }
                            .overlay(alignment: .bottomTrailing) {
                                if group.events.count > 1 {
                                    Text("×\(group.events.count)")
                                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.qyubeBackground.opacity(0.95), in: Capsule())
                                        .padding(3)
                                }
                            }
                            .help("\(kind?.name ?? "Unknown find") · \(kind?.rarity.displayName ?? "Unknown rarity") · \(group.events.count) caught")
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(kind?.name ?? "Unknown find"), \(kind?.rarity.displayName ?? "Unknown rarity"), \(group.events.count) caught")
                    }
                }
            }
        }
    }

    private func rarityOrder(_ id: String) -> Int {
        guard let rarity = CatalogDefinitions.kind(id: id)?.rarity else { return 4 }
        return CatalogDefinitions.Rarity.allCases.firstIndex(of: rarity) ?? 4
    }
}
