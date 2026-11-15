import SwiftUI

struct AnalyticsJournalHeading: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.custom("GeistPixel-Regular", size: 17))
                .foregroundStyle(Color.qyubeMenuInk)
            Spacer(minLength: 4)
            Text(detail)
                .font(.custom("GeistPixel-Regular", size: 10))
                .foregroundStyle(Color.qyubeAccent)
        }
    }
}
