"""Create a deterministic, circular Arctic wind and distant water sound bed."""
from pathlib import Path
import wave
import numpy as np

ROOT = Path(__file__).resolve().parent
RATE = 32000
DURATION = 180
N = RATE * DURATION
rng = np.random.default_rng(121126)
t = np.arange(N, dtype=np.float64) / RATE
freq = np.fft.rfftfreq(N, 1 / RATE)


def noise(low, high, slope):
    spectrum = rng.standard_normal(len(freq)) + 1j * rng.standard_normal(len(freq))
    spectrum *= (np.maximum(freq, 1) ** (-slope / 2)
                 * (1 - np.exp(-(freq / low) ** 4))
                 * np.exp(-(freq / high) ** 2))
    spectrum[0] = 0
    spectrum[-1] = spectrum[-1].real
    samples = np.fft.irfft(spectrum, n=N)
    return samples / np.std(samples)


def envelope(harmonics, depth):
    result = np.zeros(N)
    for harmonic in harmonics:
        result += np.sin(2 * np.pi * harmonic * t / DURATION + rng.uniform(0, 2 * np.pi))
    return 1 + depth * result / len(harmonics)


# Every modulation and noise layer is periodic over the complete buffer.
wind = noise(65, 2300, 1.4) * envelope([2, 3, 7, 11], .48)
air = noise(450, 6500, .9) * envelope([3, 8, 13], .28)
water_envelope = np.maximum(0, envelope([17, 23, 31, 37], 1.8) - .35) ** 2
water = noise(130, 4200, .75) * water_envelope
shore = noise(500, 7500, .35) * envelope([29, 41, 53], .65)
center = .61 * wind + .11 * air + .19 * water + .035 * shore
side = noise(110, 3800, 1.05) * envelope([4, 9, 14], .3) * .15
audio = np.column_stack((center + side, center - side))
audio *= 10 ** (-25 / 20) / np.sqrt(np.mean(audio ** 2))
assert np.max(np.abs(audio)) < .8, "Unexpected peak; avoid clipping"
seam = np.abs(audio[0] - audio[-1]).max()
steps = np.percentile(np.abs(np.diff(audio, axis=0)), 99.9)
assert seam < steps, "Loop seam exceeds ordinary sample transitions"
pcm = np.round(audio * 32767).astype('<i2')
with wave.open(str(ROOT / 'arctic-wind-sea-master.wav'), 'wb') as wav:
    wav.setnchannels(2)
    wav.setsampwidth(2)
    wav.setframerate(RATE)
    wav.writeframes(pcm.tobytes())
print(f'{DURATION}s stereo, peak {20*np.log10(np.max(np.abs(audio))):.1f} dBFS, '
      f'RMS -25 dBFS, seam {seam:.6f}, ordinary transition p99.9 {steps:.6f}')
