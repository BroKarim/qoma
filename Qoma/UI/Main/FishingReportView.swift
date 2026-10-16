import SwiftUI

struct FishingReportView: View {
  let session: FocusSession
  let catches: [CatchEvent]
  var hasActiveSession = false
  let onStartAgain: () -> Void
  let onGoHome: () -> Void

  private var grouped: [(id: String, count: Int)] {
    Dictionary(grouping: catches, by: \.kindID).map { (id: $0.key, count: $0.value.count) }
      .sorted { $0.count == $1.count ? $0.id < $1.id : $0.count > $1.count }
  }

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(spacing: 18) {
          QyubePenguinArt(celebratory: session.status == .completed).frame(height: 125)
          Text(session.status == .completed ? "Nicely done." : "A moment of focus.")
            .font(.system(size: 25, weight: .semibold))
          Text(session.taskTitle.isEmpty ? "Focus session" : session.taskTitle)
            .font(.system(size: 14)).multilineTextAlignment(.center)
          Text(session.status.rawValue.capitalized).font(.system(size: 11)).foregroundStyle(
            .secondary)
          HStack {
            metric(QyubeFormat.duration(session.actualActiveSeconds), "Focused")
            metric("\(catches.count)", "Catches kept")
            metric("\(grouped.count)", "Species")
          }.padding(.vertical, 8)
          if session.status == .interrupted && session.actualActiveSeconds < 300 {
            Text("Your catches returned to the sea. Focus for five minutes to keep your next haul.")
              .font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
          } else if catches.isEmpty {
            Text("No catches landed this time.").font(.system(size: 12)).foregroundStyle(.secondary)
          } else {
            HStack(spacing: 12) {
              ForEach(Array(grouped.prefix(3)), id: \.id) { item in
                VStack(spacing: 6) {
                  QyubeCatchArt().frame(height: 36)
                  Text(CatalogDefinitions.kind(id: item.id)?.name ?? "Catch")
                    .font(.system(size: 10)).lineLimit(1)
                  Text("×\(item.count)").font(.system(size: 11)).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity).padding(8)
                  .background(Color.qyubeSelection, in: RoundedRectangle(cornerRadius: 8))
              }
            }
            Text("Saved to your Catalog.").font(.system(size: 11)).foregroundStyle(.secondary)
          }
        }.padding(.horizontal, 22).padding(.bottom, 12)
      }
      .qyubeScrollIndicator()
      VStack(spacing: 12) {
        QyubePrimaryButton(title: hasActiveSession ? "Show timer" : "Start another session", action: onStartAgain)
        Button("Back to Home", action: onGoHome).buttonStyle(.plain).font(.system(size: 12))
          .foregroundStyle(.secondary)
      }.padding(22)
    }
  }
  private func metric(_ value: String, _ title: String) -> some View {
    VStack(spacing: 5) {
      Text(value).font(.system(size: 20, weight: .semibold, design: .rounded))
      Text(title).font(.system(size: 10)).foregroundStyle(.secondary)
    }.frame(maxWidth: .infinity)
  }
}
