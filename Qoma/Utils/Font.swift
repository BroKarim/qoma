import SwiftUI

extension Font {
    static func dzenn(size: CGFloat, weight: Weight = .regular) -> Font {
        .custom("Poppins", size: size).weight(weight)
    }

    static var dzennCaption: Font { .custom("Poppins", size: 11, relativeTo: .caption) }
    static var dzennCaption2: Font { .custom("Poppins", size: 10, relativeTo: .caption2) }
    static var dzennSubheadline: Font { .custom("Poppins", size: 14, relativeTo: .subheadline) }
    static var dzennHeadline: Font { .custom("Poppins", size: 15, relativeTo: .headline) }
    static var dzennTitle2: Font { .custom("Poppins", size: 22, relativeTo: .title2) }
    static var dzennBody: Font { .custom("Poppins", size: 16, relativeTo: .body) }
}
