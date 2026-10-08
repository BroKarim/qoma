import SwiftUI

struct QyubeGeneralSettingsPane: View {
    @AppStorage(AppConstants.SoundSettings.selectedSoundKey)
    private var selectedSoundID = AppConstants.SoundSettings.defaultSoundID
    @AppStorage(AppConstants.SoundSettings.volumeKey)
    private var volume = AppConstants.SoundSettings.defaultVolume
    @AppStorage(AppConstants.SoundSettings.autoMuteAfter5SecondsKey)
    private var autoMute = true
    @AppStorage(DistractionAudioPlayer.enabledKey) private var distractionSounds = true

    var body: some View {
        Form {
            Section("Session sound") {
                Picker("Completion sound", selection: $selectedSoundID) {
                    ForEach(AppConstants.SoundSettings.options) { option in
                        Text(option.title).tag(option.id)
                    }
                }
                .pickerStyle(.menu)

                LabeledContent("Volume") {
                    HStack(spacing: 12) {
                        Slider(value: $volume, in: 0...1)
                            .frame(width: 190)
                        Text("\(Int(volume * 100))%")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }

                Toggle("Stop the sound after five seconds", isOn: $autoMute)
            }

            Section("While focusing") {
                Toggle("Distraction sound effects", isOn: $distractionSounds)
                LabeledContent("Floating companion") {
                    Text("Stays visible while a session is active or paused")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Timer panel") {
                    Text("Close it anytime; use the menu bar to bring it back")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
    }
}
