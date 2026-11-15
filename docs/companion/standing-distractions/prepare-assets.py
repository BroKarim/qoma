from pathlib import Path
import json
from PIL import Image

base = Path(__file__).resolve().parent
root = base.parents[2] / 'Qoma/Assets.xcassets/Companion/PixelCoveV2'
for kind in ('bloom', 'lights'):
    source = Image.open(base / f'{kind}.png').convert('RGBA')
    width, height = source.size
    atlas = Image.new('RGBA', (1024, 768))
    for index in range(12):
        column, row = index % 4, index // 4
        cell = source.crop((column * width // 4, row * height // 3,
                            (column + 1) * width // 4, (row + 1) * height // 3))
        alpha = cell.getchannel('A')
        bounds = alpha.point(lambda value: 255 if value >= 128 else 0).getbbox()
        assert bounds and alpha.getextrema()[0] == 0, (kind, index)
        # Register by the opaque right edge and foot baseline, leaving room for the prop on the left.
        cell = cell.crop(bounds)
        scale = 256 / max(width / 4, height / 3)
        cell = cell.resize((round(cell.width * scale), round(cell.height * scale)), Image.Resampling.NEAREST)
        x, y = 240 - cell.width, 236 - cell.height
        assert x >= 0 and y >= 0, (kind, index)
        atlas.paste(cell, (column * 256 + x, row * 256 + y))
    folder = root / f'PixelDistraction{kind.title()}.imageset'
    folder.mkdir(exist_ok=True)
    atlas.save(folder / 'atlas.png')
    (folder / 'Contents.json').write_text(json.dumps({
        'images': [{'filename': 'atlas.png', 'idiom': 'universal'}],
        'info': {'author': 'xcode', 'version': 1},
    }, indent=2) + '\n')
