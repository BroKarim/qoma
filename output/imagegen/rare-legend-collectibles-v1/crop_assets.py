"""Crop approved sheet cells only; preserve generated RGBA and alpha."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
jobs = json.loads((ROOT / 'batches.json').read_text())
boxes = [
    [(0, 0, 800, 459), (800, 0, 1536, 459),
     (0, 459, 800, 1024), (800, 459, 1536, 1024)],
    [(0, 0, 975, 887), (975, 0, 1774, 887)],
]
records = []
for job, cells in zip(jobs, boxes):
    sheet = Image.open(ROOT / job['sheet']).convert('RGBA')
    for index, (spec, box) in enumerate(zip(job['items'], cells)):
        item = sheet.crop(box)
        bounds = item.getchannel('A').getbbox()
        if bounds is None:
            raise ValueError(f'Empty cell: {spec["id"]}')
        item = item.crop(bounds)
        scale = 440 / max(item.size)
        item = item.resize((round(item.width*scale), round(item.height*scale)),
                           Image.Resampling.LANCZOS)
        canvas = Image.new('RGBA', (512, 512))
        canvas.alpha_composite(item, ((512-item.width)//2, (512-item.height)//2))
        rarity = 'legendary' if spec['id'].startswith('legendary-') else 'rare'
        target = ROOT / rarity / (spec['id']+'.png')
        target.parent.mkdir(exist_ok=True)
        canvas.save(target)
        records.append(dict(**spec, rarity=rarity, sheet=job['sheet'],
                            cell=[index//job['cols']+1, index%job['cols']+1],
                            crop=list(box), path=f'{rarity}/{spec["id"]}.png',
                            status='draft-art-not-integrated'))
(ROOT / 'manifest.json').write_text(json.dumps(records, indent=2)+'\n')

# Each review row shows the same item over light and dark backgrounds.
preview = Image.new('RGB', (1200, 660), '#FAFBF8')
draw = ImageDraw.Draw(preview)
for index, record in enumerate(records):
    x, y = index%3*400, index//3*330
    draw.rectangle((x+200, y, x+399, y+289), fill='#253E4A')
    sprite = Image.open(ROOT/record['path'])
    sprite.thumbnail((190, 260), Image.Resampling.LANCZOS)
    for offset in [0, 200]:
        preview.paste(sprite, (x+offset+(200-sprite.width)//2,
                               y+(285-sprite.height)//2), sprite)
    draw.text((x+8, y+298), record['id'], fill='#253E4A')
preview.save(ROOT/'contact-sheet-light-dark.jpg')
print(f'Exported {len(records)} transparent 512px assets and review contact sheet.')
