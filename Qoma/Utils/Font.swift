import SwiftUI

extension Font {
    static func qoma(size: CGFloat, weight: Weight = .regular) -> Font {
        .custom("Poppins", size: size).weight(weight)
    }

    static var qomaCaption: Font { .custom("Poppins", size: 11, relativeTo: .caption) }
    static var qomaCaption2: Font { .custom("Poppins", size: 10, relativeTo: .caption2) }
    static var qomaSubheadline: Font { .custom("Poppins", size: 14, relativeTo: .subheadline) }
    static var qomaHeadline: Font { .custom("Poppins", size: 15, relativeTo: .headline) }
    static var qomaTitle2: Font { .custom("Poppins", size: 22, relativeTo: .title2) }
    static var qomaBody: Font { .custom("Poppins", size: 16, relativeTo: .body) }
}
