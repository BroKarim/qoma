import SwiftUI

extension Font {
    static func dzenn(size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static var dzennCaption: Font { .system(.caption, design: .monospaced) }
    static var dzennCaption2: Font { .system(.caption2, design: .monospaced) }
    static var dzennSubheadline: Font { .system(.subheadline, design: .monospaced) }
    static var dzennHeadline: Font { .system(.headline, design: .monospaced) }
    static var dzennTitle2: Font { .system(.title2, design: .monospaced) }
    static var dzennBody: Font { .system(.body, design: .monospaced) }
}
