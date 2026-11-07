"""Prepare generated atlas alpha and dimensions; preserve the calibrated cell layout."""
from pathlib import Path
import io
import subprocess
from PIL import Image, ImageChops

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
CATALOG = ROOT / 'Qoma/Assets.xcassets/Companion/WatercolorCoveV6'
NAMES = {'catch': 'CompanionCatchFramesV3', 'cast': 'CompanionCastFramesV4',
         'deposit': 'CompanionDepositFramesV4', 'hop': 'CompanionDistractionIceV3',
         'poses': 'CompanionPosesV2'}
for key, old in NAMES.items():
    image = Image.open(HERE / 'sources' / f'{key}.png').convert('RGBA')
    image = image.resize((1024, 768) if key == 'hop' else (1536, 1024), Image.Resampling.LANCZOS)
    image.putalpha(image.getchannel('A').point(
        (lambda a: max(0, min(255, (a - 160) * 255 // 95))) if key == 'hop'
        else (lambda a: 255 if a >= 249 else 0)))
    if key != 'hop':
        # Original silhouette is only a matte: it removes generated glow beyond the registered sprite.
        data = subprocess.check_output(['git', 'show',
            f'72edfad:Qoma/Assets.xcassets/Companion/{old}.imageset/{old}.png'], cwd=ROOT)
        matte = Image.open(io.BytesIO(data)).getchannel('A')
        image.putalpha(ImageChops.multiply(image.getchannel('A'), matte))
    assert image.getpixel((0, 0))[3] == 0
    cols, rows = (3, 2) if key == 'poses' else (4, 3)
    for row in range(rows):
        for col in range(cols):
            box = (col * image.width // cols, row * image.height // rows,
                   (col + 1) * image.width // cols, (row + 1) * image.height // rows)
            assert image.crop(box).getchannel('A').getbbox(), (key, row, col)
    name = f'Cove{key.title()}V6'
    image.save(CATALOG / f'{name}.imageset' / f'{name}.png')
print('Prepared 54 revised drawings; all cells nonempty, corners transparent.')
