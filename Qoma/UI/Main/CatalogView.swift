import SwiftUI

struct CatalogView: View {
    var catches: [CatchEvent] = []
    @State private var filter = Filter.all
    @State private var selected: CatalogDefinitions.Kind?

    private enum Filter: String, CaseIterable {
        case all = "All"
        case fish = "Fish"
        case finds = "Ocean finds"
    }

    private var counts: [String: Int] {
        let unique = Dictionary(catches.filter(\.isBanked).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return Dictionary(grouping: unique.values, by: \.kindID).mapValues(\.count)
    }

    private var kinds: [CatalogDefinitions.Kind] {
        CatalogDefinitions.allKinds.filter { self.filter == .all || (self.filter == .fish ? $0.isFish : !$0.isFish) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                JournalPageHeader(
                    eyebrow: "YOUR LITTLE COLLECTION",
                    title: "Catalog",
                    subtitle: "A collection of moments well spent.")
                self.progress
                Picker("Category", selection: self.$filter) {
                    ForEach(Filter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).labelsHidden().frame(maxWidth: 420)
                .padding(3)
                .qyubeInkSurface(fill: .qyubeSelection.opacity(0.22))
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 14)], spacing: 14) {
                    ForEach(self.kinds) { kind in
                        Button { self.selected = kind } label: { self.card(kind) }
                            .buttonStyle(.plain)
                            .accessibilityLabel(self.counts[kind.id, default: 0] > 0
                                ? "\(kind.name), \(kind.rarity.rawValue), "
                                + "\(self.counts[kind.id, default: 0]) caught. Weight not recorded."
                                : "Undiscovered catch")
                    }
                }
                Text("Every focused moment adds to your collection.")
                    .font(.system(size: 14, design: .serif)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
            }.padding(28).padding(.top, 12)
        }
        .qyubeScrollIndicator()
        .sheet(item: self.$selected) { kind in
            CatalogDetail(kind: kind, catchCount: self.counts[kind.id, default: 0])
        }
    }

    private var progress: some View {
        let discovered = CatalogDefinitions.allKinds.count(where: { self.counts[$0.id, default: 0] > 0 })
        return HStack(spacing: 24) {
            Text("\(discovered) of \(CatalogDefinitions.allKinds.count) discovered")
                .font(.system(size: 16, design: .serif))
            ProgressView(value: Double(discovered), total: Double(CatalogDefinitions.allKinds.count))
                .frame(maxWidth: 250).tint(.qyubeAccent)
        }
    }

    private func card(_ kind: CatalogDefinitions.Kind) -> some View {
        let count = self.counts[kind.id, default: 0]
        let discovered = count > 0
        return VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                QyubeInkBorder().fill(Color.qyubeSidebar.opacity(0.76))
                QyubeCatchArt(kindID: kind.id, discovered: discovered, catalog: true)
                    .padding(18).frame(height: 174).frame(maxWidth: .infinity)
                if discovered {
                    Text("×\(count)").font(.system(size: 12)).foregroundStyle(.secondary).padding(10)
                }
            }.frame(height: 174)
            Text(discovered ? kind.name : "???")
                .font(.system(size: 20, design: .serif))
                .foregroundStyle(discovered ? kind.rarity.color : .qyubeInk)
                .lineLimit(1).minimumScaleFactor(0.75)
            if discovered, kind.isFish {
                Text(CatchWeightFormat.kilograms(nil)).font(.system(size: 13))
                    .help("Weight has not been recorded for these catches yet.")
            } else {
                Text(discovered ? "Ocean find" : "—").font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Text(discovered ? kind.rarity.rawValue.capitalized : "Undiscovered")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .padding(10).padding(.bottom, 8).frame(maxWidth: .infinity)
        .qyubeInkSurface(fill: .qyubeCardBackground.opacity(0.68))
        .shadow(color: Color.qyubeAccent.opacity(0.055), radius: 5, y: 2)
        .accessibilityElement(children: .ignore)
    }
}

private struct CatalogDetail: View {
    let kind: CatalogDefinitions.Kind
    let catchCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            QyubeCatchArt(kindID: self.kind.id, discovered: self.catchCount > 0, catalog: true).frame(
                width: 160,
                height: 180)
            Text(self.catchCount > 0 ? self.kind.name : "???").font(.system(size: 25, design: .serif))
            Text(self
                .catchCount > 0 ? "\(self.kind.rarity.rawValue.capitalized) · Caught \(self.catchCount) times" :
                "Undiscovered")
                .font(.caption).foregroundStyle(.secondary)
            if self.catchCount > 0, self.kind.isFish {
                Text("Weight not recorded yet").font(.caption).foregroundStyle(.secondary)
            }
            Button("Done") { self.dismiss() }.keyboardShortcut(.cancelAction)
        }
        .padding(28)
        .frame(width: 300)
        .background(Color.qyubeBackground)
        .qyubeInkSurface(fill: .qyubeBackground, stroke: .qyubeAccent.opacity(0.65))
    }
}

extension CatalogDefinitions.Kind: Identifiable {}
