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

/// Uses original item art when available and keeps undiscovered catalog art as a dark silhouette.
struct QyubeCatchArt: View {
    var kindID: String = "uncommon-03"
    var discovered = true

    private var assetName: String? {
        guard let artworkID = CatalogDefinitions.kind(id: kindID)?.artworkID else { return nil }
        let proposed = "Collectible-" + artworkID
        return NSImage(named: proposed) == nil ? nil : proposed
    }

    @ViewBuilder
    var body: some View {
        if let assetName = self.assetName {
            Image(assetName).renderingMode(self.discovered ? .original : .template)
                .resizable().scaledToFit()
                .foregroundStyle(self.discovered ? Color.qyubeAccent : Color.qyubeInk)
                .accessibilityHidden(true)
        }
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
                QyubeInkDivider().frame(maxWidth: 260)
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
        case .common: Color(red: 96 / 255, green: 125 / 255, blue: 139 / 255)
        case .uncommon: Color(red: 59 / 255, green: 99 / 255, blue: 145 / 255)
        case .rare: Color(red: 158 / 255, green: 69 / 255, blue: 61 / 255)
        case .legendary: Color(red: 130 / 255, green: 92 / 255, blue: 41 / 255)
        }
    }
}
