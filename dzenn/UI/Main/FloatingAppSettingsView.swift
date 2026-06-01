import SwiftUI

struct FloatingAppSettingsView: View {
    @AppStorage(AppConstants.FloatingThemeSettings.opacityKey)
    private var floatingOpacity: Double = AppConstants.FloatingThemeSettings.defaultOpacity
    @AppStorage(AppConstants.FloatingThemeSettings.selectedThemeKey)
    private var selectedThemeID: String = AppConstants.FloatingThemeSettings.defaultThemeID

    private let themeColumns = [
        GridItem(.adaptive(minimum: 124), spacing: 12, alignment: .top),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsPageHeader(
                    title: "Appearance",
                    subtitle: "Shape floating panel look and visual mood.")

                self.windowFeelSection
                self.timerThemeSection
            }
            .padding(24)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            self.floatingOpacity = self.clampOpacity(self.floatingOpacity)
        }
        .onChange(of: self.floatingOpacity) { newValue in
            self.floatingOpacity = self.clampOpacity(newValue)
        }
    }

    private var selectedTheme: FloatingTheme {
        FloatingTheme.from(id: self.selectedThemeID)
    }

    private var windowFeelSection: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Window feel",
                    subtitle: "Core polish that applies instantly to floating panel.")

                SettingsRow(
                    title: "Opacity",
                    subtitle: "Higher value feels solid. Lower value feels lighter.")
                {
                    HStack(spacing: 12) {
                        CustomSlider(
                            value: self.$floatingOpacity,
                            range: AppConstants.FloatingThemeSettings.minOpacity...AppConstants
                                .FloatingThemeSettings.maxOpacity,
                            step: 0.01)
                            .frame(width: 220)

                        Text("\(Int((self.floatingOpacity * 100).rounded()))%")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                }
            }
        }
    }

    private var timerThemeSection: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Timer color",
                    subtitle: "Choose floating timer text color.")

                LazyVGrid(columns: self.themeColumns, spacing: 12) {
                    ForEach(FloatingTheme.allCases) { theme in
                        Button {
                            self.selectedThemeID = theme.id
                        } label: {
                            FloatingThemeOptionCard(
                                theme: theme,
                                isSelected: theme == self.selectedTheme)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func clampOpacity(_ value: Double) -> Double {
        min(
            AppConstants.FloatingThemeSettings.maxOpacity,
            max(AppConstants.FloatingThemeSettings.minOpacity, value))
    }
}

private struct FloatingThemeOptionCard: View {
    let theme: FloatingTheme
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [self.theme.swatchLeadingColor, self.theme.swatchTrailingColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                .overlay(
                    Text("25:00")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(self.theme.textColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(self.theme.borderColor, lineWidth: 1))
                .frame(height: 64)

            HStack(spacing: 8) {
                Text(self.theme.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer(minLength: 8)

                if self.isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(self.isSelected ? 0.08 : 0.035)))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    self.isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.08),
                    lineWidth: 1))
    }
}
