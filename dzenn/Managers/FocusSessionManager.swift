import AVFoundation
import Combine
import Foundation

@MainActor
final class FocusSessionManager: ObservableObject {
    static let shared = FocusSessionManager()

    @Published var activeTask: String = ""
    @Published var duration: TimeInterval = 0
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var state: SessionState = .idle

    private(set) var timerService = TimerService()

    private var cancellables = Set<AnyCancellable>()
    private var completionHandled = false
    private let soundAlertPlayer = SoundAlertPlayer()

    private init() {
        self.timerService.$remainingTime
            .combineLatest(self.timerService.$isRunning, self.timerService.$isPaused)
            .sink { [weak self] remainingTime, isRunning, timerIsPaused in
                guard let self else { return }

                if !self.state.isIdle,
                   !self.completionHandled,
                   !isRunning,
                   !timerIsPaused,
                   remainingTime <= 0
                {
                    self.handleTimerFinished()
                }
            }
            .store(in: &self.cancellables)
    }

    func start(task: String, duration: TimeInterval) {
        self.soundAlertPlayer.stop()
        self.activeTask = task
        self.duration = duration
        self.isActive = true
        self.isPaused = false
        self.state = .running(mode: .quickSession, phase: .focus)
        self.completionHandled = false

        self.timerService.start(duration: duration)
    }

    func stop() {
        self.soundAlertPlayer.stop()
        self.timerService.stop()
        self.completionHandled = true
        self.resetSession()
    }

    func pause() {
        guard self.isActive, !self.isPaused else { return }
        self.timerService.pause()
        self.isPaused = true
    }

    func resume() {
        guard self.isActive, self.isPaused else { return }
        self.timerService.resume()
        self.isPaused = false
    }

    private func breakDuration(for type: BreakType) -> TimeInterval {
        let minutes = type == .short
            ? AppConstants.BreakDuration.shortMinutes
            : AppConstants.BreakDuration.longMinutes
        return TimeInterval(minutes * 60)
    }

    private func handleTimerFinished() {
        self.completionHandled = true
        self.playCompletionSoundIfNeeded()

        switch self.state.phase {
        case .focus:
            self.prepareBreak(type: .short)
            WindowManager.shared.hideFloating()
            MenuBarController.shared?.showPopover()
        case .shortBreak, .longBreak:
            self.completeSession(mode: self.state.mode ?? .quickSession)
            WindowManager.shared.hideFloating()
            MenuBarController.shared?.showPopover()
        case .completed, .none:
            break
        }
    }

    private func resetSession() {
        self.isActive = false
        self.isPaused = false
        self.activeTask = ""
        self.duration = 0
        self.state = .idle
        self.completionHandled = true
    }

    private func completeSession(mode: SessionMode) {
        self.isActive = false
        self.isPaused = false
        self.activeTask = ""
        self.duration = 0
        self.state = .completed(mode: mode)
        self.completionHandled = true
    }

    private func prepareBreak(type: BreakType) {
        self.activeTask = ""
        self.duration = self.breakDuration(for: type)
        self.isActive = false
        self.isPaused = false
        self.state = .configured(mode: .quickSession, phase: type.sessionPhase)
    }

    private func playCompletionSoundIfNeeded() {
        let defaults = UserDefaults.standard
        let selectedSoundID = defaults.string(forKey: AppConstants.SoundSettings.selectedSoundKey)
            ?? AppConstants.SoundSettings.defaultSoundID
        let autoMuteAfter5Seconds =
            defaults.object(forKey: AppConstants.SoundSettings.autoMuteAfter5SecondsKey) as? Bool
                ?? false
        let soundVolume = defaults.object(forKey: AppConstants.SoundSettings.volumeKey) as? Double
            ?? AppConstants.SoundSettings.defaultVolume

        self.soundAlertPlayer.play(
            soundID: selectedSoundID,
            volume: soundVolume,
            autoMuteAfter5Seconds: autoMuteAfter5Seconds)
    }
}

@MainActor
private final class SoundAlertPlayer {
    private var player: AVAudioPlayer?
    private var autoMuteWorkItem: DispatchWorkItem?

    func play(soundID: String, volume: Double, autoMuteAfter5Seconds: Bool) {
        self.stop()

        guard let option = AppConstants.SoundSettings.options.first(where: { $0.id == soundID }) else {
            print("[SoundAlertPlayer] Unknown sound id: \(soundID)")
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
            print("[SoundAlertPlayer] Sound file not found: \(option.fileName).\(option.fileExtension)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            self.player = player
            player.volume = Float(min(1.0, max(0.0, volume)))
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
        } catch {
            print("[SoundAlertPlayer] Failed to play sound: \(error.localizedDescription)")
            return
        }

        guard autoMuteAfter5Seconds else { return }

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
