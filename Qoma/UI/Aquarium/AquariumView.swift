import SwiftUI

/// Standalone visual sandbox. It deliberately owns no session or collection data.
@available(macOS 14.0, *)
struct AquariumView: View {
    @State private var isPlaying = true
    @State private var waterEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Aquarium")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.10, green: 0.14, blue: 0.18))
                    Text("A little ocean of your own.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                Label("Calm Sea", systemImage: "water.waves")
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.black.opacity(0.08))
                    }
            }

            AquariumScene(isPlaying: self.isPlaying, waterEnabled: self.waterEnabled)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

            HStack(spacing: 14) {
                Label("4 species", systemImage: "fish")
                Text("•").accessibilityHidden(true)
                Text("Just swimming along")
                Spacer(minLength: 0)
                Button {
                    self.waterEnabled.toggle()
                } label: {
                    Image(systemName: self.waterEnabled ? "water.waves" : "water.waves.slash")
                        .frame(width: 30, height: 30)
                }
                .help(self.waterEnabled ? "Turn off water effects" : "Turn on water effects")
                .accessibilityLabel(self.waterEnabled ? "Turn off water effects" : "Turn on water effects")

                Button {
                    self.isPlaying.toggle()
                } label: {
                    Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 30, height: 30)
                }
                .help(self.isPlaying ? "Pause aquarium" : "Resume aquarium")
                .accessibilityLabel(self.isPlaying ? "Pause aquarium" : "Resume aquarium")
            }
            .buttonStyle(.bordered)
            .font(.caption)
            .foregroundStyle(Color(red: 0.38, green: 0.45, blue: 0.49))
        }
        .padding(.horizontal, 28)
        .padding(.top, 48)
        .padding(.bottom, 24)
        .background(Color(red: 0.975, green: 0.982, blue: 0.985))
        .environment(\.colorScheme, .light)
    }
}

/// Only this subtree ticks. Header, sidebar and controls do not observe animation time.
@available(macOS 14.0, *)
private struct AquariumScene: View {
    let isPlaying: Bool
    let waterEnabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var elapsed: TimeInterval = 0
    @State private var runningSince: TimeInterval?
    @State private var isVisible = false
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

    private var shouldAnimate: Bool {
        self.isVisible && self.isPlaying && !self.reduceMotion && self.scenePhase == .active
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: self.lowPower ? 1 / 15 : 1 / 30, paused: !self.shouldAnimate)) { _ in
            let time = self.elapsed + (self.runningSince.map { ProcessInfo.processInfo.systemUptime - $0 } ?? 0)
            GeometryReader { geometry in
                ZStack {
                    Rectangle()
                        .fill(Color(red: 0.66, green: 0.85, blue: 0.90))
                        .colorEffect(ShaderLibrary.aquariumWater(
                            .float2(geometry.size),
                            .float(time),
                            .float(self.waterEnabled && !self.reduceMotion && !self.lowPower ? 1 : 0)))
                    Canvas { context, size in
                        AquariumArtwork.draw(in: &context, size: size, time: time)
                    }
                }
                .compositingGroup()
                .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .strokeBorder(.white.opacity(0.72), lineWidth: 8)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .strokeBorder(Color(red: 0.43, green: 0.64, blue: 0.69).opacity(0.25), lineWidth: 1)
                }
                .shadow(color: Color(red: 0.32, green: 0.54, blue: 0.61).opacity(0.12), radius: 12, y: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Aquarium with a koi, clownfish, blue tang and spotted ray.")
        .accessibilityValue("Seaweed, rocks, a starfish, a discarded bottle and a yellow submarine.")
        .onAppear { self.isVisible = true; self.updateClock() }
        .onDisappear { self.isVisible = false; self.updateClock() }
        .onChange(of: self.shouldAnimate) { self.updateClock() }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            self.lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    private func updateClock() {
        let now = ProcessInfo.processInfo.systemUptime
        if self.shouldAnimate, self.runningSince == nil {
            self.runningSince = now
        } else if !self.shouldAnimate, let start = runningSince {
            self.elapsed += now - start
            self.runningSince = nil
        }
    }
}

#Preview("Aquarium • standalone") {
    if #available(macOS 14.0, *) {
        AquariumView().frame(width: 780, height: 620)
    }
}
