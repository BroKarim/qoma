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
        Button(action: self.action) {
            Text(self.title).font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity).frame(height: 42).foregroundStyle(.white)
                .background(Color.qyubeInk, in: RoundedRectangle(cornerRadius: 9))
        }.buttonStyle(.plain)
    }
}

/// Bundled art only; the catalog fish is intentionally shared until its final art is chosen.
struct QyubeCatchArt: View {
    var kindID: String = "anchovy"
    var discovered = true
    var catalog = false

    private var assetName: String {
        guard let kind = CatalogDefinitions.kind(id: kindID) else { return "" }
        return self.catalog && kind.isFish ? "CatalogFishPlaceholder" : "Collectible-" + self.kindID
    }

    var body: some View {
        Group {
            if self.assetName.isEmpty {
                Image(systemName: "questionmark.diamond").resizable().scaledToFit()
            } else {
                Image(self.assetName).renderingMode(self.discovered ? .original : .template)
                    .resizable().scaledToFit()
            }
        }
        .foregroundStyle(Color.qyubeInk)
        .accessibilityHidden(true)
    }
}

struct QyubePenguinArt: View {
    var celebratory = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage("qyube.reduceMotionOverride") private var reduceMotion = false
    @State private var appearedAt = Date()

    var body: some View {
        TimelineView(.animation(
            minimumInterval: 1.0 / 20,
            paused: self.systemReduceMotion || self.reduceMotion))
        { context in
            let elapsed = context.date.timeIntervalSince(self.appearedAt)
            let movement = self.systemReduceMotion || self.reduceMotion ? 0 : sin(elapsed * 1.5)
            Image(self.celebratory ? "CompanionPoseCompleted" : "CompanionPoseFishing")
                .resizable().scaledToFit().scaleEffect(1.45).rotationEffect(.degrees(movement * 0.8)).offset(
                    y: movement * 1.5)
        }.accessibilityLabel(self.celebratory ? "Happy penguin" : "Penguin fishing")
    }
}

struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DragView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
    private final class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}

struct JournalPageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 16) {
                Text(self.eyebrow).font(.system(size: 9, weight: .medium)).tracking(3)
                    .foregroundStyle(Color.qyubeAccent)
                Rectangle().fill(Color.qyubeLine).frame(maxWidth: 260).frame(height: 0.5)
            }.padding(.bottom, 8)
            Text(self.title).font(.system(size: 44, design: .serif))
            Text(self.subtitle).font(.system(size: 17, design: .serif)).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

extension CatalogDefinitions.Rarity {
    var color: Color {
        switch self {
        case .common: Color(red: 0.28, green: 0.43, blue: 0.32)
        case .uncommon: Color(red: 0.23, green: 0.39, blue: 0.57)
        case .rare: Color(red: 0.62, green: 0.27, blue: 0.24)
        case .legendary: Color(red: 0.51, green: 0.36, blue: 0.16)
        }
    }
}
