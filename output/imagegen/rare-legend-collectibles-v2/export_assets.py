"""Crop, trim, resize and review generated sheets. Requires Pillow."""
import json
import sys
from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent


def refine_crops(records, batches):
    for name, batch in batches.items():
        if not (ROOT / name).exists():
            continue
        image = Image.open(ROOT / name).convert('RGBA')
        width, height = image.size
        alpha = image.getchannel('A').point(lambda value: 255 if value >= 32 else 0).tobytes()
        seen = bytearray(width * height)
        components = []
        for start, value in enumerate(alpha):
            if not value or seen[start]:
                continue
            seen[start] = 1
            queue = deque([start])
            area = 0
            xmin, ymin, xmax, ymax = width, height, 0, 0
            while queue:
                position = queue.popleft()
                y, x = divmod(position, width)
                area += 1
                xmin, ymin, xmax, ymax = min(xmin, x), min(ymin, y), max(xmax, x), max(ymax, y)
                neighbors = []
                if x: neighbors.append(position - 1)
                if x + 1 < width: neighbors.append(position + 1)
                if y: neighbors.append(position - width)
                if y + 1 < height: neighbors.append(position + width)
                for neighbor in neighbors:
                    if alpha[neighbor] and not seen[neighbor]:
                        seen[neighbor] = 1
                        queue.append(neighbor)
            if area > 1000:
                components.append((area, [max(0, xmin - 3), max(0, ymin - 3),
                                          min(width, xmax + 4), min(height, ymax + 4)]))
        count = len(batch['items'])
        components = sorted(components, reverse=True)[:count]
        if len(components) != count:
            raise ValueError(f'Inspect connected objects in {name}: {len(components)} / {count}')
        components.sort(key=lambda part: (part[1][1] + part[1][3]) / 2)
        ordered = []
        for index in range(0, count, batch['cols']):
            ordered.extend(sorted(components[index:index + batch['cols']], key=lambda part: part[1][0]))
        for record, (_, box) in zip([r for r in records if r['sheet'] == name], ordered):
            record.update(crop=box, cropMethod='main connected silhouette, alpha >= 32, 3px padding')


def export():
    records = json.loads((ROOT / 'manifest.json').read_text())
    batches = {b['sheet']: b for b in json.loads((ROOT / 'batches.json').read_text())}
    if '--refine-crops' in sys.argv:
        refine_crops(records, batches)
    validation = []
    for record in records:
        source = ROOT / record['sheet']
        if not source.exists():
            continue
        batch = batches[record['sheet']]
        sheet = Image.open(source).convert('RGBA')
        row, col = record['cell']
        cols, rows = batch['cols'], batch['rows']
        box = record.get('crop', [round(sheet.width * (col - 1) / cols),
                                 round(sheet.height * (row - 1) / rows),
                                 round(sheet.width * col / cols), round(sheet.height * row / rows)])
        cell = sheet.crop(box)
        bounds = cell.getchannel('A').getbbox()
        if bounds is None:
            raise ValueError(f"Empty cell: {record['id']}")
        item = cell.crop(bounds)
        scale = 440 / max(item.size)
        item = item.resize((round(item.width * scale), round(item.height * scale)), Image.Resampling.LANCZOS)
        sprite = Image.new('RGBA', (512, 512))
        sprite.alpha_composite(item, ((512 - item.width) // 2, (512 - item.height) // 2))
        target = ROOT / record['path']
        target.parent.mkdir(exist_ok=True, parents=True)
        sprite.save(target)
        record.update(crop=box, alphaBounds=list(bounds), status='draft-art')
        alpha = sprite.getchannel('A')
        edges = alpha.getbbox()
        assert alpha.getextrema()[0] == 0 and edges
        assert min(edges[0], edges[1], 512 - edges[2], 512 - edges[3]) >= 36
        validation.append(dict(id=record['id'], size=[512, 512], alphaRange=list(alpha.getextrema()), bounds=list(edges)))
    (ROOT / 'manifest.json').write_text(json.dumps(records, indent=2) + '\n')
    (ROOT / 'validation.json').write_text(json.dumps(dict(count=len(validation), assets=validation), indent=2) + '\n')

    for rarity in ('rare', 'legendary'):
        items = [r for r in records if r['rarity'] == rarity and (ROOT / r['path']).exists()]
        for background, foreground, theme in [('#f7f4ed', '#333c44', 'light'), ('#202833', '#edf0f5', 'dark')]:
            rows = max(1, (len(items) + 5) // 6)
            contact = Image.new('RGBA', (1200, rows * 210), background)
            draw = ImageDraw.Draw(contact)
            for index, record in enumerate(items):
                row, col = divmod(index, 6)
                icon = Image.open(ROOT / record['path']).convert('RGBA')
                icon.thumbnail((172, 172), Image.Resampling.LANCZOS)
                contact.alpha_composite(icon, (col * 200 + (200 - icon.width) // 2, row * 210 + (176 - icon.height) // 2 + 4))
                label = record['id'].removeprefix(rarity + '-')
                draw.text((col * 200 + 8, row * 210 + 186), f'{index + 1:02} {label}', fill=foreground)
            contact.convert('RGB').save(ROOT / f'{rarity}-contact-{theme}.jpg', quality=95)
    print(f'Exported and checked {len(validation)} transparent 512px assets.')


if __name__ == '__main__':
    export()
