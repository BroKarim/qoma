import SwiftUI

struct QyubeGeneralSettingsPane: View {
    @ObservedObject private var focus = FocusPreferences.shared
    @State private var editingRules = false
    @AppStorage(AppConstants.SoundSettings.selectedSoundKey)
    private var selectedSoundID = AppConstants.SoundSettings.defaultSoundID
    @AppStorage(AppConstants.SoundSettings.volumeKey)
    private var volume = AppConstants.SoundSettings.defaultVolume
    @AppStorage(AppConstants.SoundSettings.autoMuteAfter5SecondsKey)
    private var autoMute = true
    @AppStorage(DistractionAudioPlayer.enabledKey) private var distractionSounds = true

    var body: some View {
        Form {
            Section("Focus rules") {
                Picker("Mode for new sessions", selection: $focus.policy.mode) {
                    Text("Timer only").tag(FocusPolicyMode.timerOnly)
                    Text("Allowing").tag(FocusPolicyMode.allowing)
                    Text("Blocking").tag(FocusPolicyMode.blocking)
                }
                .pickerStyle(.menu)
                if focus.policy.mode != .timerOnly {
                    Button("Choose apps and websites…") { editingRules = true }
                    Text("Changes apply when you start the next session.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
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
                Toggle("Hide floating timer", isOn: $focus.hideFloatingTimer)
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
        .sheet(isPresented: $editingRules) {
            QyubeAppRuleEditor(
                policy: $focus.policy,
                selectedDomainBrowser: $focus.browserBundleID
            )
        }
    }
}
