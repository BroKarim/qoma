"""Extract the approved artwork into small runtime sprites; no illustration is redrawn."""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
CATALOG = ROOT.parents[1] / "Qoma/Assets.xcassets"


def save_asset(name, image, group):
    folder = CATALOG / group / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    image.save(folder / f"{name}.png", optimize=True)
    (folder / "Contents.json").write_text(json.dumps({
        "images": [{"filename": f"{name}.png", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")


def trim(image):
    box = image.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
    assert box, "Artwork must not be empty"
    return image.crop(box)


for source, prefix, maximum in [
    ("ice-flowers-sheet-v1", "DistractionIceFlower", 256),
    ("snow-clumps-sheet-v1", "DistractionSnow", 128),
]:
    sheet = Image.open(ROOT / "effect-assets-v1" / f"{source}.png").convert("RGBA")
    for i in range(6):
        x, y = i % 3 * 512, i // 3 * 512
        sprite = trim(sheet.crop((x, y, x + 512, y + 512)))
        sprite.thumbnail((maximum, maximum), Image.Resampling.LANCZOS)
        save_asset(f"{prefix}{i + 1}", sprite, "Distraction")

for source, name, width in [
    ("wind-swoosh-v1", "DistractionWind", 768),
    ("snowbank-v1", "DistractionSnowbank", 1024),
]:
    sprite = trim(Image.open(ROOT / "effect-assets-v1" / f"{source}.png").convert("RGBA"))
    sprite.thumbnail((width, width), Image.Resampling.LANCZOS)
    save_asset(name, sprite, "Distraction")

# Cut along actual transparent gutters: the generated source cells are not perfectly uniform.
# Register feet per drawing, but keep one scale per action so squash/extension stays painted.
for source, name, columns, rows in [
    ("lights", "CompanionDistractionLightsV3", [0, 409, 776, 1147, 1536], [0, 390, 698, 1024]),
    ("ice", "CompanionDistractionIceV3", [0, 396, 776, 1157, 1536], [0, 352, 675, 1024]),
    ("snow", "CompanionDistractionSnowV3", [0, 402, 769, 1151, 1536], [0, 363, 687, 1024]),
]:
    sheet = Image.open(ROOT / "penguin-drawn-v3" / f"{source}-source.png").convert("RGBA")
    atlas = Image.new("RGBA", (1024, 768))
    registration = []
    scale = None
    for i in range(12):
        column, row = i % 4, i // 4
        cell = sheet.crop((columns[column], rows[row], columns[column + 1], rows[row + 1]))
        box = cell.getchannel("A").point(lambda a: 255 if a > 64 else 0).getbbox()
        assert box
        if scale is None:
            scale = 180 / (box[3] - box[1])
        # Locate the painted feet, excluding the separate stand on the left of light-switch drawings.
        floor = box[3]
        left = round(cell.width * 0.28) if source == "lights" else 0
        weights = []
        for x in range(left, cell.width):
            weight = 0
            for y in range(round(floor - (box[3] - box[1]) * 0.22), floor):
                r, g, b, a = cell.getpixel((x, y))
                if a > 128 and r + g + b < 360:
                    weight += 1
            weights.append((x, weight))
        total = sum(weight for _, weight in weights)
        assert total > 0
        center = sum(x * weight for x, weight in weights) / total
        offset = (round(128 - center * scale), round(236 - floor * scale))
        cell = cell.resize((round(cell.width * scale), round(cell.height * scale)), Image.Resampling.LANCZOS)
        frame = Image.new("RGBA", (256, 256))
        frame.alpha_composite(cell, offset)
        output_box = frame.getchannel("A").point(lambda a: 255 if a > 64 else 0).getbbox()
        # Assert the transformed opaque source also fits, rather than silently accepting clipped output.
        expected = (box[0] * scale + offset[0], box[1] * scale + offset[1],
                    box[2] * scale + offset[0], box[3] * scale + offset[1])
        assert min(expected[:2]) > 0 and max(expected[2:]) < 256, (name, i, expected)
        assert output_box and 234 <= output_box[3] <= 238
        atlas.alpha_composite(frame, (column * 256, row * 256))
        registration.append({"frame": i, "sourceCenterX": round(center, 3), "sourceFloorY": floor,
                             "scale": round(scale, 6), "offset": offset})
    save_asset(name, atlas, "Companion")
    (ROOT / "penguin-drawn-v3" / f"{source}-registration.json").write_text(json.dumps(registration, indent=2) + "\n")

print("Prepared 14 effect sprites and three registered twelve-drawing whole-character atlases.")
