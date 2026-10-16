import SwiftUI

struct QyubeJournalSettingsView: View {
    @ObservedObject private var focus = FocusPreferences.shared
    @AppStorage(AppConstants.SoundSettings.selectedSoundKey)
    private var sound = AppConstants.SoundSettings.defaultSoundID
    @AppStorage(AppConstants.SoundSettings.volumeKey)
    private var volume = AppConstants.SoundSettings.defaultVolume
    @AppStorage(AppConstants.FloatingThemeSettings.selectedThemeKey)
    private var themeID = AppConstants.FloatingThemeSettings.defaultThemeID
    @AppStorage(AppConstants.FloatingThemeSettings.liquidGlassKey) private var glass = false
    @AppStorage("qyube.reduceMotionOverride") private var reduceMotion = false
    @AppStorage(DistractionAudioPlayer.enabledKey) private var distractionSounds = true
    @State private var editingRules = false
    @State private var rulesExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                JournalPageHeader(
                    eyebrow: "MAKE YOURSELF AT HOME",
                    title: "Settings",
                    subtitle: "A few small comforts for your focus.")
                    .padding(.bottom, 8)
                self.account
                self.soundSettings
                self.floatingSettings
                self.comfort
                self.focusRules
            }.padding(28).padding(.top, 12)
        }
        .qyubeScrollIndicator()
        .sheet(isPresented: self.$editingRules) {
            QyubeAppRuleEditor(policy: self.$focus.policy, selectedDomainBrowser: self.$focus.browserBundleID)
        }
        .onDisappear { SoundAlertPlayer.shared.stop() }
        .onChange(of: self.sound) { _, _ in SoundAlertPlayer.shared.stop() }
        .onChange(of: self.volume) { _, value in
            self.volume = min(1, max(0, value.isFinite ? value : AppConstants.SoundSettings.defaultVolume))
            SoundAlertPlayer.shared.stop()
        }
        .onAppear {
            if self.sound != "off" && !AppConstants.SoundSettings.options.contains(where: { $0.id == sound }) {
                self.sound = AppConstants.SoundSettings.defaultSoundID
            }
            if !self.volume.isFinite || !(0...1)
                .contains(self.volume) { self.volume = AppConstants.SoundSettings.defaultVolume }
            if !FloatingTheme.allCases.contains(where: { $0.id == themeID }) {
                self.themeID = AppConstants.FloatingThemeSettings.defaultThemeID
            }
        }
    }

    private var account: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                self.heading("Account")
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle").font(.system(size: 34, weight: .ultraLight))
                        .foregroundStyle(Color.qyubeAccent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your quiet corner").font(.system(size: 17, design: .serif))
                        Text("Using qyube offline on this Mac.").font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Log in") {}.disabled(true).help("Account login is not enabled yet.")
                }
                Text("Account login will be available later. Your collection stays on this Mac.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
        }
    }

    private var soundSettings: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                self.heading("Sound")
                SettingsRow(title: "Session ends") {
                    Picker("Completion sound", selection: self.$sound) {
                        Text("Off").tag("off")
                        ForEach(AppConstants.SoundSettings.options) { Text($0.title).tag($0.id) }
                    }.labelsHidden().frame(width: 180)
                    Button {
                        SoundAlertPlayer.shared.play(
                            soundID: self.sound,
                            volume: self.volume)
                    } label: { Image(systemName: "play.fill") }
                        .accessibilityLabel("Preview completion sound").disabled(self.sound == "off")
                }
                Divider()
                SettingsRow(title: "Volume") {
                    Slider(value: self.$volume, in: 0...1).frame(width: 180)
                        .accessibilityLabel("Completion sound volume")
                    Text("\(Int(self.volume * 100))%").monospacedDigit().frame(width: 38, alignment: .trailing)
                }
                Text("Sounds stop automatically after 5 seconds.").font(.system(size: 11)).foregroundStyle(.secondary)
            }
        }
    }

    private var floatingSettings: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                self.heading("Floating timer")
                SettingsRow(title: "Show floating timer") {
                    Toggle("Show floating timer", isOn: Binding(
                        get: { !self.focus.hideFloatingTimer }, set: { self.focus.hideFloatingTimer = !$0 }))
                        .labelsHidden().toggleStyle(.switch)
                }
                Divider()
                ViewThatFits(in: .horizontal) {
                    HStack {
                        Text("Timer color"); Spacer(); self.themePicker.fixedSize(horizontal: true, vertical: false)
                    }
                    VStack(alignment: .leading, spacing: 12) { Text("Timer color"); self.themePicker.fixedSize(
                        horizontal: true,
                        vertical: false) }
                }
                if #available(macOS 26.0, *) {
                    Divider()
                    SettingsRow(title: "Liquid Glass", subtitle: "A translucent surface for your timer.") {
                        Toggle("Liquid Glass", isOn: self.$glass).labelsHidden().toggleStyle(.switch)
                    }
                }
            }
        }
    }

    private var themePicker: some View {
        HStack(spacing: 10) {
            ForEach(FloatingTheme.allCases) { theme in
                Button { self.themeID = theme.id } label: {
                    Circle().fill(theme.textColor).frame(width: 22, height: 22)
                        .padding(4)
                        .overlay(Circle().stroke(self.themeID == theme.id ? Color.qyubeAccent : .clear, lineWidth: 1.5))
                }
                .buttonStyle(.plain).accessibilityLabel(theme.title)
                .accessibilityAddTraits(self.themeID == theme.id ? .isSelected : [])
                .help(theme.title)
            }
            Text("24:53").font(.system(size: 25, weight: .medium, design: .serif).monospacedDigit())
                .foregroundStyle(FloatingTheme.from(id: self.themeID).textColor)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.white, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.qyubeLine, lineWidth: 0.7))
                .lineLimit(1).fixedSize()
                .accessibilityLabel("Timer color preview")
        }
    }

    private var comfort: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                self.heading("Comfort")
                SettingsRow(title: "Reduce motion", subtitle: "Gentler penguin movement and quiet visual cues.") {
                    Toggle("Reduce motion", isOn: self.$reduceMotion).labelsHidden().toggleStyle(.switch)
                }
                Divider()
                SettingsRow(title: "Distraction sound effects") {
                    Toggle("Distraction sound effects", isOn: self.$distractionSounds).labelsHidden()
                        .toggleStyle(.switch)
                }
            }
        }
    }

    private var focusRules: some View {
        SettingsSurfaceCard {
            DisclosureGroup("Focus rules", isExpanded: self.$rulesExpanded) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Changes apply to the next session you start.").font(.caption).foregroundStyle(.secondary)
                    Picker("Mode for new sessions", selection: self.$focus.policy.mode) {
                        Text("Timer only").tag(FocusPolicyMode.timerOnly)
                        Text("Allowing").tag(FocusPolicyMode.allowing)
                        Text("Blocking").tag(FocusPolicyMode.blocking)
                    }
                    if self.focus.policy.mode != .timerOnly {
                        Button("Choose apps and websites…") { self.editingRules = true }
                    }
                }.padding(.top, 14)
            }
        }
    }

    private func heading(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 23, design: .serif))
            Divider()
        }
    }
}
