import SwiftUI

struct QyubeCompactSettingsView: View {
  @AppStorage(AppConstants.SoundSettings.selectedSoundKey) private var sound = AppConstants
    .SoundSettings.defaultSoundID
  @AppStorage(AppConstants.SoundSettings.volumeKey) private var volume = AppConstants.SoundSettings
    .defaultVolume
  @AppStorage(AppConstants.SoundSettings.autoMuteAfter5SecondsKey) private var autoMute = true
  @AppStorage("qyube.reduceMotionOverride") private var reduceMotion = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 25) {
        Text("Settings").font(.system(size: 25, weight: .semibold))
        VStack(alignment: .leading, spacing: 17) {
          heading("Sound")
          Picker("Session sound", selection: $sound) {
            ForEach(AppConstants.SoundSettings.options) { Text($0.title).tag($0.id) }
          }.pickerStyle(.menu)
          HStack {
            Text("Volume")
            Slider(value: $volume, in: 0...1).accessibilityLabel("Volume")
            Text("\(Int(volume * 100))%").monospacedDigit().frame(width: 33)
          }
          Toggle("Stop sound after 5 seconds", isOn: $autoMute).toggleStyle(.switch).controlSize(
            .small)
        }
        Divider()
        VStack(alignment: .leading, spacing: 14) {
          heading("Motion")
          Toggle("Reduce motion", isOn: $reduceMotion).toggleStyle(.switch).controlSize(.small)
          Text("Gentler penguin movement and quiet visual cues.")
            .font(.system(size: 11)).foregroundStyle(.secondary)
        }
        Divider()
        VStack(alignment: .leading, spacing: 12) {
          heading("While focusing")
          Text(
            "Your penguin stays with you throughout the session. Close the timer anytime and bring it back from the menu bar."
          )
          .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(
            horizontal: false, vertical: true)
        }
        Divider()
        HStack {
          Text("qyube").font(.system(size: 17, weight: .medium, design: .rounded))
          Spacer()
          Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
            .foregroundStyle(.secondary)
        }
      }.font(.system(size: 12)).padding(.horizontal, 22).padding(.bottom, 24)
    }
    .qyubeScrollIndicator()
  }
  private func heading(_ title: String) -> some View {
    Text(title).font(.system(size: 14, weight: .semibold))
  }
}
