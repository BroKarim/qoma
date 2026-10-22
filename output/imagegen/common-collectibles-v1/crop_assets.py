"""Deterministic crops only; generation/background extraction happens via imagegen.
Run from any directory: python3 crop_assets.py
"""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent


def export(sheet_name, xs, ys, names, folder, rarity):
    sheet = Image.open(ROOT / sheet_name).convert('RGBA')
    records = []
    for index, name in enumerate(names):
        row, col = divmod(index, len(xs) - 1)
        box = [xs[col], ys[row], xs[col + 1], ys[row + 1]]
        item = sheet.crop(box)
        bounds = item.getchannel('A').getbbox()
        if bounds is None:
            raise ValueError(f'Empty cell: {name}')
        item = item.crop(bounds)
        # Match visual footprint; upscaling source fish adds no new painted detail.
        scale = 440 / max(item.size)
        item = item.resize((round(item.width*scale), round(item.height*scale)),
                           Image.Resampling.LANCZOS)
        canvas = Image.new('RGBA', (512, 512))
        canvas.alpha_composite(item, ((512-item.width)//2, (512-item.height)//2))
        target = ROOT / folder / f'{name}.png'
        target.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(target)
        records.append(dict(id=name, rarity=rarity, category=folder,
                            sheet=sheet_name, cell=[row+1, col+1], crop=box,
                            path=f'{folder}/{name}.png', status='draft-art'))
    return records


if __name__ == '__main__':
    manifest = export('fish-sheet-transparent-v1.png',
                      [0, 242, 458, 680, 895, 1114, 1330, 1550, 1774],
                      [0, 230, 450, 648, 887],
                      [f'fish-source-{i:02}' for i in range(1, 33)], 'fish', None)
    common = ROOT / 'common-ocean-finds-sheet-v1.png'
    if common.exists():
        width, height = Image.open(common).size
        manifest += export(common.name,
                           [round(width*i/3) for i in range(4)],
                           [0, round(height/2), height],
                           ['common-sea-pebble', 'common-clam-shell',
                            'common-spiral-shell', 'common-driftwood',
                            'common-shell-shard', 'common-sea-glass'],
                           'ocean-finds', 'common')
    (ROOT / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print(f'Exported {len(manifest)} transparent 512px assets.')
