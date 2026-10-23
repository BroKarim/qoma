"""Deterministic crop/export and light/dark review sheets; no image generation."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent


def export():
    records = json.loads((ROOT / 'manifest.json').read_text())
    for record in records:
        sheet = Image.open(ROOT / record['sheet']).convert('RGBA')
        row, col = record['cell']
        box = record.get('crop', [
            round(sheet.width * (col - 1) / 3), round(sheet.height * (row - 1) / 2),
            round(sheet.width * col / 3), round(sheet.height * row / 2)])
        cell = sheet.crop(box)
        bounds = cell.getchannel('A').getbbox()
        if bounds is None:
            raise ValueError(f"Empty cell: {record['id']}")
        item = cell.crop(bounds)
        scale = 440 / max(item.size)
        item = item.resize((round(item.width * scale), round(item.height * scale)), Image.Resampling.LANCZOS)
        canvas = Image.new('RGBA', (512, 512))
        canvas.alpha_composite(item, ((512 - item.width) // 2, (512 - item.height) // 2))
        target = ROOT / record['path']
        target.parent.mkdir(exist_ok=True, parents=True)
        canvas.save(target)
        record.update(crop=box, alphaBounds=list(bounds), status='draft-art')
    (ROOT / 'manifest.json').write_text(json.dumps(records, indent=2) + '\n')

    for background, foreground, name in [('#f7f4ed', '#333c44', 'light'), ('#202833', '#e8edf0', 'dark')]:
        contact = Image.new('RGBA', (1200, 1200), background)
        draw = ImageDraw.Draw(contact)
        for index, record in enumerate(records):
            row, col = divmod(index, 6)
            icon = Image.open(ROOT / record['path']).convert('RGBA')
            icon.thumbnail((164, 164), Image.Resampling.LANCZOS)
            contact.alpha_composite(icon, (col * 200 + (200 - icon.width) // 2, row * 200 + 4))
            draw.text((col * 200 + 8, row * 200 + 174), f"{index + 1:02} {record['id'][9:]}", fill=foreground)
        contact.convert('RGB').save(ROOT / f'contact-sheet-{name}.jpg', quality=94)
    print(f'Exported {len(records)} transparent 512px assets and two contact sheets.')


if __name__ == '__main__':
    export()
