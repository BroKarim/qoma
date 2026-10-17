import SwiftUI

struct QyubeMenuBarPenguin: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage("qyube.reduceMotionOverride") private var reduceMotion = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: systemReduceMotion || reduceMotion)) { context in
            let movement = systemReduceMotion || reduceMotion
                ? 0 : sin(context.date.timeIntervalSinceReferenceDate * 1.5)
            Image("JournalArcticPenguin")
                .resizable().scaledToFit()
                .rotationEffect(.degrees(movement * 0.8), anchor: .bottom)
                .offset(y: movement * 1.5)
        }
        .accessibilityHidden(true)
    }
}
