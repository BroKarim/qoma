import SwiftUI
import UniformTypeIdentifiers

struct FloatingAppSettingsView: View {
    @AppStorage(AppConstants.FloatingThemeSettings.opacityKey)
    private var floatingOpacity: Double = AppConstants.FloatingThemeSettings.defaultOpacity
    @AppStorage(AppConstants.FloatingThemeSettings.selectedThemeKey)
    private var selectedThemeID: String = AppConstants.FloatingThemeSettings.defaultThemeID
    @AppStorage(AppConstants.FloatingLayoutSettings.selectedLayoutKey)
    private var layoutModeID: String = AppConstants.FloatingLayoutSettings.defaultLayoutID
    @AppStorage(AppConstants.FloatingLayoutSettings.imagePathKey)
    private var imagePath: String = ""
    @AppStorage(AppConstants.FloatingLayoutSettings.showTimerOnImageKey)
    private var showTimerOnImage: Bool = true
    @AppStorage(AppConstants.FloatingLayoutSettings.imageOffsetXKey)
    private var appliedImageOffsetX: Double = AppConstants.FloatingLayoutSettings.defaultImageOffset
    @AppStorage(AppConstants.FloatingLayoutSettings.imageOffsetYKey)
    private var appliedImageOffsetY: Double = AppConstants.FloatingLayoutSettings.defaultImageOffset

    @State private var draftImageOffsetX: Double = AppConstants.FloatingLayoutSettings.defaultImageOffset
    @State private var draftImageOffsetY: Double = AppConstants.FloatingLayoutSettings.defaultImageOffset
    @State private var cachedImage: NSImage?

    private let styleColumns = [
        GridItem(.adaptive(minimum: 180), spacing: 12, alignment: .top),
    ]
    private let themeColumns = [
        GridItem(.adaptive(minimum: 124), spacing: 12, alignment: .top),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SettingsPageHeader(
                    title: "Appearance",
                    subtitle: "Shape floating panel look, layout, and visual mood.")

                self.styleSection
                self.windowFeelSection
                self.modeSpecificSection
                self.plannedControlsSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            self.floatingOpacity = self.clampOpacity(self.floatingOpacity)
            self.ensureValidSelections()
            self.cachedImage = self.loadImage(path: self.imagePath)
            self.syncDraftOffsetsFromApplied()
            self.syncLegacyImageToggle()
        }
        .onChange(of: self.floatingOpacity) { newValue in
            self.floatingOpacity = self.clampOpacity(newValue)
        }
        .onChange(of: self.imagePath) { newPath in
            self.cachedImage = self.loadImage(path: newPath)
        }
        .onChange(of: self.layoutModeID) { _ in
            self.syncLegacyImageToggle()
        }
    }

    private var selectedLayoutMode: FloatingLayoutMode {
        FloatingLayoutMode.from(id: self.layoutModeID)
    }

    private var selectedTheme: FloatingTheme {
        FloatingTheme.from(id: self.selectedThemeID)
    }

    private var hasSelectedImage: Bool {
        self.cachedImage != nil
    }

    private var selectedImageName: String {
        guard !self.imagePath.isEmpty else { return "No image selected" }
        return URL(fileURLWithPath: self.imagePath).lastPathComponent
    }

    private var styleSection: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Floating style",
                    subtitle: "Pick how Dzenn stays visible while you work.")

                LazyVGrid(columns: self.styleColumns, spacing: 12) {
                    ForEach(FloatingLayoutMode.allCases) { mode in
                        Button {
                            self.selectLayoutMode(mode)
                        } label: {
                            FloatingStyleOptionCard(
                                mode: mode,
                                isSelected: mode == self.selectedLayoutMode,
                                image: self.cachedImage,
                                timerTheme: self.selectedTheme)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
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

                Divider()

                HStack(spacing: 10) {
                    SettingsBadge(title: self.selectedLayoutMode.title)
                    if self.selectedLayoutMode == .timerOnly {
                        SettingsBadge(title: self.selectedTheme.title)
                    } else {
                        SettingsBadge(title: self.hasSelectedImage ? "Image ready" : "Image needed")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var modeSpecificSection: some View {
        if self.selectedLayoutMode == .timerOnly {
            self.timerThemeSection
        } else {
            self.imageSection
        }
    }

    private var timerThemeSection: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Timer color",
                    subtitle: "Shown when Timer Only style active.")

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

    private var imageSection: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Floating image",
                    subtitle: self.selectedLayoutMode == .mixed
                        ? "Artwork stays on top, timer stays below."
                        : "Image Only hides timer and turns panel into visual board.")

                SettingsRow(
                    title: self.hasSelectedImage ? self.selectedImageName : "No image selected",
                    subtitle: "Wide artwork works best. You can replace it anytime.")
                {
                    HStack(spacing: 10) {
                        Button(self.hasSelectedImage ? "Replace Image..." : "Choose Image...") {
                            self.pickImage()
                        }

                        Button("Remove") {
                            self.removeStoredImage()
                        }
                        .disabled(!self.hasSelectedImage)
                    }
                }

                if !self.hasSelectedImage {
                    FloatingImageEmptyState(mode: self.selectedLayoutMode)
                }

                if let image = self.cachedImage {
                    Divider()
                    self.imagePositioningSection(image: image)
                }
            }
        }
    }

    private var plannedControlsSection: some View {
        SettingsSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeading(
                    title: "Good next additions",
                    subtitle: "Strong candidates for future Appearance page polish.")

                VStack(spacing: 10) {
                    PlannedAppearanceRow(
                        title: "Corner radius",
                        subtitle: "Switch between sharper or softer floating edges.")
                    PlannedAppearanceRow(
                        title: "Glass intensity",
                        subtitle: "Control how much blur and translucency show through.")
                    PlannedAppearanceRow(
                        title: "Typography",
                        subtitle: "Alternate timer font, weight, and number spacing.")
                    PlannedAppearanceRow(
                        title: "Shadow depth",
                        subtitle: "Choose softer calm shadow or stronger lifted card.")
                }
            }
        }
    }

    private func imagePositioningSection(image: NSImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image framing")
                .font(.system(size: 14, weight: .semibold))

            FloatingImagePositioningPreview(
                image: image,
                previewAspectRatio: self.previewAspectRatio,
                offsetX: self.$draftImageOffsetX,
                offsetY: self.$draftImageOffsetY)

            HStack(spacing: 12) {
                Button("Apply Position") {
                    self.applyDraftPosition()
                }
                .disabled(!self.hasPendingPositionChanges)

                Button("Reset") {
                    self.resetDraftPosition()
                }
                .disabled(!self.hasDraftPosition)
            }

            Text("Floating panel keeps last applied framing until you press Apply Position.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var previewAspectRatio: CGFloat {
        switch self.selectedLayoutMode {
        case .timerOnly:
            AppConstants.FloatingLayoutSettings.width / AppConstants.FloatingLayoutSettings.imageOnlyHeight
        case .mixed:
            AppConstants.FloatingLayoutSettings.width / AppConstants.FloatingLayoutSettings.mixedImageHeight
        case .imageOnly:
            AppConstants.FloatingLayoutSettings.width / AppConstants.FloatingLayoutSettings.imageOnlyHeight
        }
    }

    private var hasPendingPositionChanges: Bool {
        abs(self.draftImageOffsetX - self.appliedImageOffsetX) > 0.001
            || abs(self.draftImageOffsetY - self.appliedImageOffsetY) > 0.001
    }

    private var hasDraftPosition: Bool {
        abs(self.draftImageOffsetX) > 0.001 || abs(self.draftImageOffsetY) > 0.001
    }

    private func clampOpacity(_ value: Double) -> Double {
        min(
            AppConstants.FloatingThemeSettings.maxOpacity,
            max(AppConstants.FloatingThemeSettings.minOpacity, value))
    }

    private func clampNormalized(_ value: Double) -> Double {
        Double(FloatingImageFraming.clampedNormalized(CGFloat(value)))
    }

    private func ensureValidSelections() {
        let nextTheme = FloatingTheme.from(id: self.selectedThemeID)
        if self.selectedThemeID != nextTheme.id {
            self.selectedThemeID = nextTheme.id
        }

        let nextLayout = FloatingLayoutMode.from(id: self.layoutModeID)
        if self.layoutModeID != nextLayout.id {
            self.layoutModeID = nextLayout.id
        }
    }

    private func syncLegacyImageToggle() {
        self.showTimerOnImage = self.selectedLayoutMode.showsTimer
    }

    private func selectLayoutMode(_ mode: FloatingLayoutMode) {
        withAnimation(.easeInOut(duration: 0.18)) {
            self.layoutModeID = mode.id
        }
    }

    private func syncDraftOffsetsFromApplied() {
        self.draftImageOffsetX = self.clampNormalized(self.appliedImageOffsetX)
        self.draftImageOffsetY = self.clampNormalized(self.appliedImageOffsetY)
    }

    private func applyDraftPosition() {
        self.appliedImageOffsetX = self.clampNormalized(self.draftImageOffsetX)
        self.appliedImageOffsetY = self.clampNormalized(self.draftImageOffsetY)
    }

    private func resetDraftPosition() {
        self.draftImageOffsetX = AppConstants.FloatingLayoutSettings.defaultImageOffset
        self.draftImageOffsetY = AppConstants.FloatingLayoutSettings.defaultImageOffset
    }

    private func resetAppliedPosition() {
        self.appliedImageOffsetX = AppConstants.FloatingLayoutSettings.defaultImageOffset
        self.appliedImageOffsetY = AppConstants.FloatingLayoutSettings.defaultImageOffset
        self.resetDraftPosition()
    }

    private func pickImage() {
        FloatingImagePicker.pickImage { url in
            guard let url else { return }
            if let storedPath = FloatingImageStorage.shared.storeImage(from: url) {
                self.imagePath = storedPath
            } else {
                self.imagePath = url.path
            }
            self.resetAppliedPosition()
        }
    }

    private func removeStoredImage() {
        FloatingImageStorage.shared.removeImage(atPath: self.imagePath)
        self.imagePath = ""
        self.layoutModeID = FloatingLayoutMode.timerOnly.id
        self.resetAppliedPosition()
    }

    private func loadImage(path: String) -> NSImage? {
        guard !path.isEmpty else { return nil }
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        return NSImage(contentsOfFile: path)
    }
}

private struct FloatingStyleOptionCard: View {
    let mode: FloatingLayoutMode
    let isSelected: Bool
    let image: NSImage?
    let timerTheme: FloatingTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            self.preview
                .frame(height: 102)

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.mode.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(self.mode.subtitle)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: self.isSelected ? "checkmark.circle.fill" : self.mode.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(self.isSelected ? .white : Color.white.opacity(0.55))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(self.isSelected ? 0.08 : 0.035)))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    self.isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.08),
                    lineWidth: 1))
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.16))

            switch self.mode {
            case .timerOnly:
                self.timerOnlyPreview
            case .mixed:
                self.mixedPreview
            case .imageOnly:
                self.imageOnlyPreview
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var timerOnlyPreview: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(self.timerTheme.backgroundColor)
            .overlay(
                Text("25:00")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(self.timerTheme.textColor))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(self.timerTheme.borderColor, lineWidth: 1))
            .padding(.horizontal, 36)
            .padding(.vertical, 24)
    }

    private var mixedPreview: some View {
        VStack(spacing: 0) {
            self.imagePanel(cornerRadius: 10)
                .frame(height: 58)

            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(Color(red: 20.0 / 255.0, green: 23.0 / 255.0, blue: 31.0 / 255.0))
                .overlay(
                    Text("25:00")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white))
                .frame(height: 28)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var imageOnlyPreview: some View {
        self.imagePanel(cornerRadius: 12)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
    }

    @ViewBuilder
    private func imagePanel(cornerRadius: CGFloat) -> some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.08))

                if let image = self.image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                } else {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.06),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.55)))
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1))
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

private struct FloatingImageEmptyState: View {
    let mode: FloatingLayoutMode

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "photo.badge.plus")
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Image style needs artwork")
                        .font(.system(size: 13, weight: .semibold))

                    Text(
                        self.mode == .mixed
                            ? "Choose image to complete timer + image layout."
                            : "Choose image to activate artwork-only floating panel.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.03)))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [5, 6])))
    }
}

private struct PlannedAppearanceRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.system(size: 13.5, weight: .semibold))

                Text(self.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 12)

            SettingsBadge(title: "Coming soon")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.03)))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

private struct FloatingImagePositioningPreview: View {
    let image: NSImage
    let previewAspectRatio: CGFloat
    @Binding var offsetX: Double
    @Binding var offsetY: Double

    @State private var dragStartOffset: CGSize?

    private let previewWidth: CGFloat = 280

    var body: some View {
        GeometryReader { _ in
            let containerSize = CGSize(width: self.previewWidth, height: self.previewWidth / self.previewAspectRatio)
            let normalizedOffset = FloatingImageFraming.clampedNormalizedOffset(x: self.offsetX, y: self.offsetY)
            let imageOffset = FloatingImageFraming.offset(
                fromNormalized: normalizedOffset,
                imageSize: self.image.size,
                containerSize: containerSize)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))

                Image(nsImage: self.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: containerSize.width, height: containerSize.height)
                    .offset(x: imageOffset.width, y: imageOffset.height)
                    .frame(width: containerSize.width, height: containerSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)

                Text("Drag to reposition")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        VisualEffectBackground(material: .hudWindow, blendingMode: .withinWindow)
                            .clipShape(Capsule()))
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(width: containerSize.width, height: containerSize.height)
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if self.dragStartOffset == nil {
                            self.dragStartOffset = imageOffset
                        }
                        guard let dragStartOffset = self.dragStartOffset else { return }

                        let next = CGSize(
                            width: dragStartOffset.width + value.translation.width,
                            height: dragStartOffset.height + value.translation.height)

                        let limits = FloatingImageFraming.maxOffset(
                            imageSize: self.image.size,
                            containerSize: containerSize)
                        let clamped = CGSize(
                            width: min(max(next.width, -limits.width), limits.width),
                            height: min(max(next.height, -limits.height), limits.height))

                        let normalized = FloatingImageFraming.normalized(
                            fromOffset: clamped,
                            imageSize: self.image.size,
                            containerSize: containerSize)
                        self.offsetX = normalized.width
                        self.offsetY = normalized.height
                    }
                    .onEnded { _ in
                        self.dragStartOffset = nil
                    })
        }
        .frame(width: self.previewWidth, height: self.previewWidth / self.previewAspectRatio)
    }
}

private enum FloatingImagePicker {
    static func pickImage(completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        panel.begin { response in
            guard response == .OK else {
                completion(nil)
                return
            }
            completion(panel.url)
        }
    }
}
