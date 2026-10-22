import SwiftUI

struct SessionOutcomeView: View {
    let onBreak: () -> Void
    let onToday: () -> Void
    @AppStorage(AppConstants.FloatingThemeSettings.liquidGlassKey) private var liquidGlass = false

    var body: some View {
        VStack(spacing: 12) {
            PixelPenguinView().frame(width: 112, height: 112)
            Text("nice work! break?").font(.system(size: 17, weight: .medium, design: .rounded))
            HStack(spacing: 8) {
                action("coffee", label: "Take a 5 minute break", action: onBreak)
                action("fishing", label: "Open Today", action: onToday)
            }
        }
        .foregroundStyle(Color.qyubeInk)
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if #available(macOS 26.0, *), liquidGlass {
                RoundedRectangle(cornerRadius: 20).fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
            } else {
                RoundedRectangle(cornerRadius: 20).fill(.white)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.qyubeLine, lineWidth: 1))
        .environment(\.colorScheme, .light)
    }

    private func action(_ asset: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image("FloatingPixel-\(asset)").resizable().interpolation(.none)
                .scaledToFit().frame(width: 30, height: 30)
                .frame(maxWidth: .infinity).frame(height: 42)
                .background(Color(red: 0.88, green: 0.92, blue: 0.93), in: Capsule())
                .contentShape(Capsule())
        }.buttonStyle(.plain).help(label).accessibilityLabel(label)
    }
}

private struct PixelPenguinView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var nod = false

    var body: some View {
        ZStack(alignment: .top) {
            Image("FloatingPixel-body").resizable().interpolation(.none)
                .scaledToFit().frame(width: 88, height: 74).offset(y: 38)
            Image("FloatingPixel-head").resizable().interpolation(.none)
                .scaledToFit().frame(width: 82, height: 72)
                .rotationEffect(.degrees(reduceMotion ? 0 : (nod ? 4 : -4)), anchor: .bottom)
                .offset(x: reduceMotion ? 0 : (nod ? 1 : -1), y: reduceMotion ? 0 : (nod ? 2 : 0))
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.35).repeatForever(autoreverses: true), value: nod)
        }
        .onAppear { nod = true }
        .accessibilityHidden(true)
    }
}

struct BreakPanelView: View {
    @ObservedObject var readout: TimerReadoutModel
    let finished: Bool
    let onSkip: () -> Void
    let onRepeat: () -> Bool
    let onDone: () -> Void
    let onReview: () -> Void

    @State private var repeatFailed = false

    var body: some View {
        VStack(spacing: 11) {
            Text(finished ? "Break finished" : "Break")
                .font(.system(size: 23, weight: .semibold, design: .serif))
            if finished {
                Text("Ready when you are.")
                    .font(.callout).foregroundStyle(.secondary)
                Button("REPEAT SESSION") {
                    if !onRepeat() { repeatFailed = true }
                }
                .buttonStyle(.plain)
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity).frame(height: 36)
                .foregroundStyle(.white).background(Color.qyubeAccent, in: RoundedRectangle(cornerRadius: 8))
                Button("Done", action: onDone).buttonStyle(.plain)
                if repeatFailed {
                    Button("Review session in Today", action: onReview)
                        .buttonStyle(.plain).font(.caption)
                }
            } else {
                Text(QyubeFormat.countdown(readout.breakRemaining))
                    .font(.system(size: 42, weight: .medium, design: .serif).monospacedDigit())
                Button("Skip break", action: onSkip)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.qyubeAccent)
            }
        }
        .foregroundStyle(Color.qyubeInk)
        .padding(16)
        .frame(width: 260, height: 190)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.qyubeLine, lineWidth: 1))
        .environment(\.colorScheme, .light)
    }
}
