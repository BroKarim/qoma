import SwiftUI

struct QyubeAppearanceSettingsPane: View {
    @AppStorage("qyube.reduceMotionOverride") private var reduceMotionOverride = false

    var body: some View {
        Form {
            Section("Motion") {
                Toggle(isOn: $reduceMotionOverride) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Reduce companion motion")
                        Text("Keep the penguin visible with gentler movement and static distraction cues.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Color") {
                LabeledContent("Palette") {
                    HStack(spacing: 6) {
                        swatch(.qyubeInk)
                        swatch(.qyubeBackground)
                        swatch(.qyubeAccent)
                        Text("Penguin · ice · warm accent")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
    }

    private func swatch(_ color: Color) -> some View {
        Circle().fill(color).frame(width: 16, height: 16)
            .overlay(Circle().stroke(.black.opacity(0.12), lineWidth: 1))
    }
}
