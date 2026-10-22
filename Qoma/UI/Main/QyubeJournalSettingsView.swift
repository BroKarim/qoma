import SwiftUI

struct QyubeJournalSettingsView: View {
    @ObservedObject private var focus = FocusPreferences.shared
    @AppStorage("qyube.dailyFocusGoal.hours") private var goalHours = 2
    @AppStorage("qyube.dailyFocusGoal.minutes") private var goalMinutes = 0
    @AppStorage(AppConstants.QuickPresets.preset1Key)
    private var quickPreset1 = AppConstants.QuickPresets.defaultValues[0]
    @AppStorage(AppConstants.QuickPresets.preset2Key)
    private var quickPreset2 = AppConstants.QuickPresets.defaultValues[1]
    @AppStorage(AppConstants.QuickPresets.preset3Key)
    private var quickPreset3 = AppConstants.QuickPresets.defaultValues[2]
    @AppStorage(AppConstants.SoundSettings.selectedSoundKey)
    private var sound = AppConstants.SoundSettings.defaultSoundID
    @AppStorage(AppConstants.SoundSettings.volumeKey)
    private var volume = AppConstants.SoundSettings.defaultVolume
    @AppStorage(AppConstants.SoundSettings.autoMuteAfter5SecondsKey) private var autoMute = true
    @AppStorage(AppConstants.FloatingThemeSettings.selectedThemeKey)
    private var themeID = AppConstants.FloatingThemeSettings.defaultThemeID
    @AppStorage(AppConstants.FloatingThemeSettings.liquidGlassKey) private var glass = false
    @AppStorage(AppConstants.FloatingThemeSettings.opacityKey)
    private var opacity = AppConstants.FloatingThemeSettings.defaultOpacity
    @AppStorage("qyube.reduceMotionOverride") private var reduceMotion = false
    @AppStorage(DistractionAudioPlayer.enabledKey) private var distractionSounds = true
    @AppStorage(AppConstants.AnalyticsSettings.analyticsEnabledKey)
    private var analyticsEnabled = AppConstants.AnalyticsSettings.defaultAnalyticsEnabled
    @State private var isResetConfirmationPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SETTINGS")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(Color.qyubeAccent)
                    Text("Settings")
                        .font(.system(size: 23, design: .serif))
                        .foregroundStyle(Color.qyubeMenuInk)
                }

                self.goalSection
                self.presetsSection
                self.soundSection
                self.floatingSection
                self.appearanceSection
                self.privacySection
                self.aboutSection
                self.resetSection
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .qyubeHideNativeScrollers()
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(Color.qyubeMenuInk)
        .onDisappear { SoundAlertPlayer.shared.stop() }
        .onChange(of: self.sound) { _, _ in SoundAlertPlayer.shared.stop() }
        .onChange(of: self.volume) { _, value in
            self.volume = min(1, max(0, value.isFinite ? value : AppConstants.SoundSettings.defaultVolume))
            SoundAlertPlayer.shared.stop()
        }
        .onChange(of: self.goalHours) { _, value in self.goalHours = min(24, max(0, value)) }
        .onChange(of: self.goalMinutes) { _, value in self.goalMinutes = min(59, max(0, value)) }
        .onChange(of: self.quickPreset1) { _, value in self.quickPreset1 = self.clampPreset(value) }
        .onChange(of: self.quickPreset2) { _, value in self.quickPreset2 = self.clampPreset(value) }
        .onChange(of: self.quickPreset3) { _, value in self.quickPreset3 = self.clampPreset(value) }
        .onChange(of: self.opacity) { _, value in
            self.opacity = min(
                AppConstants.FloatingThemeSettings.maxOpacity,
                max(AppConstants.FloatingThemeSettings.minOpacity, value.isFinite ? value : 1))
        }
        .onChange(of: self.analyticsEnabled) { _, value in
            AppConstants.AnalyticsSettings.isAnalyticsEnabled = value
        }
        .onAppear {
            if self.sound != "off" && !AppConstants.SoundSettings.options.contains(where: { $0.id == self.sound }) {
                self.sound = AppConstants.SoundSettings.defaultSoundID
            }
            if !self.volume.isFinite { self.volume = AppConstants.SoundSettings.defaultVolume }
            if !FloatingTheme.allCases.contains(where: { $0.id == self.themeID }) {
                self.themeID = AppConstants.FloatingThemeSettings.defaultThemeID
            }
        }
        .alert("Reset settings?", isPresented: self.$isResetConfirmationPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { self.resetSettings() }
        } message: {
            Text("Your Qyube preferences will return to their defaults.")
        }
    }

    private var goalSection: some View {
        self.card {
            VStack(alignment: .leading, spacing: 8) {
                self.sectionLabel("DAILY FOCUS GOAL")
                HStack(spacing: 7) {
                    self.numberField(value: self.$goalHours, label: "Daily goal hours")
                    Text("h").font(.system(size: 11)).foregroundStyle(.secondary)
                    self.numberField(value: self.$goalMinutes, label: "Daily goal minutes")
                    Text("m").font(.system(size: 11)).foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                Text("0h 0m means no target.")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
    }

    private var presetsSection: some View {
        self.card {
            VStack(alignment: .leading, spacing: 8) {
                self.sectionLabel("QUICK PRESETS")
                HStack(spacing: 6) {
                    self.presetField(value: self.$quickPreset1)
                    self.presetField(value: self.$quickPreset2)
                    self.presetField(value: self.$quickPreset3)
                }
            }
        }
    }

    private var soundSection: some View {
        self.card {
            VStack(alignment: .leading, spacing: 9) {
                self.sectionLabel("COMPLETION SOUND")
                HStack(spacing: 8) {
                    Picker("Completion sound", selection: self.$sound) {
                        Text("Off").tag("off")
                        ForEach(AppConstants.SoundSettings.options) { Text($0.title).tag($0.id) }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        SoundAlertPlayer.shared.play(soundID: self.sound, volume: self.volume)
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Preview completion sound")
                    .disabled(self.sound == "off")
                }
                HStack(spacing: 8) {
                    Text("Volume").font(.system(size: 10))
                    Slider(value: self.$volume, in: 0...1)
                    Text("\(Int(self.volume * 100))%")
                        .font(.system(size: 10).monospacedDigit())
                        .frame(width: 30, alignment: .trailing)
                }
                self.toggleRow("Auto mute after 5 seconds", isOn: self.$autoMute)
            }
        }
    }

    private var floatingSection: some View {
        self.card {
            VStack(alignment: .leading, spacing: 8) {
                self.sectionLabel("FLOATING TIMER")
                self.toggleRow(
                    "Show floating timer",
                    isOn: Binding(
                        get: { !self.focus.hideFloatingTimer },
                        set: { self.focus.hideFloatingTimer = !$0 }))
                Text("When off, controls move to the menu bar.")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                self.toggleRow("Distraction sound effects", isOn: self.$distractionSounds)
            }
        }
    }

    private var appearanceSection: some View {
        self.card {
            VStack(alignment: .leading, spacing: 9) {
                self.sectionLabel("APPEARANCE")
                self.toggleRow("Reduce companion motion", isOn: self.$reduceMotion)
                if #available(macOS 26.0, *) {
                    self.toggleRow("Liquid Glass", isOn: self.$glass)
                }
                HStack(spacing: 8) {
                    Text("Opacity").font(.system(size: 10))
                    Slider(value: self.$opacity, in: AppConstants.FloatingThemeSettings.minOpacity...1)
                    Text("\(Int((self.opacity * 100).rounded()))%")
                        .font(.system(size: 10).monospacedDigit())
                        .frame(width: 30, alignment: .trailing)
                }
                HStack(spacing: 7) {
                    Text("Timer color").font(.system(size: 10))
                    Spacer(minLength: 0)
                    ForEach(FloatingTheme.allCases) { theme in
                        Button { self.themeID = theme.id } label: {
                            Circle().fill(theme.textColor).frame(width: 15, height: 15)
                                .overlay(Circle().stroke(
                                    self.themeID == theme.id ? Color.qyubeMenuInk : .clear,
                                    lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.title)
                        .accessibilityAddTraits(self.themeID == theme.id ? .isSelected : [])
                    }
                }
            }
        }
    }

    private var privacySection: some View {
        self.card {
            VStack(alignment: .leading, spacing: 8) {
                self.sectionLabel("PRIVACY")
                self.toggleRow("Record activity", isOn: self.$analyticsEnabled)
            }
        }
    }

    private var aboutSection: some View {
        self.card {
            VStack(alignment: .leading, spacing: 8) {
                self.sectionLabel("ABOUT")
                Button {
                    UpdaterManager.shared.checkForUpdates()
                } label: {
                    HStack {
                        Text("Check for Updates")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var resetSection: some View {
        self.card {
            VStack(alignment: .leading, spacing: 8) {
                self.sectionLabel("RESET")
                Button("Reset settings") { self.isResetConfirmationPresented = true }
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.qyubeAccent)
                Button("Erase all data") {}
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .disabled(true)
                    .help("Data erasure will be added in a later implementation stage.")
            }
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10, content: content)
            .padding(12)
            .qyubeInkSurface(fill: .qyubeCardBackground.opacity(0.58))
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold))
            .tracking(1)
            .foregroundStyle(Color.qyubeAccent)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            Text(title).font(.system(size: 11)).lineLimit(2)
            Spacer(minLength: 4)
            Toggle(title, isOn: isOn).labelsHidden().toggleStyle(.switch).controlSize(.small)
        }
    }

    private func numberField(value: Binding<Int>, label: String) -> some View {
        TextField("", value: value, formatter: Self.integerFormatter)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.center)
            .frame(width: 42)
            .accessibilityLabel(label)
    }

    private func presetField(value: Binding<Int>) -> some View {
        HStack(spacing: 3) {
            TextField("", value: value, formatter: Self.integerFormatter)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .font(.system(size: 10))
            Text("min").font(.system(size: 9)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func clampPreset(_ value: Int) -> Int {
        min(AppConstants.QuickPresets.maxMinutes, max(AppConstants.QuickPresets.minMinutes, value))
    }

    private func resetSettings() {
        self.goalHours = 2
        self.goalMinutes = 0
        self.quickPreset1 = AppConstants.QuickPresets.defaultValues[0]
        self.quickPreset2 = AppConstants.QuickPresets.defaultValues[1]
        self.quickPreset3 = AppConstants.QuickPresets.defaultValues[2]
        self.sound = AppConstants.SoundSettings.defaultSoundID
        self.volume = AppConstants.SoundSettings.defaultVolume
        self.autoMute = true
        self.focus.hideFloatingTimer = false
        self.distractionSounds = true
        self.reduceMotion = false
        self.glass = false
        self.opacity = AppConstants.FloatingThemeSettings.defaultOpacity
        self.themeID = AppConstants.FloatingThemeSettings.defaultThemeID
        self.analyticsEnabled = AppConstants.AnalyticsSettings.defaultAnalyticsEnabled
    }

    private static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}
