import AVFoundation
import Foundation
import OSLog

@MainActor
final class SoundAlertPlayer {
    static let shared = SoundAlertPlayer()
    private var player: AVAudioPlayer?
    private var autoMuteWorkItem: DispatchWorkItem?

    func play(soundID: String, volume: Double) {
        self.stop()

        guard soundID != "off" else { return }
        guard let option = AppConstants.SoundSettings.options.first(where: { $0.id == soundID }) else {
            Logger.sound.error("Unknown sound id: \(soundID, privacy: .public)")
            return
        }

        let soundURL =
            Bundle.main.url(
                forResource: option.fileName,
                withExtension: option.fileExtension,
                subdirectory: "Sounds") ??
            Bundle.main.url(
                forResource: option.fileName,
                withExtension: option.fileExtension)

        guard let soundURL else {
            Logger.sound.error("Sound file not found: \(option.fileName).\(option.fileExtension, privacy: .public)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            self.player = player
            player.volume = Float(min(1.0, max(0.0, volume)))
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            Logger.sound.info("Playing sound: \(option.title, privacy: .public)")
        } catch {
            Logger.sound.error("Failed to play sound: \(error.localizedDescription, privacy: .public)")
            return
        }

        // Completion alerts are always short, including previously saved auto-mute=false preferences.

        let workItem = DispatchWorkItem { [weak self] in
            self?.stop()
        }

        self.autoMuteWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
    }

    func stop() {
        self.autoMuteWorkItem?.cancel()
        self.autoMuteWorkItem = nil
        self.player?.stop()
        self.player = nil
    }
}
