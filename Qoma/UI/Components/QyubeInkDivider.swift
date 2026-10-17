import SwiftUI

struct QyubeInkDivider: View {
    var axis: Axis = .horizontal

    var body: some View {
        Canvas { context, size in
            var line = Path()
            if axis == .horizontal {
                line.move(to: CGPoint(x: 0, y: size.height * 0.55))
                line.addCurve(
                    to: CGPoint(x: size.width, y: size.height * 0.45),
                    control1: CGPoint(x: size.width * 0.32, y: size.height * 0.2),
                    control2: CGPoint(x: size.width * 0.68, y: size.height * 0.8))
            } else {
                line.move(to: CGPoint(x: size.width * 0.45, y: 0))
                line.addCurve(
                    to: CGPoint(x: size.width * 0.55, y: size.height),
                    control1: CGPoint(x: size.width * 0.8, y: size.height * 0.32),
                    control2: CGPoint(x: size.width * 0.2, y: size.height * 0.68))
            }
            context.stroke(
                line,
                with: .color(.qyubeAccent.opacity(0.48)),
                style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
        }
        .frame(
            maxWidth: axis == .horizontal ? .infinity : 2,
            maxHeight: axis == .vertical ? .infinity : 2)
        .accessibilityHidden(true)
    }
}
