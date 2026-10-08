import AppKit
import AVFoundation

@MainActor
final class DistractionAudioPlayer {
    nonisolated static let enabledKey = "qyube.distractionSounds"
    private var player: AVAudioPlayer?
    private var fadeTask: Task<Void, Never>?
    private let enabled: () -> Bool

    init(enabled: @escaping () -> Bool = {
        UserDefaults.standard.object(forKey: DistractionAudioPlayer.enabledKey) as? Bool ?? true
    }) {
        self.enabled = enabled
    }

    func play(_ cue: DistractionSoundCue) {
        stop()
        guard enabled() else { return }
        let name = cue == .freeze ? "IceFreezingSound" : "LightSwitchSound"
        guard let data = NSDataAsset(name: name)?.data,
            let player = try? AVAudioPlayer(data: data) else { return }
        let volume = UserDefaults.standard.object(forKey: AppConstants.SoundSettings.volumeKey) as? Double
            ?? AppConstants.SoundSettings.defaultVolume
        player.volume = Float(min(1, max(0, volume))) * 0.65
        player.prepareToPlay()
        self.player = player
        player.play()
        if cue == .freeze {
            fadeTask = Task { @MainActor [weak self, weak player] in
                do {
                    try await Task.sleep(for: .seconds(1.4))
                    guard !Task.isCancelled else { return }
                    player?.setVolume(0, fadeDuration: 0.2)
                    try await Task.sleep(for: .seconds(0.2))
                    guard !Task.isCancelled else { return }
                    player?.stop()
                    self?.player = nil
                } catch { /* Cancellation stops the previous cue without touching a new player. */ }
            }
        }
    }

    func stop() {
        fadeTask?.cancel()
        fadeTask = nil
        player?.stop()
        player = nil
    }
}
