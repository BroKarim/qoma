import SwiftUI

struct FloatingTimerView: View {
    private static let timerFontName = "RobotoMono-VariableFont_wght"

    @ObservedObject private var timer = FocusSessionManager.shared.timerService

    @AppStorage(AppConstants.FloatingThemeSettings.opacityKey)
    private var floatingOpacity: Double = AppConstants.FloatingThemeSettings.defaultOpacity
    @AppStorage(AppConstants.FloatingThemeSettings.selectedThemeKey)
    private var selectedThemeID: String = AppConstants.FloatingThemeSettings.defaultThemeID
    @AppStorage(AppConstants.FloatingLayoutSettings.selectedLayoutKey)
    private var layoutModeID: String = AppConstants.FloatingLayoutSettings.defaultLayoutID
    @AppStorage(AppConstants.FloatingLayoutSettings.imagePathKey) private var imagePath: String = ""
    @AppStorage(AppConstants.FloatingLayoutSettings.imageOffsetXKey)
    private var imageOffsetX: Double = AppConstants.FloatingLayoutSettings.defaultImageOffset
    @AppStorage(AppConstants.FloatingLayoutSettings.imageOffsetYKey)
    private var imageOffsetY: Double = AppConstants.FloatingLayoutSettings.defaultImageOffset

    @State private var cachedImage: NSImage?

    var body: some View {
        let layoutMode = FloatingLayoutMode.from(id: self.layoutModeID)
        let theme = self.theme(for: layoutMode)
        let clampedOpacity = min(
            AppConstants.FloatingThemeSettings.maxOpacity,
            max(AppConstants.FloatingThemeSettings.minOpacity, self.floatingOpacity))

        Group {
            switch layoutMode {
            case .timerOnly:
                self.timerOnlyContent(theme: theme)
                    .frame(height: AppConstants.FloatingLayoutSettings.timerOnlyHeight)
            case .imageOnly:
                self.imageContent(theme: theme)
                    .frame(height: AppConstants.FloatingLayoutSettings.imageOnlyHeight)
            case .mixed:
                self.mixedContent(theme: theme)
                    .frame(height: AppConstants.FloatingLayoutSettings.mixedHeight)
            }
        }
        .frame(width: layoutMode.contentSize.width)
        .background(self.panelBackground(theme: theme, opacity: clampedOpacity, isTimerOnly: layoutMode == .timerOnly))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .animation(.easeInOut(duration: 0.2), value: self.floatingOpacity)
        .onAppear {
            self.cachedImage = self.loadImage(path: self.imagePath)
            WindowManager.shared.updateFloatingSize(mode: layoutMode)
        }
        .onChange(of: self.imagePath) { newPath in
            self.cachedImage = self.loadImage(path: newPath)
        }
        .onChange(of: self.layoutModeID) { _ in
            WindowManager.shared.updateFloatingSize(mode: FloatingLayoutMode.from(id: self.layoutModeID))
        }
    }

    private func timerOnlyContent(theme: FloatingTheme) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Text(self.format(self.timer.remainingTime))
                .font(.custom(Self.timerFontName, size: AppConstants.FloatingLayoutSettings.timerOnlyFontSize))
                .foregroundColor(theme.textColor)
                .baselineOffset(-(AppConstants.FloatingLayoutSettings.timerOnlyFontSize * 0.15))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func timerContent(theme: FloatingTheme) -> some View {
        HStack {
            Spacer()
            Text(self.format(self.timer.remainingTime))
                .font(.custom(Self.timerFontName, size: AppConstants.FloatingLayoutSettings.mixedTimerFontSize))
                .foregroundColor(theme.textColor)
            Spacer()
        }
        .padding(.horizontal, AppConstants.FloatingLayoutSettings.mixedTimerHorizontalPadding)
        .padding(.vertical, 0)
        .frame(maxHeight: .infinity)
    }

    private func mixedContent(theme: FloatingTheme) -> some View {
        ZStack(alignment: .topLeading) {
            self.imageContent(
                theme: theme,
                padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

            Text(self.format(self.timer.remainingTime))
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(red: 0.55, green: 0.1, blue: 0.1))
                )
                .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func imageContent(
        theme: FloatingTheme,
        padding: EdgeInsets = EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)) -> some View
    {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.borderColor)
                .opacity(0.2)

            if let image = cachedImage {
                GeometryReader { proxy in
                    let containerSize = proxy.size
                    let normalizedOffset =
                        FloatingImageFraming.clampedNormalizedOffset(x: self.imageOffsetX, y: self.imageOffsetY)
                    let imageOffset = FloatingImageFraming.offset(
                        fromNormalized: normalizedOffset,
                        imageSize: image.size,
                        containerSize: containerSize)

                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: containerSize.width, height: containerSize.height)
                        .offset(x: imageOffset.width, y: imageOffset.height)
                        .frame(width: containerSize.width, height: containerSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                Text("Choose Image")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding(padding)
    }

@ViewBuilder
private func panelBackground(theme: FloatingTheme, opacity: Double, isTimerOnly: Bool = false) -> some View {
    let panelShape = RoundedRectangle(cornerRadius: 18)
    let baseBackground = panelShape.fill(theme.backgroundColor.opacity(opacity))

    if isTimerOnly {
        baseBackground
            // === Drop Shadows (luar ke dalam, besar ke kecil) ===
            // shadow-[0px_32px_64px_-16px_rgba(0,0,0,0.30)] → blur=64 → radius=32, y=32
            .shadow(color: Color.black.opacity(0.30), radius: 32, x: 0, y: 32)
            // shadow-[0px_16px_32px_-8px_rgba(0,0,0,0.30)] → blur=32 → radius=16, y=16
            .shadow(color: Color.black.opacity(0.30), radius: 16, x: 0, y: 16)
            // shadow-[0px_8px_16px_-4px_rgba(0,0,0,0.24)] → blur=16 → radius=8, y=8
            .shadow(color: Color.black.opacity(0.24), radius: 8, x: 0, y: 8)
            // shadow-[0px_4px_8px_-2px_rgba(0,0,0,0.24)] → blur=8 → radius=4, y=4
            .shadow(color: Color.black.opacity(0.24), radius: 4, x: 0, y: 4)
            // shadow-[0px_-8px_16px_-1px_rgba(0,0,0,0.16)] → blur=16 → radius=8, y=-8 (shadow ke atas)
            .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: -8)
            // shadow-[0px_2px_4px_-1px_rgba(0,0,0,0.24)] → blur=4 → radius=2, y=2
            .shadow(color: Color.black.opacity(0.24), radius: 2, x: 0, y: 2)

            // === Outer Border: shadow-[0px_0px_0px_1px_rgba(0,0,0,1.00)] ===
            // Simulasi border hitam solid (spread=1 tanpa blur) → pakai stroke
            .overlay(
                panelShape
                    .stroke(Color.black.opacity(1.0), lineWidth: 1)
            )

            .overlay(
                panelShape
                    .fill(Color.white.opacity(0.08))
                    .blendMode(.plusLighter)
            )

            .overlay(
                panelShape
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0.20), location: 0.0),
                                .init(color: Color.white.opacity(0.0),  location: 0.15)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    } else {
        baseBackground
            .overlay(
                panelShape
                    .stroke(theme.borderColor, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

    private func loadImage(path: String) -> NSImage? {
        guard !path.isEmpty else { return nil }
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        return NSImage(contentsOfFile: path)
    }

    private func theme(for layoutMode: FloatingLayoutMode) -> FloatingTheme {
        switch layoutMode {
        case .timerOnly:
            FloatingTheme.from(id: self.selectedThemeID)
        case .mixed, .imageOnly:
            .obsidian
        }
    }

    private func format(_ time: TimeInterval) -> String {
        let total = max(0, Int(time.rounded(.down)))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
