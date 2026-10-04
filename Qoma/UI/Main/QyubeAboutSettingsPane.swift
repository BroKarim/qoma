import SwiftUI

struct QyubeAboutSettingsPane: View {
    private var version: String {
        let value = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        return "Version \(value)"
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 18) {
                    Image("CompanionPoseFishing")
                        .resizable().scaledToFit()
                        .frame(width: 74, height: 74)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("qyube").font(.title.bold())
                        Text(version).foregroundStyle(.secondary)
                    }
                }
            }
            Section("About") {
                Text("A small fishing companion for focused work on your Mac.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
    }
}
