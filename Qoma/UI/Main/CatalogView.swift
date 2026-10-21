import SwiftUI

struct CatalogView: View {
    private let fish = Array(0..<32)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 5)

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

                rarityLegend

                LazyVGrid(columns: self.columns, spacing: 8) {
                    ForEach(self.fish, id: \.self) { index in
                        CatalogFishTile(index: index, rarity: CatalogRarity.allCases[index % 4])
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Fish collection artwork")
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .qyubeHideNativeScrollers()
        }
        .scrollIndicators(.hidden)
    }

    private var rarityLegend: some View {
        HStack(spacing: 8) {
            ForEach(CatalogRarity.allCases) { rarity in
                HStack(spacing: 4) {
                    Circle()
                        .fill(rarity.color)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color.qyubeMenuInk.opacity(0.16), lineWidth: 0.5))
                    Text(rarity.label)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.qyubeMenuInk.opacity(0.78))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rarity colors: common, uncommon, rare, legendary")
    }
}

private struct CatalogFishTile: View {
    let index: Int
    let rarity: CatalogRarity

    var body: some View {
        CatalogFishSprite(index: self.index)
            .padding(5)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(self.rarity.color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.qyubeMenuInk.opacity(0.22), lineWidth: 0.7)
                    .allowsHitTesting(false)
            }
            .accessibilityHidden(true)
    }
}

private struct CatalogFishSprite: View {
    let index: Int

    var body: some View {
        GeometryReader { geometry in
            Image("CatalogFishSheet")
                .resizable()
                .frame(width: geometry.size.width * 8, height: geometry.size.height * 4)
                .offset(
                    x: -CGFloat(self.index % 8) * geometry.size.width,
                    y: -CGFloat(self.index / 8) * geometry.size.height)
        }
        .clipped()
    }
}

private enum CatalogRarity: Int, CaseIterable, Identifiable {
    case common
    case uncommon
    case rare
    case legendary

    var id: Self { self }

    var label: String {
        switch self {
        case .common: "Common"
        case .uncommon: "Uncommon"
        case .rare: "Rare"
        case .legendary: "Legendary"
        }
    }

    var color: Color {
        switch self {
        case .common: Color(red: 229 / 255, green: 231 / 255, blue: 233 / 255)
        case .uncommon: Color(red: 220 / 255, green: 232 / 255, blue: 242 / 255)
        case .rare: Color(red: 233 / 255, green: 225 / 255, blue: 240 / 255)
        case .legendary: Color(red: 242 / 255, green: 228 / 255, blue: 188 / 255)
        }
    }
}
