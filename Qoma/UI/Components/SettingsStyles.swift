import SwiftUI

struct SettingsPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(self.title)
                .font(.system(size: 38, weight: .regular, design: .serif))

            Text(self.subtitle)
                .font(.qoma(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            QyubeInkDivider().frame(maxWidth: 280)
        }
    }
}

struct SettingsSectionHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(self.title)
                .font(.system(size: 22, design: .serif))

            Text(self.subtitle)
                .font(.qoma(size: 12.5, weight: .medium))
                .foregroundColor(.secondary)

            QyubeInkDivider().frame(maxWidth: 180)
        }
    }
}

struct SettingsSurfaceCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            self.content()
        }
        .padding(20)
        .qyubeInkSurface(fill: .qyubeCardBackground.opacity(0.58))
    }
}

struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content)
    {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        HStack(alignment: self.subtitle == nil ? .center : .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.qoma(size: 13.5, weight: .medium))

                if let subtitle = self.subtitle {
                    Text(subtitle)
                        .font(.qoma(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 16)

            self.content()
        }
    }
}

struct SettingsBadge: View {
    let title: String

    var body: some View {
        Text(self.title)
            .font(.qoma(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(QyubeInkBorder().fill(Color.qyubeSelection))
    }
}
