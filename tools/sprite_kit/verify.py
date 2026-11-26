"""Verify the shipped sprite cells and independent equipment layers."""
from pathlib import Path

from PIL import Image

from presets import BODY_BASES, GEAR, LOOKS, POSE_NAMES

ROOT = Path(__file__).resolve().parents[2]
ACTORS = ROOT / "assets/characters/sprite_kit"
WEAPONS = ROOT / "assets/weapons/overhead"
FX = ROOT / "assets/fx/weapon_art"


def rgba(path, size):
    with Image.open(path) as image:
        assert image.mode == "RGBA" and image.size == size, (path, image.mode, image.size)
        return image.copy()


def cells(image, width, height):
    for y in range(0, image.height, height):
        for x in range(0, image.width, width):
            yield image.crop((x, y, x + width, y + height))


def verified_atlas(path, size):
    images = list(cells(rgba(path, size), 128, 128))
    for index, frame in enumerate(images):
        box = frame.getchannel("A").getbbox()
        assert box and 0 < box[0] < box[2] < 128 and 0 < box[1] < box[3] < 128, (path, index, box)
    return images


for body in BODY_BASES:
    verified_atlas(ACTORS / f"base_{body}_turn.png", (512, 256))
for look in LOOKS:
    for state in ["turn","walk","run"]:
        frames = verified_atlas(ACTORS / f"{look.key}_{state}.png", (512, 256))
        assert len({frame.tobytes() for frame in frames}) == 8, (look, state)

for state in ["walk","run"]:
    verified_atlas(ACTORS / f"saafiya_{state}_lower.png", (512, 512))
for state in ["idle_lower","unarmed"]:
    verified_atlas(ACTORS / f"saafiya_{state}.png", (128, 128))
for state in ["turn","base_turn"]:
    verified_atlas(ACTORS / f"saafiya_{state}.png", (512, 256))
for layer in ["upper","arms"]:
    frames = verified_atlas(ACTORS / f"saafiya_{layer}_poses.png", (512, 128*len(GEAR)))
    for start in range(0, len(frames), len(POSE_NAMES)):
        assert len({frame.tobytes() for frame in frames[start:start+len(POSE_NAMES)]}) == 4
    assert len({frame.tobytes() for frame in frames[::len(POSE_NAMES)]}) == len(GEAR)

for gear in GEAR:
    receiver, action, magazine = list(cells(rgba(WEAPONS / f"{gear.ident}.png", (768,96)), 256,96))
    assert receiver.getchannel("A").getbbox(), gear
    assert bool(action.getchannel("A").getbbox()) == (gear.action != "blade"), gear
    assert bool(magazine.getchannel("A").getbbox()) == (gear.action in ["slide","bolt"]), gear
for shape in ["short","long","shell"]:
    assert rgba(FX / f"casing_{shape}.png", (96,48)).getchannel("A").getbbox()
for name, size in [("muzzle",(384,80)),("smoke",(96,96)),("impact",(512,128)),("pool",(512,128))]:
    assert rgba(FX / f"{name}.png", size).getchannel("A").getbbox()

print("Verified three body templates, ten animated cast presets, nine Saafiya poses, equipment layers and FX.")
