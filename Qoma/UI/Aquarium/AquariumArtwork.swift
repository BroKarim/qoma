import SwiftUI

/// Original vector artwork and deterministic motion for the isolated Aquarium prototype.
/// Coordinates are normalized to a 900 × 580 pool; no images, timers or app services are owned here.
@available(macOS 14.0, *)
enum AquariumArtwork {
    enum Species: Int, CaseIterable {
        case koi, clownfish, blueTang, ray

        var color: Color {
            switch self {
            case .koi: Color(red: 0.95, green: 0.96, blue: 0.91)
            case .clownfish: Color(red: 0.96, green: 0.43, blue: 0.16)
            case .blueTang: Color(red: 0.15, green: 0.48, blue: 0.71)
            case .ray: Color(red: 0.23, green: 0.34, blue: 0.39)
            }
        }
    }

    static func draw(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        // Uniform scaling keeps fish proportions intact in different window sizes.
        let scale = min(size.width / 900, size.height / 580)
        let t = CGFloat(time)
        var art = context
        art.translateBy(x: (size.width - 900 * scale) / 2, y: (size.height - 580 * scale) / 2)
        art.scaleBy(x: scale, y: scale)

        self.drawReef(in: art, at: CGPoint(x: 100, y: 474), time: t, mirrored: false)
        self.drawReef(in: art, at: CGPoint(x: 790, y: 106), time: t + 2, mirrored: true)
        self.drawBottle(in: art, at: CGPoint(x: 735, y: 465), time: t)
        self.drawStar(in: art, at: CGPoint(x: 190, y: 125))
        self.drawSubmarine(in: art, time: t)

        for species in Species.allCases {
            let position = self.location(of: species, time: t)
            let next = self.location(of: species, time: t + 0.05)
            let heading = atan2(next.y - position.y, next.x - position.x)
            var fish = art
            fish.translateBy(x: position.x, y: position.y)
            fish.rotate(by: .radians(Double(heading)))
            let lengthScale: CGFloat = species == .koi ? 1.12 : species == .ray ? 1.10 : 0.86
            fish.scaleBy(x: lengthScale, y: lengthScale)
            fish.addFilter(.shadow(
                color: Color(red: 0.16, green: 0.39, blue: 0.46).opacity(0.20),
                radius: 5,
                x: 3,
                y: 10))
            fish.drawLayer { layer in
                if species == .ray {
                    self.drawRay(in: &layer, time: t)
                } else {
                    self.drawFish(species, in: &layer, time: t)
                }
            }
        }
    }

    /// Smooth bounded courses have continuous headings and never teleport at a waypoint.
    static func location(of species: Species, time t: CGFloat) -> CGPoint {
        let phase = CGFloat(species.rawValue) * 1.7
        let speed: CGFloat = species == .ray ? 0.039 : species == .blueTang ? 0.073 : 0.052
        let a = t * speed + phase
        return CGPoint(
            x: 450 + 245 * cos(a) + 42 * sin(a * 2 + phase),
            y: 290 + 145 * sin(a * 1.23 + phase) + 22 * cos(a * 2))
    }

    /// Continuous body skin around a procedural centerline. Patterns share this deformation,
    /// preventing visible seams between the head, middle body and tail.
    private static func spine(_ u: CGFloat, time: CGFloat) -> CGPoint {
        CGPoint(x: 37 - 79 * u, y: sin(time * 4.2 - u * 5.6) * 8 * u * u)
    }

    private static func halfWidth(_ u: CGFloat, species: Species) -> CGFloat {
        let width: CGFloat = species == .blueTang ? 17 : species == .clownfish ? 14 : 12
        return 2 + width * pow(max(0, sin(.pi * u)), 0.85) * (1 - u * 0.55)
    }

    private static func skin(_ species: Species, time: CGFloat, from: CGFloat = 0, to: CGFloat = 1) -> Path {
        var points: [CGPoint] = []
        for side: CGFloat in [1, -1] {
            for index in 0...32 {
                let fraction = CGFloat(index) / 32
                let u = from + (to - from) * (side > 0 ? fraction : 1 - fraction)
                let p = self.spine(u, time: time)
                points.append(CGPoint(x: p.x, y: p.y + side * self.halfWidth(u, species: species)))
            }
        }
        return self.polygon(points)
    }

    private static func drawFish(_ species: Species, in context: inout GraphicsContext, time: CGFloat) {
        let phase = time + CGFloat(species.rawValue) * 3
        let tail = self.spine(1, time: phase)
        let tailColor = species == .blueTang ? Color(red: 0.97, green: 0.75, blue: 0.26) : species.color
        var caudal = Path()
        caudal.move(to: CGPoint(x: tail.x + 3, y: tail.y))
        caudal.addQuadCurve(to: CGPoint(x: -66, y: tail.y - 15), control: CGPoint(x: -54, y: tail.y - 6))
        caudal.addQuadCurve(to: CGPoint(x: -62, y: tail.y + 15), control: CGPoint(x: -59, y: tail.y))
        caudal.addQuadCurve(to: CGPoint(x: tail.x + 3, y: tail.y), control: CGPoint(x: -49, y: tail.y + 5))
        context.fill(caudal, with: .color(tailColor.opacity(0.85)))
        context.stroke(caudal, with: .color(.black.opacity(0.16)), lineWidth: 0.8)
        for offset: CGFloat in [-9, -3, 3, 9] {
            var ray = Path()
            ray.move(to: tail)
            ray.addLine(to: CGPoint(x: -60, y: tail.y + offset))
            context.stroke(ray, with: .color(.white.opacity(0.42)), lineWidth: 0.7)
        }

        // Paired pectoral fins articulate separately from the body wave.
        for side: CGFloat in [-1, 1] {
            var fin = Path()
            fin.move(to: CGPoint(x: 15, y: side * 7))
            fin.addQuadCurve(
                to: CGPoint(x: -4 + sin(phase * 3) * 3, y: side * 28),
                control: CGPoint(x: 12, y: side * 26))
            fin.addQuadCurve(to: CGPoint(x: 0, y: side * 8), control: CGPoint(x: -12, y: side * 17))
            context.fill(fin, with: .color(species.color.opacity(0.65)))
            context.stroke(fin, with: .color(.white.opacity(0.7)), lineWidth: 0.8)
        }

        let body = self.skin(species, time: phase)
        context.fill(body, with: .linearGradient(
            Gradient(colors: [species.color.opacity(0.85), species.color, species.color.opacity(0.88)]),
            startPoint: CGPoint(x: 0, y: -14),
            endPoint: CGPoint(x: 0, y: 14)))
        context.stroke(body, with: .color(Color.black.opacity(0.15)), lineWidth: 0.8)

        switch species {
        case .clownfish:
            for u: CGFloat in [0.20, 0.51, 0.83] {
                context.fill(
                    self.skin(species, time: phase, from: u - 0.035, to: u + 0.075),
                    with: .color(Color(red: 0.16, green: 0.20, blue: 0.22)))
                context.fill(self.skin(species, time: phase, from: u - 0.008, to: u + 0.05), with: .color(.white))
            }
        case .koi:
            var markings = context
            markings.clip(to: body)
            for (u, offset, radius) in [(CGFloat(0.12), CGFloat(0), CGFloat(9)), (0.46, -4, 12), (0.72, 3, 8)] {
                let p = self.spine(u, time: phase)
                self.ellipse(
                    in: &markings,
                    x: p.x,
                    y: p.y + offset,
                    width: radius * 2,
                    height: radius * 1.7,
                    color: Color(red: 0.91, green: 0.34, blue: 0.17))
            }
            for u: CGFloat in [0.33, 0.63, 0.79] {
                let p = self.spine(u, time: phase)
                self.ellipse(
                    in: &markings,
                    x: p.x,
                    y: p.y - 5,
                    width: 11,
                    height: 7,
                    color: Color(red: 0.18, green: 0.24, blue: 0.27))
            }
        case .blueTang:
            var markings = context
            markings.clip(to: body)
            var stripe = Path()
            stripe.move(to: CGPoint(x: 23, y: -4))
            stripe.addCurve(
                to: self.spine(0.92, time: phase),
                control1: CGPoint(x: -8, y: -17),
                control2: CGPoint(x: -11, y: 4))
            markings.stroke(
                stripe,
                with: .color(Color(red: 0.08, green: 0.18, blue: 0.29)),
                style: StrokeStyle(lineWidth: 7, lineCap: .round))
        case .ray: break
        }

        // Dorsal ridge catches the light; both eyes stay visible from above.
        var ridge = Path()
        ridge.move(to: CGPoint(x: 14, y: -1))
        ridge.addQuadCurve(to: self.spine(0.70, time: phase), control: CGPoint(x: -6, y: -3))
        context.stroke(ridge, with: .color(.white.opacity(0.45)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        for side: CGFloat in [-1, 1] {
            self.ellipse(
                in: &context,
                x: 26,
                y: side * 5.7,
                width: 4.2,
                height: 3.4,
                color: Color(red: 0.08, green: 0.13, blue: 0.16))
            self.ellipse(in: &context, x: 27, y: side * 5.7 - 0.4, width: 1.2, height: 1.2, color: .white)
        }
    }

    private static func drawRay(in context: inout GraphicsContext, time: CGFloat) {
        let flap = sin(time * 1.9) * 6
        var tail = Path()
        tail.move(to: CGPoint(x: -17, y: 0))
        tail.addCurve(
            to: CGPoint(x: -92, y: sin(time * 2) * 8),
            control1: CGPoint(x: -50, y: -5),
            control2: CGPoint(x: -65, y: 13))
        context.stroke(tail, with: .color(Species.ray.color), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        var body = Path()
        body.move(to: CGPoint(x: 33, y: 0))
        body.addCurve(
            to: CGPoint(x: -12, y: -44 + flap),
            control1: CGPoint(x: 17, y: -9),
            control2: CGPoint(x: 11, y: -42 + flap))
        body.addQuadCurve(to: CGPoint(x: -23, y: 0), control: CGPoint(x: -45, y: -13))
        body.addQuadCurve(to: CGPoint(x: -12, y: 44 - flap), control: CGPoint(x: -45, y: 13))
        body.addCurve(to: CGPoint(x: 33, y: 0), control1: CGPoint(x: 11, y: 42 - flap), control2: CGPoint(x: 17, y: 9))
        context.fill(
            body,
            with: .linearGradient(
                Gradient(colors: [Species.ray.color, Color(red: 0.37, green: 0.48, blue: 0.52)]),
                startPoint: CGPoint(x: -20, y: -30),
                endPoint: CGPoint(x: 30, y: 30)))
        context.stroke(body, with: .color(.white.opacity(0.5)), lineWidth: 1)
        var spots = context
        spots.clip(to: body)
        for i in 0..<38 {
            let x = CGFloat((i * 29) % 62) - 30
            let y = CGFloat((i * 17) % 72) - 36
            self.ellipse(in: &spots, x: x, y: y, width: 2.5, height: 2.5, color: .white.opacity(0.72))
        }
        for side: CGFloat in [-1, 1] {
            self.ellipse(in: &context, x: 18, y: side * 5, width: 4, height: 3, color: .black.opacity(0.8))
        }
    }

    private static func drawReef(in context: GraphicsContext, at point: CGPoint, time: CGFloat, mirrored: Bool) {
        var reef = context
        reef.translateBy(x: point.x, y: point.y)
        if mirrored { reef.rotate(by: .degrees(170)) }
        for i in 0..<9 {
            let x = CGFloat(i % 4) * 21 - 31
            let y = CGFloat(i / 4) * 13
            self.ellipse(in: &reef, x: x + 4, y: y + 5, width: 26, height: 18, color: .black.opacity(0.07))
            self.ellipse(
                in: &reef,
                x: x,
                y: y,
                width: 24,
                height: 17,
                color: Color(red: 0.46 + Double(i % 3) * 0.06, green: 0.63, blue: 0.64))
            self.ellipse(in: &reef, x: x - 3, y: y - 3, width: 14, height: 7, color: .white.opacity(0.2))
        }
        for i in 0..<7 {
            let origin = CGFloat(i - 3) * 10
            let height = CGFloat(55 + (i * 19) % 54)
            let sway = sin(time * 0.8 + CGFloat(i) * 0.6) * 9
            var stalk = Path()
            stalk.move(to: CGPoint(x: origin, y: 5))
            stalk.addCurve(
                to: CGPoint(x: origin + sway + 10, y: -height),
                control1: CGPoint(x: origin - 20, y: -height * 0.4),
                control2: CGPoint(x: origin + 28 + sway, y: -height * 0.7))
            reef.stroke(
                stalk,
                with: .color(Color(red: 0.31, green: 0.49 + Double(i % 3) * 0.045, blue: 0.37)),
                style: StrokeStyle(lineWidth: 6, lineCap: .round))
            for j in 1...3 {
                let y = -height * CGFloat(j) / 4
                let side: CGFloat = j.isMultiple(of: 2) ? 1 : -1
                let x = origin + sin(CGFloat(j) + time * 0.8) * 5
                var leaf = Path()
                leaf.move(to: CGPoint(x: x, y: y))
                leaf.addQuadCurve(
                    to: CGPoint(x: x + side * 25 + sway / 3, y: y - 20),
                    control: CGPoint(x: x + side * 30, y: y + 1))
                leaf.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x + side * 8, y: y - 23))
                reef.fill(leaf, with: .color(Color(red: 0.43, green: 0.60, blue: 0.39).opacity(0.85)))
            }
        }
    }

    private static func drawSubmarine(in context: GraphicsContext, time: CGFloat) {
        var sub = context
        sub.translateBy(x: 560 + sin(time * 0.11) * 40, y: 435 + cos(time * 0.15) * 13)
        sub.rotate(by: .radians(Double(-0.3 + sin(time * 0.13) * 0.1)))
        sub.addFilter(.shadow(color: .black.opacity(0.13), radius: 5, x: 5, y: 9))
        sub.drawLayer { layer in
            // Top-down: two symmetric fins, an axial dorsal hatch and rear propeller.
            let fins = self.polygon([
                CGPoint(x: -20, y: -24),
                CGPoint(x: 0, y: -11),
                CGPoint(x: 0, y: 11),
                CGPoint(x: -20, y: 24),
            ])
            layer.fill(fins, with: .color(Color(red: 0.70, green: 0.49, blue: 0.17)))
            self.ellipse(
                in: &layer,
                x: -36,
                y: 0,
                width: 17,
                height: 6,
                color: Color(red: 0.24, green: 0.33, blue: 0.35))
            self.ellipse(
                in: &layer,
                x: -40,
                y: 0,
                width: 5,
                height: 16 + abs(sin(time * 7)) * 9,
                color: Color(red: 0.33, green: 0.40, blue: 0.41))
            let hull = Path(roundedRect: CGRect(x: -31, y: -16, width: 70, height: 32), cornerRadius: 16)
            layer.fill(
                hull,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.99, green: 0.84, blue: 0.43),
                        Color(red: 0.86, green: 0.64, blue: 0.21),
                    ]),
                    startPoint: CGPoint(x: 0, y: -16),
                    endPoint: CGPoint(x: 0, y: 16)))
            layer.stroke(hull, with: .color(Color(red: 0.63, green: 0.46, blue: 0.18)), lineWidth: 1)
            self.ellipse(
                in: &layer,
                x: 5,
                y: 0,
                width: 26,
                height: 20,
                color: Color(red: 0.94, green: 0.75, blue: 0.31))
            self.ellipse(
                in: &layer,
                x: 5,
                y: 0,
                width: 17,
                height: 14,
                color: Color(red: 0.20, green: 0.37, blue: 0.43))
            self.ellipse(in: &layer, x: 7, y: -2, width: 8, height: 5, color: .white.opacity(0.45))
            let hatch = Path(roundedRect: CGRect(x: -18, y: -5, width: 10, height: 10), cornerRadius: 3)
            layer.fill(hatch, with: .color(Color(red: 0.41, green: 0.42, blue: 0.32)))
        }
        for i in 0..<4 {
            let cycle = (time * 0.35 + CGFloat(i) / 4).truncatingRemainder(dividingBy: 1)
            let rect = CGRect(
                x: -50 - cycle * 38,
                y: sin(CGFloat(i) + time) * 6 - 3,
                width: 4 + cycle * 5,
                height: 4 + cycle * 5)
            sub.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(Double(1 - cycle) * 0.6)), lineWidth: 1)
        }
    }

    private static func drawBottle(in context: GraphicsContext, at point: CGPoint, time: CGFloat) {
        var bottle = context
        bottle.translateBy(x: point.x, y: point.y + sin(time * 0.6) * 2)
        bottle.rotate(by: .degrees(32 + Double(sin(time * 0.35)) * 3))
        let body = Path(roundedRect: CGRect(x: -10, y: -11, width: 20, height: 39), cornerRadius: 5)
        bottle.fill(body, with: .color(Color(red: 0.72, green: 0.90, blue: 0.88).opacity(0.75)))
        bottle.stroke(body, with: .color(.white.opacity(0.8)), lineWidth: 1.5)
        bottle.fill(
            Path(CGRect(x: -5, y: -23, width: 10, height: 15)),
            with: .color(Color(red: 0.63, green: 0.80, blue: 0.76)))
        bottle.fill(
            Path(CGRect(x: -5, y: -25, width: 10, height: 6)),
            with: .color(Color(red: 0.62, green: 0.48, blue: 0.31)))
        bottle.fill(
            Path(CGRect(x: -6, y: 0, width: 12, height: 17)),
            with: .color(Color(red: 0.94, green: 0.92, blue: 0.81)))
        for i in 0..<3 {
            bottle.fill(
                Path(CGRect(x: -3, y: CGFloat(i) * 4 + 4, width: 6, height: 1)),
                with: .color(.gray.opacity(0.45)))
        }
    }

    private static func drawStar(in context: GraphicsContext, at point: CGPoint) {
        var star = context
        star.translateBy(x: point.x, y: point.y)
        let vertices = (0..<10).map { i -> CGPoint in
            let angle = CGFloat(i) * .pi / 5 - .pi / 2
            let radius: CGFloat = i.isMultiple(of: 2) ? 23 : 10
            return CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
        }
        star.fill(self.polygon(vertices), with: .color(Color(red: 0.89, green: 0.61, blue: 0.40)))
        star.stroke(self.polygon(vertices), with: .color(.white.opacity(0.55)), lineWidth: 1)
        for i in 0..<5 {
            let angle = CGFloat(i) * .pi * 2 / 5 - .pi / 2
            for r: CGFloat in [4, 9, 14] {
                self.ellipse(
                    in: &star,
                    x: cos(angle) * r,
                    y: sin(angle) * r,
                    width: 2,
                    height: 2,
                    color: .white.opacity(0.65))
            }
        }
    }

    private static func polygon(_ points: [CGPoint]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
    }

    private static func ellipse(
        in context: inout GraphicsContext,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        color: Color)
    {
        context.fill(
            Path(ellipseIn: CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height)),
            with: .color(color))
    }
}
