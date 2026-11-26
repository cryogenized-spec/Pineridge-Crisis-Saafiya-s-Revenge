"""Check the generated artwork and registered reaction cells."""
from pathlib import Path

from PIL import Image, ImageChops, ImageOps

ASSETS = Path(__file__).resolve().parents[1] / "assets"


def rgba(path, size=None):
    with Image.open(path) as image:
        assert image.mode == "RGBA", path
        if size:
            assert image.size == size, (path, image.size)
        alpha = image.getchannel("A")
        assert alpha.getbbox() and alpha.getextrema() == (0, 255), path
        return image.copy()


vehicles = ASSETS / "environment/vehicles"
for model in ("sedan_silver", "sedan_ochre", "hatchback_russet", "hatchback_sage",
              "utility_ivory", "security", "saafiya_car"):
    east = rgba(vehicles / f"{model}_east.png", (288, 136))
    west = rgba(vehicles / f"{model}_west.png", (288, 136))
    assert ImageChops.difference(ImageOps.mirror(east), west).getbbox(), model

for category, names in {
    "architecture": ("house_terracotta", "house_slate", "house_stone", "barricaded_house",
                     "retail_copper", "retail_teal", "retail_sand"),
    "roadside": ("fence", "fence_vertical", "gate", "gate_open", "wall", "curb", "parking", "bin", "crate",
                 "shrub_0", "shrub_1", "shrub_2"),
}.items():
    for name in names:
        rgba(ASSETS / "environment" / category / f"{name}.png")

with Image.open(ASSETS / "environment/roadside/asphalt_grain.png") as grain:
    assert grain.mode == "RGBA" and grain.size == (192, 192)
    assert 0 < max(grain.getchannel("A").getextrema()) < 64

for name in ("slingshot_icon", "club_icon", "brick"):
    rgba(ASSETS / f"props/rendered/{name}.png", (128, 128))
for name in ("empty", "half", "full", "ankh"):
    rgba(ASSETS / f"ui/vitality/{name}.png", (96, 96))
for name in ("beretta_84fs", "pump_shotgun", "norinco_akm", "canik_tp9", "sw_revolver_engraved",
             "fairbairn_sykes", "spetsnaz_sf", "akm_bayonet", "cz75_p07"):
    rgba(ASSETS / f"ui/nameplates/{name}.png", (384, 176))
overlay = rgba(ASSETS / "ui/saafiya_hud_overlay.png", (2048, 1152))
assert overlay.getpixel((1878, 171))[3] == 0

tile = 176
padding = (tile - 128) // 2
for index in range(12):
    path = ASSETS / f"characters/reactions/npc_{index:02d}.png"
    atlas = rgba(path, (tile * 5, tile * 14)).getchannel("A")
    idle = rgba(ASSETS / f"characters/crowd/npc_{index:02d}_idle.png", (128, 128)).getchannel("A")
    registered_idle = Image.new("L", (tile, tile))
    registered_idle.paste(idle, (padding, padding))
    rests = []
    for motion in range(7):
        for frame in range(10):
            x, y = frame % 5 * tile, (motion * 2 + frame // 5) * tile
            alpha = atlas.crop((x, y, x + tile, y + tile))
            box = alpha.getbbox()
            assert box and 0 < box[0] < box[2] < tile and 0 < box[1] < box[3] < tile, (path, motion, frame, box)
            if frame == 0:
                assert alpha.tobytes() == registered_idle.tobytes(), (path, motion)
            if frame == 9 and motion < 6:
                rests.append(alpha.tobytes())
            if frame == 9 and motion == 6:
                assert alpha.tobytes() == registered_idle.tobytes(), path
    assert len(set(rests)) == 6, path
print("Verified new RGBA art, directional renders and 840 registered reaction cells.")
