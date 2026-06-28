import SwiftUI

struct ExtensionsSettingsPane: View {
    @AppStorage(AppConstants.ExtensionSettings.todolistEnabledKey)
    private var todolistEnabled: Bool = AppConstants.ExtensionSettings.defaultTodolistEnabled

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SettingsPageHeader(
                    title: "Extensions",
                    subtitle: "Activate optional modules that extend the floating timer panel."
                )

                self.featureExtensions

                self.designExtensions
            }
            .padding(24)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var featureExtensions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionHeading(
                title: "Feature Extensions",
                subtitle: "Add interactive tools to the floating panel.")

            SettingsSurfaceCard {
                extensionCard(
                    title: "Todolist",
                    description: "Checklist inside the floating timer. "
                        + "Add, complete, and reorder tasks during focus sessions.",
                    icon: "checklist",
                    isEnabled: self.$todolistEnabled
                )
            }
        }
    }

    private var designExtensions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionHeading(
                title: "Design Extensions",
                subtitle: "Change the visual style or shape of the floating panel.")

            SettingsSurfaceCard {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "paintpalette")
                            .font(.qoma(size: 18, weight: .regular))
                            .foregroundColor(.secondary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Coming soon")
                                .font(.qoma(size: 14, weight: .semibold))
                            Text("Design extensions will be available in a future update.")
                                .font(.qomaSubheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                }
            }
        }
    }

    private func extensionCard(
        title: String,
        description: String,
        icon: String,
        isEnabled: Binding<Bool>
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.qoma(size: 18, weight: .regular))
                    .foregroundColor(isEnabled.wrappedValue ? .accentColor : .secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.qoma(size: 14, weight: .semibold))
                    Text(description)
                        .font(.qomaSubheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Toggle("", isOn: isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
    }
}
