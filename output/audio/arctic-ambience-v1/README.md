# Arctic wind & cold sea — draft 1

Procedurally synthesized nature ambience, without music, voices, animal calls or notification sounds. Soft filtered wind, open-air hiss and slowly changing distant water. This is a sound-design approximation, not a field recording.

- `arctic-wind-sea.m4a`: app delivery candidate, AAC 128 kbps, stereo, 32 kHz, 3 minutes, approximately 3 MB. Native macOS playback; fully offline.
- `arctic-wind-sea-master.wav`: 16-bit PCM master, same sample rate and duration. Approximately 23 MB; keep outside the shipped app unless uncompressed playback is required.
- `generate.py`: deterministic NumPy source; no runtime dependency in the app.

All source layers and modulation are circular over 180 seconds. The PCM seam is checked against ordinary sample transitions, and samples are checked for clipping. AAC introduces encoder priming/padding; preserve its gapless metadata and preload the next buffer or use a short overlapping crossfade in the player. A naive stop/restart player can still introduce a gap. Do not fade each loop to silence.

Suggested initial playback volume: 35%, adjustable independently of fishing effects and completion sound. Tune by ear on headphones and Mac speakers before shipping. Objective checks do not establish perceived realism or comfort, and this draft has not been auditioned by the agent.

No app source or resources were changed.
