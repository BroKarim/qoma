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
    @AppStorage(AppConstants.AnalyticsSettings.analyticsEnabledKey)
    private var analyticsEnabled = AppConstants.AnalyticsSettings.defaultAnalyticsEnabled

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
                self.analyticsSettings
            }.padding(28).padding(.top, 12).qyubeHideNativeScrollers()
        }
        .scrollIndicators(.hidden)
        .onDisappear { SoundAlertPlayer.shared.stop() }
        .onChange(of: self.sound) { _, _ in SoundAlertPlayer.shared.stop() }
        .onChange(of: self.volume) { _, value in
            self.volume = min(1, max(0, value.isFinite ? value : AppConstants.SoundSettings.defaultVolume))
            SoundAlertPlayer.shared.stop()
        }
        .onChange(of: self.analyticsEnabled) { _, value in
            AppConstants.AnalyticsSettings.isAnalyticsEnabled = value
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
                QyubeInkDivider()
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
                QyubeInkDivider()
                ViewThatFits(in: .horizontal) {
                    HStack {
                        Text("Timer color"); Spacer(); self.themePicker.fixedSize(horizontal: true, vertical: false)
                    }
                    VStack(alignment: .leading, spacing: 12) { Text("Timer color"); self.themePicker.fixedSize(
                        horizontal: true,
                        vertical: false) }
                }
                if #available(macOS 26.0, *) {
                    QyubeInkDivider()
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
                .qyubeInkSurface(fill: .white, stroke: .qyubeLine)
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
                QyubeInkDivider()
                SettingsRow(title: "Distraction sound effects") {
                    Toggle("Distraction sound effects", isOn: self.$distractionSounds).labelsHidden()
                        .toggleStyle(.switch)
                }
            }
        }
    }

    private var analyticsSettings: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                self.heading("Focus analytics")
                SettingsRow(
                    title: "Record app and website activity",
                    subtitle: "Stored locally on this Mac. Website tracking also needs browser permission.") {
                    Toggle("Record activity", isOn: self.$analyticsEnabled)
                        .labelsHidden().toggleStyle(.switch)
                }
            }
        }
    }

    private func heading(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 23, design: .serif))
            QyubeInkDivider()
        }
    }
}
