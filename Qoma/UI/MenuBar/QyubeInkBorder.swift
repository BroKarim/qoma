import SwiftUI

/// A fixed ink contour keeps the hand-drawn edge steady while the timer updates.
struct QyubeInkBorder: Shape {
    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: 1, dy: 1)
        let radius = min(11.0, r.height / 2)
        var path = Path()
        path.move(to: CGPoint(x: r.minX + radius, y: r.minY + 0.6))
        path.addQuadCurve(to: CGPoint(x: r.maxX - radius, y: r.minY), control: CGPoint(x: r.midX, y: r.minY - 0.6))
        path.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + radius), control: CGPoint(x: r.maxX, y: r.minY))
        path.addQuadCurve(
            to: CGPoint(x: r.maxX - 0.5, y: r.maxY - radius),
            control: CGPoint(x: r.maxX + 0.5, y: r.midY))
        path.addQuadCurve(to: CGPoint(x: r.maxX - radius, y: r.maxY), control: CGPoint(x: r.maxX, y: r.maxY))
        path.addQuadCurve(
            to: CGPoint(x: r.minX + radius, y: r.maxY - 0.4),
            control: CGPoint(x: r.midX, y: r.maxY + 0.6))
        path.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY - radius), control: CGPoint(x: r.minX, y: r.maxY))
        path.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + radius), control: CGPoint(x: r.minX - 0.5, y: r.midY))
        path.addQuadCurve(to: CGPoint(x: r.minX + radius, y: r.minY + 0.6), control: CGPoint(x: r.minX, y: r.minY))
        path.closeSubpath()
        return path
    }
}

extension Color {
    static let qyubeMenuInk = Color(red: 37 / 255, green: 62 / 255, blue: 74 / 255)
}
