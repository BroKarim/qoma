import SwiftUI

struct QyubeInkHeader<Trailing: View>: View {
    let title: String
    var titleAction: (() -> Void)?
    @ViewBuilder let trailing: () -> Trailing

    init(title: String, titleAction: (() -> Void)? = nil, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.titleAction = titleAction
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 12) {
            if let titleAction {
                Button(title, action: titleAction)
                    .buttonStyle(.plain)
                    .font(.custom("GeistPixel-Regular", size: 17, relativeTo: .title3))
                    .accessibilityLabel("Go to Today")
            } else {
                Text(title).font(.custom("GeistPixel-Regular", size: 17, relativeTo: .title3))
            }
            Spacer(minLength: 8)
            Canvas { context, size in
                var wave = Path()
                wave.move(to: CGPoint(x: 0, y: size.height * 0.7))
                for index in 0..<3 {
                    let x = CGFloat(index) * size.width / 3
                    wave.addQuadCurve(
                        to: CGPoint(x: x + size.width / 6, y: size.height * 0.25),
                        control: CGPoint(x: x + size.width / 9, y: size.height * 0.5))
                    wave.addCurve(
                        to: CGPoint(x: x + size.width / 3, y: size.height * 0.7),
                        control1: CGPoint(x: x + size.width / 10, y: size.height * 0.9),
                        control2: CGPoint(x: x + size.width / 4, y: size.height * 0.9))
                }
                context.stroke(wave, with: .color(.qyubeMenuInk), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            }
            .frame(width: 58, height: 15).accessibilityHidden(true)
            Spacer(minLength: 8)
            trailing().font(.custom("GeistPixel-Regular", size: 13, relativeTo: .callout))
        }
        .foregroundStyle(Color.qyubeMenuInk)
        .padding(.horizontal, 18).frame(height: 42)
        .overlay(alignment: .bottom) { QyubeInkDivider().frame(height: 3) }
    }
}
