"""Install reviewed generated PNGs at existing asset paths without changing app code."""
import json
import sys
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent

if __name__ == '__main__':
    asset_id, generated_path = sys.argv[1:]
    records = json.loads((ROOT / 'manifest.json').read_text())
    item = next(record for record in records if record['id'] == asset_id)
    generated = Image.open(generated_path).convert('RGBA')
    for name in item['targets']:
        target = Path(name)
        original = Image.open(target).convert('RGBA')
        atlas = 'WatercolorCoveV6' in str(target) or any(
            name in target.stem for name in ('CoveCast', 'CoveCatch', 'CoveDeposit', 'CoveHop', 'CovePoses'))
        if item['transparent'] and not atlas:
            original_bounds = original.getchannel('A').point(lambda a: 255 if a >= 32 else 0).getbbox()
            generated_bounds = generated.getchannel('A').point(lambda a: 255 if a >= 32 else 0).getbbox()
            assert original_bounds and generated_bounds
            artwork = generated.crop(generated_bounds)
            left, top, right, bottom = original_bounds
            scale = min((right - left) / artwork.width, (bottom - top) / artwork.height)
            artwork = artwork.resize((max(1, round(artwork.width * scale)), max(1, round(artwork.height * scale))), Image.Resampling.NEAREST)
            output = Image.new('RGBA', original.size)
            output.alpha_composite(artwork, (left + (right - left - artwork.width) // 2,
                                            top + (bottom - top - artwork.height) // 2))
        else:
            output = generated.resize(original.size, Image.Resampling.NEAREST)
        assert output.size == original.size
        if item['transparent']:
            assert output.getchannel('A').getextrema()[0] == 0
        temporary = target.with_name(target.stem + '.pixel-new.png')
        output.save(temporary)
        temporary.replace(target)
    receipt = dict(id=asset_id, generatedSource=generated_path, targets=item['targets'],
                   status='installed', size=item['size'])
    (ROOT / 'receipts').mkdir(exist_ok=True)
    (ROOT / 'receipts' / (asset_id + '.json')).write_text(json.dumps(receipt, indent=2) + '\n')
