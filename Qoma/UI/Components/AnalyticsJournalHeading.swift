import SwiftUI

struct AnalyticsJournalHeading: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 17, design: .serif))
                .foregroundStyle(Color.qyubeMenuInk)
            Spacer(minLength: 4)
            Text(detail)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.qyubeAccent)
        }
    }
}

\n