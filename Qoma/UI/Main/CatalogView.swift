import SwiftUI

struct CatalogView: View {
    @State private var selectedFilter: Filter = .all
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 5)

    @EnvironmentObject private var navigation: QyubeNavigation

    private var discoveredKinds: Set<String> {
        Set(self.navigation.catches.filter(\.isBanked).map(\.kindID))
    }

    private var kinds: [CatalogDefinitions.Kind] {
        CatalogDefinitions.allKinds
            .filter { self.selectedFilter.isFish == nil || $0.isFish == self.selectedFilter.isFish }
            .sorted {
                let lhs = Self.rarityOrder($0.rarity)
                let rhs = Self.rarityOrder($1.rarity)
                return lhs == rhs ? $0.id < $1.id : lhs < rhs
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("COLLECTION")
                        .font(.caption2.weight(.medium))
                        .tracking(1.5)
                        .foregroundStyle(Color.qyubeAccent)
                    Text("Catalog")
                        .font(.system(size: 23, design: .serif))
                        .foregroundStyle(Color.qyubeMenuInk)
                }

                progressSection
                filterTabs

                LazyVGrid(columns: self.columns, spacing: 8) {
                    ForEach(self.kinds, id: \.id) { kind in
                        CatalogKindTile(kind: kind, discovered: self.discoveredKinds.contains(kind.id))
                    }
                }
                .accessibilityLabel("Catalog items, ordered from common to legendary")
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .qyubeHideNativeScrollers()
        }
        .scrollIndicators(.hidden)
        .onAppear { self.navigation.refresh() }
    }

    private var progressSection: some View {
        let total = CatalogDefinitions.allKinds.count
        let discovered = self.discoveredKinds.count
        let progress = total == 0 ? 0 : Double(discovered) / Double(total)

        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("COLLECTION PROGRESS")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.1)
                    .foregroundStyle(Color.qyubeAccent)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qyubeMenuInk)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.qyubeMenuInk.opacity(0.1))
                    Capsule().fill(Color.qyubeAccent)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 6)
            .accessibilityLabel("Catalog collection progress")
            .accessibilityValue("\(Int(progress * 100)) percent")
        }
        .padding(10)
        .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(Color.qyubeMenuInk.opacity(0.18), lineWidth: 0.7)
                .allowsHitTesting(false)
        }
    }

    private var filterTabs: some View {
        HStack(spacing: 4) {
            ForEach(Filter.allCases) { filter in
                Button {
                    self.selectedFilter = filter
                } label: {
                    Text(filter.title)
                        .font(.system(size: 10, weight: self.selectedFilter == filter ? .semibold : .medium))
                        .foregroundStyle(self.selectedFilter == filter ? Color.white : Color.qyubeMenuInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background {
                            if self.selectedFilter == filter {
                                Capsule().fill(Color.qyubeAccent)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(self.selectedFilter == filter ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Color.qyubeMenuInk.opacity(0.07), in: Capsule())
        .accessibilityLabel("Catalog categories")
    }

    private static func rarityOrder(_ rarity: CatalogDefinitions.Rarity) -> Int {
        switch rarity {
        case .common: 0
        case .uncommon: 1
        case .rare: 2
        case .legendary: 3
        }
    }

    private enum Filter: String, CaseIterable, Identifiable {
        case all
        case fish
        case oceanFinds

        var id: Self { self }
        var title: String {
            switch self {
            case .all: "All"
            case .fish: "Fish"
            case .oceanFinds: "Ocean finds"
            }
        }

        var isFish: Bool? {
            switch self {
            case .all: nil
            case .fish: true
            case .oceanFinds: false
            }
        }
    }
}

private struct CatalogKindTile: View {
    let kind: CatalogDefinitions.Kind
    let discovered: Bool

    var body: some View {
        QyubeCatchArt(kindID: self.kind.id, discovered: self.discovered)
            .padding(5)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(self.kind.rarity.color.opacity(0.23))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.qyubeMenuInk.opacity(0.22), lineWidth: 0.7)
                    .allowsHitTesting(false)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(self.discovered ? "Discovered \(self.kind.name)" : "Undiscovered \(self.kind.isFish ? "fish" : "ocean find")")
    }
}
