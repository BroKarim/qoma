import SwiftUI

struct CatalogView: View {
    let accountID: String = "local"

    var body: some View {
        let counts = CatchRepository.shared.countByKind(accountID: accountID)

        VStack(alignment: .leading, spacing: 16) {
            Text("Catalog")
                .font(.system(size: 24, weight: .semibold))

            Text("Every catch you bank appears here. Undiscovered species stay as silhouettes until you find them.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64))], spacing: 16) {
                ForEach(CatalogDefinitions.allKinds) { kind in
                    CatalogItemCell(kind: kind, count: counts[kind.id] ?? 0, isDiscovered: (counts[kind.id] ?? 0) > 0)
                }
            }

            Spacer(minLength: 0)
        }
    }
}

private struct CatalogItemCell: View {
    let kind: CatalogDefinitions.Kind
    let count: Int
    let isDiscovered: Bool

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isDiscovered ? Color.secondary.opacity(0.08) : Color.secondary.opacity(0.04))
                .frame(width: 64, height: 64)
                .overlay(
                    Group {
                        if isDiscovered {
                            Text(kind.isFish ? "🐟" : "🌿")
                                .font(.system(size: 28))
                        } else {
                            Image(systemName: "questionmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.4))
                        }
                    }
                )
            Text(isDiscovered ? kind.name : "???")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isDiscovered ? .secondary : .secondary.opacity(0.5))
                .multilineTextAlignment(.center)
            if isDiscovered {
                Text("×\(count)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
    }
}

extension CatalogDefinitions.Kind: Identifiable {}
