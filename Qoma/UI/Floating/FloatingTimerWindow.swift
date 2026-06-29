import Combine
import SwiftUI

struct ShouldStartDraftKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var shouldStartDraft: Binding<Bool> {
        get { self[ShouldStartDraftKey.self] }
        set { self[ShouldStartDraftKey.self] = newValue }
    }
}

struct FloatingTimerView: View {
    private static let timerFontName = "RobotoMono-VariableFont_wght"

    @ObservedObject private var timer = FocusSessionManager.shared.timerService
    @ObservedObject private var extensionManager = ExtensionManager.shared

    @AppStorage(AppConstants.FloatingThemeSettings.opacityKey)
    private var floatingOpacity: Double = AppConstants.FloatingThemeSettings.defaultOpacity
    @AppStorage(AppConstants.FloatingThemeSettings.selectedThemeKey)
    private var selectedThemeID: String = AppConstants.FloatingThemeSettings.defaultThemeID

    @State private var isExpanded: Bool = true
    @State private var collapseWorkItem: DispatchWorkItem?
    @State private var requestedSize: CGSize = FloatingLayoutMode.timerOnly.contentSize
    @State private var isTextFieldFocused: Bool = false
    @State private var shouldStartDraftOnAppear: Bool = false

    var body: some View {
        let theme = self.selectedTheme
        let clampedOpacity = min(
            AppConstants.FloatingThemeSettings.maxOpacity,
            max(AppConstants.FloatingThemeSettings.minOpacity, self.floatingOpacity))
        let currentLayout = self.currentLayoutMode

        self.content(for: currentLayout, theme: theme)
            .frame(width: currentLayout.contentSize.width, height: currentLayout.contentSize.height)
            .background(self.panelBackground(theme: theme, opacity: clampedOpacity))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .animation(.easeInOut(duration: 0.2), value: self.floatingOpacity)
            .animation(.easeInOut(duration: 0.25), value: self.isExpanded)
            .onAppear { self.viewAppeared() }
            .onDisappear { self.collapseWorkItem?.cancel() }
            .onChange(of: self.isExpanded) { _ in self.scheduleCollapse() }
            .onChange(of: self.isTextFieldFocused) { focused in
                if focused {
                    self.collapseWorkItem?.cancel()
                } else {
                    self.scheduleCollapse()
                }
            }
            .onChange(of: self.extensionManager.activeExtension?.id) { _ in
                self.collapseWorkItem?.cancel()
                self.isExpanded = true
                self.requestedSize = self.currentLayoutMode.contentSize
                self.notifySizeChange()
            }
            .onChange(of: self.requestedSize) { newSize in
                DispatchQueue.main.async {
                    WindowManager.shared.updateFloatingSize(to: newSize)
                }
            }
    }

    private var currentLayoutMode: FloatingLayoutMode {
        guard let ext = extensionManager.activeExtension else { return .timerOnly }
        return isExpanded ? .featureExpanded(ext) : .featureCollapsed(ext)
    }

    @ViewBuilder
    private func content(for layout: FloatingLayoutMode, theme: FloatingTheme) -> some View {
        switch layout {
        case .timerOnly:
            self.timerOnlyContent(theme: theme)

        case .featureCollapsed(let ext):
            ext.collapsedView(theme: theme, onTap: { self.expand() })
                .environment(\.shouldStartDraft, $shouldStartDraftOnAppear)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture().onEnded { self.resetCollapseTimer() }
                )

        case .featureExpanded(let ext):
            ext.expandedView(
                theme: theme,
                onCollapse: { self.collapse() },
                onFocusChange: { self.isTextFieldFocused = $0 }
            )
                .environment(\.shouldStartDraft, $shouldStartDraftOnAppear)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture().onEnded { self.resetCollapseTimer() }
                )
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

    private func panelBackground(theme: FloatingTheme, opacity: Double) -> some View {
        let panelShape = RoundedRectangle(cornerRadius: 18)

        return panelShape.fill(theme.backgroundColor.opacity(opacity))
            .shadow(color: Color.black.opacity(0.30), radius: 32, x: 0, y: 32)
            .shadow(color: Color.black.opacity(0.30), radius: 16, x: 0, y: 16)
            .shadow(color: Color.black.opacity(0.24), radius: 8, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.24), radius: 4, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: -8)
            .shadow(color: Color.black.opacity(0.24), radius: 2, x: 0, y: 2)
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
                                .init(color: Color.white.opacity(0.0), location: 0.15)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }

    private func format(_ time: TimeInterval) -> String {
        let total = max(0, Int(time.rounded(.down)))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func viewAppeared() {
        isExpanded = true
        requestedSize = currentLayoutMode.contentSize
        notifySizeChange()
        scheduleCollapse()
    }

    private func scheduleCollapse() {
        collapseWorkItem?.cancel()

        guard extensionManager.activeExtension != nil, isExpanded else { return }

        let workItem = DispatchWorkItem { [self] in
            DispatchQueue.main.async {
                guard self.extensionManager.activeExtension != nil, self.isExpanded else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.isExpanded = false
                    self.requestedSize = self.currentLayoutMode.contentSize
                }
            }
        }

        collapseWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + AppConstants.ExtensionSettings.collapsedTimeout,
            execute: workItem
        )
    }

    private func resetCollapseTimer() {
        guard extensionManager.activeExtension != nil else { return }
        scheduleCollapse()
    }

    private func expand() {
        collapseWorkItem?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            isExpanded = true
            requestedSize = currentLayoutMode.contentSize
        }
        scheduleCollapse()
    }

    private func collapse() {
        collapseWorkItem?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            isExpanded = false
            requestedSize = currentLayoutMode.contentSize
        }
    }

    private func notifySizeChange() {
        DispatchQueue.main.async {
            WindowManager.shared.updateFloatingSize(to: self.requestedSize)
        }
    }
}

extension FloatingTimerView {
    var selectedTheme: FloatingTheme {
        FloatingTheme.from(id: self.selectedThemeID)
    }
}
