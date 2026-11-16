"""Procedural water/rod effects timed to CompanionPlayback and CompanionScene."""
from pathlib import Path
import wave
import numpy as np

ROOT = Path(__file__).resolve().parent
RATE = 48000
rng = np.random.default_rng(121127)


def noise(n, low=150, high=5000):
    f = np.fft.rfftfreq(n, 1 / RATE)
    spectrum = rng.normal(size=len(f)) + 1j * rng.normal(size=len(f))
    spectrum *= (1 - np.exp(-(f / low) ** 4)) * np.exp(-(f / high) ** 2)
    spectrum[0] = 0
    spectrum[-1] = spectrum[-1].real
    x = np.fft.irfft(spectrum, n=n)
    return x / np.std(x)


def burst(x, start, length, level, low=150, high=5000):
    a = round(start * RATE)
    n = min(round(length * RATE), len(x) - a)
    u = np.linspace(0, 1, n)
    x[a:a+n] += level * noise(n, low, high) * np.sin(np.pi * u) ** 2


def drop(x, start, length, level, frequency):
    a = round(start * RATE)
    n = min(round(length * RATE), len(x) - a)
    t = np.arange(n) / RATE
    # Short downward chirp models a water bubble, with no sustained note.
    phase = 2 * np.pi * frequency * (1 - np.exp(-18 * t)) / 18
    x[a:a+n] += level * np.sin(phase) * np.exp(-t * 45) * (1 - np.exp(-t * 900))


def save(name, x, peak_db=-15, loop=False):
    if not loop:
        n = min(240, len(x) // 2)
        x[:n] *= np.linspace(0, 1, n)
        x[-n:] *= np.linspace(1, 0, n)
    x *= 10 ** (peak_db / 20) / max(np.max(np.abs(x)), 1e-9)
    assert np.isfinite(x).all() and np.max(np.abs(x)) < 1
    if loop:
        assert abs(x[0] - x[-1]) < np.percentile(np.abs(np.diff(x)), 99.9)
    else:
        assert abs(x[0]) < 1e-9 and abs(x[-1]) < 1e-9
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(np.round(x * 32767).astype('<i2').tobytes())
    print(f'{name}: {len(x)/RATE:.3f}s, peak {peak_db} dBFS')


x = np.zeros(round(.55 * RATE))
burst(x, .045, .35, .16, 450, 6000)
# Water contact follows splash visibility at casting progress .85.
burst(x, .4675, .0825, .22, 220, 6800)
drop(x, .475, .075, .16, 880)
save('cast-0550ms', x)

n = 8 * RATE
t = np.arange(n) / RATE
x = noise(n, 180, 2600) * (.07 + .03 * np.sin(2*np.pi*t/8))
for start, hz in [(1.1, 720), (3.7, 590), (6.2, 840)]:
    burst(x, start, .18, .05, 450, 4000)
    drop(x, start + .025, .12, .06, hz)
save('waiting-water-loop-8s', x, peak_db=-28, loop=True)

for duration in (1.4, 1.5, 1.6):
    x = np.zeros(round(duration * RATE))
    burst(x, .015 * duration, .55 * duration, .10, 300, 3300)
    for p in (.07, .14, .21, .28, .35, .42):
        burst(x, p * duration, .025, .035, 800, 4800)
    burst(x, .35 * duration, .23 * duration, .16, 200, 5900)
    drop(x, .43 * duration, .12, .10, 780)
    save(f'reel-{round(duration*1000)}ms', x, peak_db=-18)

x = np.zeros(round(.5 * RATE))
burst(x, .01, .16, .08, 450, 5100)
for start, hz, level in [(.025, 1120, .22), (.11, 890, .14), (.205, 680, .09)]:
    drop(x, start, .15, level, hz)
save('catch-success-0500ms', x, peak_db=-15)
