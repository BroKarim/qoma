import SwiftUI

struct AppearanceSettingsPane: View {
    @AppStorage("qyube.reduceMotionOverride") private var reduceMotionOverride = false
    @AppStorage(AppConstants.FloatingThemeSettings.opacityKey)
    private var floatingOpacity: Double = AppConstants.FloatingThemeSettings.defaultOpacity
    @AppStorage(AppConstants.FloatingThemeSettings.selectedThemeKey)
    private var selectedThemeID: String = AppConstants.FloatingThemeSettings.defaultThemeID
    @AppStorage(AppConstants.FloatingThemeSettings.liquidGlassKey)
    private var liquidGlass = false

    private let themeColumns = [
        GridItem(.adaptive(minimum: 124), spacing: 12, alignment: .top),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsPageHeader(
                    title: "Appearance",
                    subtitle: "Shape floating panel look and visual mood.")

                windowFeelSection
                timerThemeSection
                SettingsSurfaceCard {
                    SettingsRow(
                        title: "Reduce companion motion",
                        subtitle: "Keep the penguin visible with gentler movement.")
                    {
                        Toggle("", isOn: $reduceMotionOverride).toggleStyle(.switch)
                    }
                }
            }
            .padding(24)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .qyubeScrollIndicator()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            floatingOpacity = clampOpacity(floatingOpacity)
        }
        .onChange(of: floatingOpacity) { newValue in
            floatingOpacity = clampOpacity(newValue)
        }
    }

    private var selectedTheme: FloatingTheme {
        FloatingTheme.from(id: selectedThemeID)
    }

    private var windowFeelSection: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Window feel",
                    subtitle: "Core polish that applies instantly to floating panel.")

                if #available(macOS 26.0, *) {
                    SettingsRow(
                        title: "Liquid Glass",
                        subtitle: "Use a translucent glass surface for the floating timer.")
                    {
                        Toggle("Liquid Glass", isOn: $liquidGlass)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    QyubeInkDivider()
                }

                SettingsRow(
                    title: "Opacity",
                    subtitle: "Higher value feels solid. Lower value feels lighter.")
                {
                    HStack(spacing: 12) {
                        CustomSlider(
                            value: $floatingOpacity,
                            range: AppConstants.FloatingThemeSettings.minOpacity...AppConstants
                                .FloatingThemeSettings.maxOpacity,
                            step: 0.01)
                            .frame(width: 220)

                        Text("\(Int((floatingOpacity * 100).rounded()))%")
                            .font(.qoma(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                }
                .disabled(liquidGlassEnabled)
            }
        }
    }

    private var liquidGlassEnabled: Bool {
        if #available(macOS 26.0, *) { return liquidGlass }
        return false
    }

    private var timerThemeSection: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Timer color",
                    subtitle: "Choose floating timer text color.")

                LazyVGrid(columns: themeColumns, spacing: 12) {
                    ForEach(FloatingTheme.allCases) { theme in
                        Button {
                            selectedThemeID = theme.id
                        } label: {
                            FloatingThemeOptionCard(
                                theme: theme,
                                isSelected: theme == selectedTheme)
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
            QyubeInkBorder()
                .fill(Color(white: 0.98))
                .overlay(
                    Text("25:00")
                        .font(.system(size: 22, weight: .medium, design: .serif).monospacedDigit())
                        .foregroundColor(theme.textColor))
                .overlay(
                    QyubeInkBorder()
                        .stroke(theme.borderColor, lineWidth: 1))
                .frame(height: 64)

            HStack(spacing: 8) {
                Text(theme.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.qyubeInk)
                }
            }
        }
        .padding(12)
        .qyubeInkSurface(
            fill: isSelected ? .qyubeSelection : .qyubeSidebar,
            stroke: isSelected ? .qyubeAccent.opacity(0.72) : .qyubeLine)
    }
}
