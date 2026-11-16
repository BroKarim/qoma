"""Package the generated 3×2 sheet without changing its original alpha."""
from pathlib import Path
import json
from PIL import Image

base = Path(__file__).resolve().parent
root = base.parents[2] / 'Qoma/Assets.xcassets/Distraction/CrystalBloomV1'
sheet = Image.open(base / 'sources/crystal-bloom-sheet.png').convert('RGBA')
assert sheet.size == (1536, 1024)
for index in range(6):
    x, y = index % 3 * 512, index // 3 * 512
    cell = sheet.crop((x, y, x + 512, y + 512)).resize((128, 128), Image.Resampling.NEAREST)
    assert cell.getchannel('A').getbbox(), f'Empty cell {index}'
    destination = root / f'CrystalBloom{index + 1}.imageset'
    destination.mkdir(parents=True, exist_ok=True)
    cell.save(destination / 'bloom.png')
    (destination / 'Contents.json').write_text(json.dumps({
        'images': [{'filename': 'bloom.png', 'idiom': 'universal'}],
        'info': {'author': 'xcode', 'version': 1},
    }, indent=2))
