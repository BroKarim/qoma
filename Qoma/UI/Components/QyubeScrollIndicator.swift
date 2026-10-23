import AppKit
import SwiftUI

private enum QyubeScrollAxis {
    case horizontal, vertical
}

private struct QyubeScrollMetrics: Equatable {
    var contentLength: CGFloat = 0
    var viewportLength: CGFloat = 0
    var offset: CGFloat = 0
}

private final class QyubeScrollProbeView: NSView {
    var hierarchyDidChange: (() -> Void)?

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        hierarchyDidChange?()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        hierarchyDidChange?()
    }
}

private struct QyubeScrollObserver: NSViewRepresentable {
    @Binding var metrics: QyubeScrollMetrics
    let axis: QyubeScrollAxis
    let tracksMetrics: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(metrics: self.$metrics, axis: self.axis, tracksMetrics: self.tracksMetrics)
    }

    func makeNSView(context: Context) -> NSView {
        let view = QyubeScrollProbeView(frame: .zero)
        view.hierarchyDidChange = { [weak coordinator = context.coordinator, weak view] in
            guard let view else { return }
            coordinator?.attach(to: view)
        }
        context.coordinator.attach(to: view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        guard let view = view as? QyubeScrollProbeView else { return }
        context.coordinator.metrics = self.$metrics
        context.coordinator.attach(to: view)
    }

    final class Coordinator {
        var metrics: Binding<QyubeScrollMetrics>
        private let axis: QyubeScrollAxis
        private let tracksMetrics: Bool
        private weak var scrollView: NSScrollView?
        private var observer: NSObjectProtocol?

        init(metrics: Binding<QyubeScrollMetrics>, axis: QyubeScrollAxis, tracksMetrics: Bool) {
            self.metrics = metrics
            self.axis = axis
            self.tracksMetrics = tracksMetrics
        }

        deinit {
            if let observer { NotificationCenter.default.removeObserver(observer) }
        }

        func attach(to view: QyubeScrollProbeView) {
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view else { return }
                guard let scrollView = view.enclosingScrollView else { return }
                scrollView.hasVerticalScroller = false
                scrollView.hasHorizontalScroller = false
                scrollView.autohidesScrollers = true
                scrollView.verticalScroller?.alphaValue = 0
                scrollView.horizontalScroller?.alphaValue = 0
                scrollView.scrollerStyle = .overlay
                scrollView.drawsBackground = false
                guard self.scrollView !== scrollView else { return }

                self.scrollView = scrollView

                guard self.tracksMetrics else { return }
                scrollView.contentView.postsBoundsChangedNotifications = true
                self.observer = NotificationCenter.default.addObserver(
                    forName: NSView.boundsDidChangeNotification,
                    object: scrollView.contentView,
                    queue: .main
                ) { [weak self] _ in
                    self?.updateMetrics()
                }
                self.updateMetrics()
            }
        }

        private func updateMetrics() {
            guard let scrollView else { return }
            let clip = scrollView.contentView.bounds
            let document = scrollView.documentView?.bounds ?? .zero
            self.metrics.wrappedValue = QyubeScrollMetrics(
                contentLength: self.axis == .vertical ? document.height : document.width,
                viewportLength: self.axis == .vertical ? clip.height : clip.width,
                offset: self.axis == .vertical ? clip.minY : clip.minX)
        }
    }
}

private struct QyubeScrollIndicator: ViewModifier {
    let axis: QyubeScrollAxis
    @State private var metrics = QyubeScrollMetrics()
    @State private var isVisible = false
    @State private var hideToken = UUID()

    func body(content: Content) -> some View {
        content
            .scrollIndicators(.hidden)
            .background(QyubeScrollObserver(metrics: self.$metrics, axis: self.axis, tracksMetrics: true))
            .overlay(alignment: self.axis == .vertical ? .topTrailing : .bottomLeading) {
                self.indicator
            }
            .onChange(of: self.metrics.offset) { _, _ in self.showTemporarily() }
    }

    private var indicator: some View {
        let scrollableLength = max(self.metrics.contentLength - self.metrics.viewportLength, 0)
        let trackLength = max(self.metrics.viewportLength - 8, 0)
        let thumbLength = max(24, trackLength * self.metrics.viewportLength / max(self.metrics.contentLength, 1))
        let progress = scrollableLength > 0 ? min(max(self.metrics.offset / scrollableLength, 0), 1) : 0
        let position = 4 + max(trackLength - thumbLength, 0) * progress

        return Capsule()
            .fill(self.axis == .vertical ? Color.qyubeInk.opacity(0.25) : Color.qyubeAccent.opacity(0.35))
            .frame(
                width: self.axis == .vertical ? 3 : min(thumbLength, trackLength),
                height: self.axis == .vertical ? min(thumbLength, trackLength) : 3)
            .offset(x: self.axis == .horizontal ? position : 0, y: self.axis == .vertical ? position : -2)
            .padding(.trailing, self.axis == .vertical ? 4 : 0)
            .opacity(self.isVisible && scrollableLength > 0 ? 1 : 0)
            .animation(.easeOut(duration: 0.2), value: self.isVisible)
            .allowsHitTesting(false)
    }

    private func showTemporarily() {
        self.isVisible = true
        let token = UUID()
        self.hideToken = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard self.hideToken == token else { return }
            self.isVisible = false
        }
    }
}

extension View {
    func qyubeScrollIndicator() -> some View {
        modifier(QyubeScrollIndicator(axis: .vertical))
    }

    func qyubeHorizontalScrollIndicator() -> some View {
        modifier(QyubeScrollIndicator(axis: .horizontal))
    }

    func qyubeHideNativeScrollers() -> some View {
        background(QyubeScrollObserver(
            metrics: .constant(QyubeScrollMetrics()),
            axis: .horizontal,
            tracksMetrics: false))
            .scrollIndicators(.hidden)
    }
}
