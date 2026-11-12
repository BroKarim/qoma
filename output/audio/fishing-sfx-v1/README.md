# Fishing sound effects — draft 1

Procedurally synthesized rod movement, water and bubble effects; no music or victory melody. WAV, mono, 48 kHz, 16-bit PCM. All six files total about 1.3 MB. The app has not been modified.

Timing references: `Qoma/UI/Floating/Companion/CompanionPlayback.swift` and `CompanionScene.swift`, inspected 12 November 2026.

| File | Duration | Suggested visual cue |
| --- | --- | --- |
| cast-0550ms.wav | 0.55 s | Start of `.casting`; water contact at 0.4675 s = progress 0.85, when the splash appears. |
| waiting-water-loop-8s.wav | 8 s, circular | `.fishing` lasts a random 6–10 s. Loop quietly and fade out in about 40 ms on phase exit. This file length does not change the animation duration. |
| reel-1500ms.wav | 1.5 s | Start of `.pulling`. Water lift at progress 0.35, taper by about 0.60. Remaining silence preserves phase timing. |
| reel-1400ms.wav / reel-1600ms.wav | 1.4 / 1.6 s | Endpoint audition alternatives for the random pulling duration. |
| catch-success-0500ms.wav | 0.5 s | `.pulling` crossing progress 0.62, when the happy reveal begins. Fits the remaining 0.532 s even at the shortest current pulling duration. |

Pulling duration is continuous, not limited to the three exported lengths. In the eventual player use the 1.5 s base at playback rate `1.5 / phaseDuration` (about 0.938–1.071), so its internal water cue remains aligned to progress 0.35. Alternatively resample offline for a fixed animation duration. Fire each cue once per transition/progress crossing; never once per render frame. Pause/cancel should stop the voices.

The 0.22 s `.bite` phase is intentionally not given an additional effect in this four-effect draft. `.deposit` lasts 1.2 s; the catch reaches the bucket around progress 0.75. Success here accompanies the visual reveal, not bucket contact. The decorative playback cycle does not award Catalog rewards: do not interpret its sound as confirmation of persisted catch data. If success audio is instead reserved for actual awarded catches, trigger it from a confirmed catch event and suppress the decorative success cue.

Checks: deterministic regeneration, finite samples, no clipping, zero one-shot endpoints and loop seam within normal sample transitions. Perceived realism, comfort and runtime audiovisual sync still require listening and in-app playback. These files have not been auditioned by the agent.
