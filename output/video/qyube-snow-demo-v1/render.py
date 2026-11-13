"""Run with python3 render.py. Requires Pillow, numpy, ffmpeg and ffprobe."""
from pathlib import Path
import json
import math
import subprocess
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / 'assets/qyube-cap-1.mp4'
OUTPUT = ROOT / 'qyube-snow-demo-v1.mp4'
meta = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_streams', '-of', 'json', str(SOURCE)]))['streams'][0]
SW, SH = int(meta['width']), int(meta['height'])
FPS = 30
COUNT = int(meta['nb_frames'])
assert meta['avg_frame_rate'] == '30/1' and COUNT == 502
bg = Image.open(ROOT / 'assets/blue-sage.png').convert('RGB')
bg = bg.crop((0, 0, bg.width // 2 * 2, bg.height // 2 * 2))
W, H = bg.size
assert W % 2 == 0 and H % 2 == 0
decoder = subprocess.Popen(['ffmpeg', '-v', 'error', '-i', str(SOURCE), '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'], stdout=subprocess.PIPE)
encoder = subprocess.Popen(['ffmpeg', '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}', '-r', str(FPS), '-i', '-', '-i', str(SOURCE), '-map', '0:v:0', '-map', '1:a:0', '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p', '-c:a', 'copy', '-movflags', '+faststart', '-t', str(COUNT / FPS), str(OUTPUT)], stdin=subprocess.PIPE)
crop = (0, 300, SW, 1140)
size = (680, 529)
position = (500, 457)
rng = np.random.default_rng(42)
flakes = [(rng.uniform(420, 1260), rng.uniform(240, 1040), rng.uniform(20, 44), int(rng.choice([2, 2, 3])), int(rng.integers(90, 180))) for _ in range(48)]
mask = None
for frame_no in range(COUNT):
    raw = decoder.stdout.read(SW * SH * 3)
    assert len(raw) == SW * SH * 3, f'Missing source frame {frame_no}'
    source = Image.frombytes('RGB', (SW, SH), raw)
    if mask is None:
        # shortcut: the island silhouette is fixed in this recording; use per-frame matting for moving scenery.
        dark = np.max(np.asarray(source), axis=2) < 22
        boundary = Image.fromarray(np.where(dark, 0, 255).astype('uint8')).copy()
        ImageDraw.floodfill(boundary, (0, 0), 128, thresh=0)
        mask = Image.fromarray(np.where(np.asarray(boundary) == 128, 0, 255).astype('uint8'))
        assert mask.getpixel((0, 0)) == 0 and mask.getpixel((640, 730)) == 255
        mask = mask.filter(ImageFilter.MinFilter(9)).filter(ImageFilter.GaussianBlur(0.5))
        mask.save(ROOT / 'assets/island-mask.png')
        shadow = Image.new('RGBA', (W, H))
        ImageDraw.Draw(shadow).ellipse((542, 934, 1146, 1002), fill=(33, 65, 68, 50))
        shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    t = frame_no / FPS
    fade = min(1, t / 0.45)
    canvas = bg.convert('RGBA')
    island = source.convert('RGBA')
    island.putalpha(mask)
    island = island.crop(crop).resize(size, Image.Resampling.LANCZOS)
    if fade < 1:
        island.putalpha(island.getchannel('A').point(lambda a: round(a * fade)))
    canvas = Image.alpha_composite(canvas, shadow)
    canvas.alpha_composite(island, position)
    fx = Image.new('RGBA', (W, H))
    draw = ImageDraw.Draw(fx)
    # Gentle water ripples stay in the open foreground pool.
    for start, cx, cy in [(2.0, 761, 877), (5.5, 853, 900), (10.0, 738, 899), (13.5, 837, 887)]:
        phase = (t - start) / 1.8
        if 0 <= phase <= 1:
            radius = 5 + 19 * phase
            draw.arc((cx-radius, cy-radius/3, cx+radius, cy+radius/3), 10, 165, fill=(206, 239, 233, round(75 * math.sin(math.pi * phase))), width=1)
    for x, y, speed, s, opacity in flakes:
        fy = 240 + (y - 240 + t * speed) % 800
        fxpos = x + 11 * math.sin(t * 0.65 + y)
        draw.rectangle((round(fxpos), round(fy), round(fxpos)+s-1, round(fy)+s-1), fill=(245, 252, 251, round(opacity * fade)))
    if 8 <= t <= 11:
        # Original two-pose pixel bird sprite; no external assets.
        bird = Image.new('RGBA', (24, 16))
        bd = ImageDraw.Draw(bird)
        wing_up = int((t - 8) * 7) % 2 == 0
        bd.polygon([(4, 9), (0, 5), (2, 11), (9, 12), (17, 11), (19, 7), (15, 5), (11, 8)], fill='#546c79')
        bd.rectangle((8, 9, 16, 11), fill='#dbe8e5')
        bd.polygon([(8, 9), (5, 1 if wing_up else 14), (11, 4 if wing_up else 13), (14, 9)], fill='#728d9a')
        bd.point((17, 6), fill='#253c47')
        bd.rectangle((19, 7, 21, 8), fill='#d2a16b')
        bird = bird.resize((48, 32), Image.Resampling.NEAREST)
        fx.alpha_composite(bird, (round(450 + (t-8) / 3 * 830), round(348 - 30 * math.sin((t-8) / 3 * math.pi))))
        if frame_no == 255:
            bird.save(ROOT / 'assets/bird-sprite.png')
    canvas = Image.alpha_composite(canvas, fx).convert('RGB')
    if frame_no in (90, 270, 450):
        canvas.save(ROOT / f'preview-{frame_no // FPS:02d}s.png')
    encoder.stdin.write(canvas.tobytes())
    if frame_no % 100 == 0:
        print(f'Rendered {frame_no}/{COUNT}', flush=True)
encoder.stdin.close()
assert encoder.wait() == 0 and decoder.wait() == 0
result = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_streams', '-of', 'json', str(OUTPUT)]))['streams'][0]
assert int(result['nb_frames']) == COUNT
assert abs(float(result['duration']) - COUNT / FPS) < 0.001
print(f'Verified {COUNT} frames, {COUNT / FPS:.6f}s: {OUTPUT}')
