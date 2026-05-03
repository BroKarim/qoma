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
                VStack(spacing: 0) {
                    self.imageContent(
                        theme: theme,
                        padding: EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 10))
                        .frame(height: AppConstants.FloatingLayoutSettings.mixedImageHeight)
                    self.timerContent(theme: theme)
                        .frame(height: AppConstants.FloatingLayoutSettings.mixedTimerHeight)
                }
            }
        }
        .frame(width: layoutMode.contentSize.width)
        .background(self.panelBackground(theme: theme, opacity: clampedOpacity))
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
            Spacer(minLength: 0)
            Text(self.format(self.timer.remainingTime))
                .font(.custom(Self.timerFontName, size: AppConstants.FloatingLayoutSettings.timerOnlyFontSize))
                .foregroundColor(theme.textColor)
                .padding(.horizontal, AppConstants.FloatingLayoutSettings.timerOnlyHorizontalPadding)
                .offset(y: AppConstants.FloatingLayoutSettings.timerOnlyVerticalOffset)
            Spacer(minLength: 0)
        }
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
                Text("Image")
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding(padding)
    }

    @ViewBuilder
    private func panelBackground(theme: FloatingTheme, opacity: Double) -> some View {
        let panelShape = RoundedRectangle(cornerRadius: 18)

        panelShape
            .fill(theme.backgroundColor.opacity(opacity))
            .overlay(
                panelShape
                    .stroke(theme.borderColor, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
            .graphite
        }
    }

    private func format(_ time: TimeInterval) -> String {
        let total = Int(time)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
