import AppKit
import SwiftUI

enum QyubeFormat {
  static func duration(_ seconds: TimeInterval) -> String {
    let minutes = max(0, Int(seconds / 60))
    if minutes == 0 { return seconds > 0 ? "\(Int(seconds))s" : "0m" }
    return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
  }
  static func countdown(_ seconds: TimeInterval) -> String {
    let value = max(0, Int(seconds.rounded(.up)))
    return String(format: "%02d:%02d", value / 60, value % 60)
  }
}

struct QyubePrimaryButton: View {
  let title: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Text(title).font(.system(size: 14, weight: .medium))
        .frame(maxWidth: .infinity).frame(height: 42).foregroundStyle(.white)
        .background(Color.qyubeInk, in: RoundedRectangle(cornerRadius: 9))
    }.buttonStyle(.plain)
  }
}

/// One shared watercolor illustration until the collectible art roster is ready.
struct QyubeCatchArt: View {
  var discovered = true
  var body: some View {
    Image("CompanionFish").renderingMode(discovered ? .original : .template)
      .resizable().scaledToFit().foregroundStyle(Color.qyubeInk).accessibilityHidden(true)
  }
}

struct QyubePenguinArt: View {
  var celebratory = false
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
  @AppStorage("qyube.reduceMotionOverride") private var reduceMotion = false
  @State private var appearedAt = Date()

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 20, paused: systemReduceMotion || reduceMotion))
    { context in
      let elapsed = context.date.timeIntervalSince(appearedAt)
      let movement = systemReduceMotion || reduceMotion ? 0 : sin(elapsed * 1.5)
      Image(celebratory ? "CompanionPoseCompleted" : "CompanionPoseFishing")
        .resizable().scaledToFit().scaleEffect(1.45).rotationEffect(.degrees(movement * 0.8)).offset(
          y: movement * 1.5)
    }.accessibilityLabel(celebratory ? "Happy penguin" : "Penguin fishing")
  }
}

struct WindowDragArea: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView { DragView() }
  func updateNSView(_ nsView: NSView, context: Context) {}
  private final class DragView: NSView {
    override func mouseDown(with event: NSEvent) { window?.performDrag(with: event) }
  }
}
