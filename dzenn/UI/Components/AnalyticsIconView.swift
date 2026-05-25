import SwiftUI

enum IconType {
    case app(bundleID: String, iconData: Data?)
    case website(domain: String, iconData: Data?)
}

struct AnalyticsIconView: View {
    let type: IconType
    let size: CGFloat

    var body: some View {
        Group {
            if let iconData, let nsImage = NSImage(data: iconData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.12))
            } else {
                Image(nsImage: createLetterIcon())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.12))
            }
        }
        .frame(width: size, height: size)
    }

    private var iconData: Data? {
        switch type {
        case .app(_, let data): return data
        case .website(_, let data): return data
        }
    }

    private var identifier: String {
        switch type {
        case .app(let id, _): return id
        case .website(let domain, _): return domain
        }
    }

    private func createLetterIcon() -> NSImage {
        let letter = String(identifier.prefix(1)).uppercased()
        let color = colorForString(identifier)
        let image = NSImage(size: NSSize(width: 32, height: 32), flipped: false) { rect in
            color.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).fill()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: NSColor.white
            ]
            let size = (letter as NSString).size(withAttributes: attrs)
            let point = NSPoint(
                x: (rect.width - size.width) / 2,
                y: (rect.height - size.height) / 2
            )
            (letter as NSString).draw(at: point, withAttributes: attrs)
            return true
        }
        return image
    }

    private func colorForString(_ str: String) -> NSColor {
        let colors: [NSColor] = [
            .systemBlue, .systemPurple, .systemPink, .systemOrange,
            .systemGreen, .systemRed, .systemTeal, .systemIndigo
        ]
        let hash = abs(str.hashValue)
        return colors[hash % colors.count]
    }
}
