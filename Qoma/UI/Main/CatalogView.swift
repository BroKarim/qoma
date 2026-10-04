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
    Dictionary(grouping: catches, by: \.kindID).mapValues(\.count)
  }
  private var kinds: [CatalogDefinitions.Kind] {
    CatalogDefinitions.allKinds.filter {
      filter == .all || (filter == .fish ? $0.isFish : !$0.isFish)
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Catalog").font(.system(size: 25, weight: .semibold))
        Text(
          "\(CatalogDefinitions.allKinds.filter { counts[$0.id, default: 0] > 0 }.count) of \(CatalogDefinitions.allKinds.count) discovered"
        )
        .font(.system(size: 12)).foregroundStyle(.secondary)
        Picker("Category", selection: $filter) {
          ForEach(Filter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
        }.pickerStyle(.segmented).labelsHidden()
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 54), spacing: 8)], spacing: 10) {
          ForEach(kinds) { kind in
            Button {
              selected = kind
            } label: {
              VStack(spacing: 6) {
                QyubeCatchArt(discovered: counts[kind.id, default: 0] > 0)
                  .frame(height: 32).padding(.horizontal, 5)
                Text(counts[kind.id, default: 0] > 0 ? "×\(counts[kind.id, default: 0])" : "?")
                  .font(.system(size: 10)).foregroundStyle(.secondary)
              }.padding(.vertical, 10).frame(maxWidth: .infinity)
                .background(Color(white: 0.98), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.qyubeLine, lineWidth: 0.7))
            }.buttonStyle(.plain)
              .accessibilityLabel(
                counts[kind.id, default: 0] > 0
                  ? "\(kind.name), \(counts[kind.id, default: 0]) caught" : "Undiscovered catch")
          }
        }
        Text("A small collection of moments well spent.")
          .font(.system(size: 11)).foregroundStyle(.secondary).padding(.top, 12)
      }.padding(.horizontal, 22).padding(.bottom, 22)
    }
    .sheet(item: $selected) { kind in
      CatalogDetail(kind: kind, catchCount: counts[kind.id, default: 0])
    }
  }
}

private struct CatalogDetail: View {
  let kind: CatalogDefinitions.Kind
  let catchCount: Int
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    VStack(spacing: 18) {
      QyubeCatchArt(discovered: catchCount > 0).frame(width: 140, height: 90)
      Text(catchCount > 0 ? kind.name : "Not discovered yet").font(.title3.weight(.semibold))
      Text(
        catchCount > 0
          ? "\(kind.rarity.rawValue.capitalized) · Caught \(catchCount) times"
          : "Something is waiting beneath the surface."
      )
      .font(.caption).foregroundStyle(.secondary)
      QyubePrimaryButton(title: "Done") { dismiss() }.keyboardShortcut(.cancelAction)
    }.padding(24).frame(width: 270).background(.white)
  }
}

extension CatalogDefinitions.Kind: Identifiable {}
