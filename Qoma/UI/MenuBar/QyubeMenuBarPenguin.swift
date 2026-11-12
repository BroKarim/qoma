import SwiftUI

struct QyubeMenuBarPenguin: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: systemReduceMotion)) { context in
            let movement = systemReduceMotion
                ? 0 : sin(context.date.timeIntervalSinceReferenceDate * 1.5)
            Image("JournalArcticPenguin")
                .resizable().scaledToFit()
                .rotationEffect(.degrees(movement * 0.8), anchor: .bottom)
                .offset(y: movement * 1.5)
        }
        .accessibilityHidden(true)
    }
}
