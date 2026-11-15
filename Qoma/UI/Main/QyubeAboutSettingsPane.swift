import SwiftUI

struct QyubeAboutSettingsPane: View {
    private var version: String {
        let value = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "Version \(value) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                JournalPageHeader(
                    eyebrow: "A CALMER FOCUS AHEAD",
                    title: "About",
                    subtitle: "A small companion for focused work.")
                SettingsSurfaceCard {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 24) {
                            Image("CompanionPoseFishing").resizable().scaledToFit().frame(width: 100, height: 110)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("qyube").font(.custom("GeistPixel-Regular", size: 36))
                                Text(self.version).font(.custom("GeistPixel-Regular", size: 12)).foregroundStyle(.secondary)
                            }
                        }
                        QyubeInkDivider()
                        Text("Make room for focused work, one quiet moment at a time.")
                            .font(.custom("GeistPixel-Regular", size: 21))
                        Text(
                            "Focus with a fishing companion, revisit your day, and collect little finds along the way. "
                                + "Your focus history and collection are stored on this Mac.")
                            .font(.custom("GeistPixel-Regular", size: 13)).foregroundStyle(.secondary).lineSpacing(5)
                    }
                }
                SettingsSurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("A little help").font(.custom("GeistPixel-Regular", size: 23))
                        QyubeInkDivider()
                        Text("Fishing chances")
                            .font(.custom("GeistPixel-Regular", size: 14))
                        Text(CatchRarityRules.helpOddsText)
                            .font(.custom("GeistPixel-Regular", size: 12))
                            .foregroundStyle(Color.qyubeMenuInk)
                        Text("The chance of a rare catch can rise after several catches without one.")
                            .font(.custom("GeistPixel-Regular", size: 12)).foregroundStyle(.secondary).lineSpacing(3)
                        Link("Contact support", destination: URL(string: "mailto:support@qoma.app")!)
                        Text("Made for quieter days and moments well spent.")
                            .font(.custom("GeistPixel-Regular", size: 13)).foregroundStyle(.secondary)
                    }
                }
            }.padding(28).padding(.top, 12).qyubeHideNativeScrollers()
        }
        .scrollIndicators(.hidden)
    }
}
