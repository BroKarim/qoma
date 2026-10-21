import SwiftUI

/// A fixed ink contour keeps the hand-drawn edge steady while the timer updates.
struct QyubeInkBorder: Shape {
    func path(in rect: CGRect) -> Path {
        // Keep the imperfect contour inside its bounds so antialiasing never clips an edge.
        let r = rect.insetBy(dx: 2, dy: 2)
        let radius = min(11.0, r.height / 2)
        var path = Path()
        path.move(to: CGPoint(x: r.minX + radius, y: r.minY + 1.2))
        path.addQuadCurve(to: CGPoint(x: r.maxX - radius, y: r.minY), control: CGPoint(x: r.midX, y: r.minY - 1.4))
        path.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + radius), control: CGPoint(x: r.maxX, y: r.minY))
        path.addQuadCurve(
            to: CGPoint(x: r.maxX - 1.1, y: r.maxY - radius),
            control: CGPoint(x: r.maxX + 1.4, y: r.midY))
        path.addQuadCurve(to: CGPoint(x: r.maxX - radius, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        path.addQuadCurve(
            to: CGPoint(x: r.minX + radius, y: r.maxY - 1.1),
            control: CGPoint(x: r.midX, y: r.maxY + 1.4))
        path.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - radius), control: CGPoint(x: r.minX, y: r.maxY))
        path.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + radius), control: CGPoint(x: r.minX - 1.3, y: r.midY))
        path.addQuadCurve(to: CGPoint(x: r.minX + radius, y: r.minY + 1.2), control: CGPoint(x: r.minX, y: r.minY))
        path.closeSubpath()
        return path
    }
}

extension Color {
    static let qyubeMenuInk = Color(red: 37 / 255, green: 62 / 255, blue: 74 / 255)
}

extension View {
    func qyubeInkSurface(
        fill: Color = .qyubeCardBackground.opacity(0.72),
        stroke: Color = .qyubeAccent.opacity(0.58),
        lineWidth: CGFloat = 1
    ) -> some View {
        background(QyubeInkBorder().fill(fill))
            .overlay(QyubeInkBorder().stroke(stroke, lineWidth: lineWidth).allowsHitTesting(false))
    }
}
