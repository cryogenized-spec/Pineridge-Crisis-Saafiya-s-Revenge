"""Generate the registered Godot sprites and the editable Blender kit geometry."""
import argparse
from dataclasses import replace
import json
from math import cos, pi, sin
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

from mesh import CELL, ROOT, Renderer, atlas, overhead_point
from people import bones, person
from presets import BODY_BASES, GEAR, HERO, LOOKS, POSE_NAMES, Look, pose_hands
from weapons import FOCUS, SIZE, VIEW, casing, weapon

SPRITES = ROOT / "assets/characters/sprite_kit"
PROPS = ROOT / "assets/weapons/overhead"
FX = ROOT / "assets/fx/weapon_art"
DOCS = ROOT / "docs/sprite-kit"
BASE_LOOKS = [
    Look(f"base_{body}", f"{body.title()} body", "neutral", body, "956f5d",
         "shaved", "69616d", "554755", "393339", "knit", "ab8864")
    for body in BODY_BASES
]
PART_SELECTORS = ("Receiver", "Action", "Magazine")
POSE_COLUMNS = len(POSE_NAMES)


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def turn(renderer, model):
    return atlas([renderer.render(model, heading=-i*pi/4) for i in range(8)], (CELL, CELL), 4)


def render_characters(renderer):
    for look in BASE_LOOKS:
        save(turn(renderer, person(look, bare=True)), SPRITES / f"{look.key}_turn.png")
    for look in LOOKS:
        save(turn(renderer, person(look)), SPRITES / f"{look.key}_turn.png")
        for gait in ("walk", "run"):
            frames = [renderer.render(person(look, gait, i/8)) for i in range(8)]
            save(atlas(frames, (CELL, CELL), 4), SPRITES / f"{look.key}_{gait}.png")
        print(f"Rendered {look.label}", flush=True)
    for gait in ("walk", "run"):
        frames = [renderer.render(person(HERO, gait, frame/16, layer="lower")) for frame in range(16)]
        save(atlas(frames, (CELL, CELL), 4), SPRITES / f"saafiya_{gait}_lower.png")
    save(renderer.render(person(HERO, layer="lower")), SPRITES / "saafiya_idle_lower.png")
    save(renderer.render(person(HERO)), SPRITES / "saafiya_unarmed.png")
    save(turn(renderer, person(HERO, bare=True)), SPRITES / "saafiya_base_turn.png")
    save(turn(renderer, person(HERO)), SPRITES / "saafiya_turn.png")

    for layer in ("upper", "arms"):
        frames = [renderer.render(person(HERO, hands=pose_hands(gear, pose), layer=layer))
                  for gear in GEAR for pose in POSE_NAMES]
        save(atlas(frames, (CELL, CELL), POSE_COLUMNS), SPRITES / f"saafiya_{layer}_poses.png")
    print("Rendered Saafiya’s replacement and grip poses", flush=True)


def render_weapons(renderer):
    for gear in GEAR:
        mesh = weapon(gear)
        frames = [renderer.render(mesh, pixels=SIZE, view=VIEW, focus=FOCUS,
                                  selection=lambda part: part.group.split("/")[0] == category)
                  if any(part.group.startswith(category+"/") for part in mesh.parts)
                  else Image.new("RGBA", SIZE)
                  for category in PART_SELECTORS]
        save(atlas(frames, SIZE, 3), PROPS / f"{gear.ident}.png")
    for shape in ("short", "long", "shell"):
        image = renderer.render(casing(shape), pixels=(96, 48), view=1.12, focus=(0,0,.10))
        save(image, FX / f"casing_{shape}.png")
    print("Rendered nine overhead equipment sheets and three ejected shells", flush=True)


def flash(variant):
    """A white core, broken gold lobes and fine sparks in a short axial envelope."""
    px, py = np.meshgrid(np.linspace(-.15, 1.1, 192), np.linspace(-.55, .55, 128))
    angle = np.arctan2(py, px+.025)
    rng = np.random.default_rng(1241+variant)
    shape = np.clip(np.sin(angle*5+variant)*.18 + np.cos(angle*8)*.095 + 1, .68, 1.34)
    distance = np.sqrt((px-.22)**2/.28**2 + py**2/.182**2) / shape
    light = np.maximum(0, 1-distance*.60)**1.3
    head = .71*np.exp(-((px-.084)/.13)**2-(py/.084)**2)
    tongue = np.exp(-((px-.43)/.40)**2-(py/(.048+.13*np.exp(-((px-.17)/.28)**2)))**2)
    side = .32*np.exp(-((px-.26)/.22)**2-((py-(.13 if variant % 2 else -.16))/.19)**2)
    plume = np.maximum(light + head + side, .64*tongue) * np.clip((px+.14)*14, 0, 1)
    texture = np.clip(plume*(.94+rng.random(px.shape)*.12), 0, 1)
    rgb = np.stack((np.full_like(texture, 255), 118+135*texture, 34+216*texture,
                   255*np.clip(texture**.8,0,1)), axis=-1)
    image = Image.fromarray(rgb.astype(np.uint8), "RGBA")
    draw = ImageDraw.Draw(image)
    for i in range(17):
        x = rng.integers(35, 174)
        y = 64+rng.normal(0, (x-10)*.17)
        if 1 < y < 125:
            strength = int(rng.integers(85, 189))
            draw.line((x,y,x+rng.integers(2,8),y+rng.normal(0,2)), fill=(255,185,81,strength),
                      width=int(rng.integers(1,3)))
    return image.resize((128, 80), Image.Resampling.LANCZOS)


def stain(variant, pool):
    size = 192
    rng = np.random.default_rng(519+variant)
    yy, xx = np.mgrid[-1:1:complex(size), -1:1:complex(size)]
    shifted_x = xx + .092*sin(variant)
    shifted_y = yy + .076*cos(variant)
    angles = np.arctan2(shifted_y, shifted_x)
    perimeter = .83 + .11*np.cos(angles*4+variant) + .09*np.sin(angles*7-variant)
    radius = np.sqrt((shifted_x/.91)**2 + (shifted_y/.65)**2)/perimeter
    edge = np.clip((1-radius)*(9 if pool else 4.5),0,1)
    var = .76 + .11*np.sin(xx*13+yy*4+variant) + rng.random(xx.shape)*.16
    alpha = np.clip(edge * var * (223 if pool else 171), 0, 255)
    highlight = np.exp(-((xx+.28)/.51)**2-((yy+.23)/.27)**2)
    shade = 39 if pool else 33
    tone = np.stack((shade+highlight*35+var*16, 7+highlight*6+var*4, 16+highlight*11,
                     alpha), axis=-1)
    return Image.fromarray(tone.astype(np.uint8), "RGBA").resize((128,128), Image.Resampling.LANCZOS)


def render_effects():
    save(atlas([flash(i) for i in range(3)], (128,80), 3), FX / "muzzle.png")
    for pool, filename in [(False,"impact"),(True,"pool")]:
        save(atlas([stain(i,pool) for i in range(4)], (128,128), 4), FX / f"{filename}.png")
    cloud = Image.new("RGBA", (96,96))
    draw = ImageDraw.Draw(cloud)
    for x,y,w,h,a in [(13,24,58,48,78),(31,17,43,62,70),(26,41,51,38,59)]:
        draw.ellipse((x,y,x+w,y+h),fill=(145,137,139,a))
    save(cloud.filter(ImageFilter.GaussianBlur(7)), FX / "smoke.png")


def write_catalogue():
    rows = [
        "# Generated by tools/sprite_kit/generate.py. Authored values live in presets.py.",
        "extends RefCounted",
        "",
        "const CELL := 128",
        "const POSE_COLUMNS := 4",
        'const SPRITES := "res://assets/characters/sprite_kit/"',
        'const PROP_CELL := Vector2(256, 96)',
        "const LIVE_SLOTS := [0, 1, 2]",
        "const CATALOGUE := [",
    ]
    for gear in GEAR:
        points = [overhead_point(pose_hands(gear, pose)[0]) for pose in POSE_NAMES]
        grips = ", ".join(f"Vector2({x:.3f}, {y:.3f})" for x,y in points)
        rows += [
            "\t{",
            f'\t\t"id": "{gear.ident}", "label": "{gear.name}", "action": "{gear.action}",',
            f'\t\t"art": preload("res://assets/weapons/overhead/{gear.ident}.png"),',
            f'\t\t"width": {gear.width}, "tip": {gear.muzzle*gear.width/VIEW:.3f},',
            f'\t\t"port": {gear.port*gear.width/VIEW:.3f}, "case": "{gear.case}",',
            f'\t\t"grips": [{grips}],',
            "\t},",
        ]
    rows += ["]", "const PEOPLE := ["]
    for look in LOOKS + BASE_LOOKS + [HERO]:
        rows.append(f'\t{{"key": "{look.key}", "name": "{look.label}", "body": "{look.base}", "hair": "{look.hair}"}},')
    rows.append('	{"key": "saafiya_base", "name": "Saafiya anatomy base", "body": "balanced", "hair": "neutral"}')
    rows.extend(["]", ""])
    (ROOT / "scripts/sprite_kit_art.gd").write_text("\n".join(rows))


def dump_models(destination):
    models = []
    for look in [*BASE_LOOKS, HERO, *LOOKS]:
        bare = look.key.startswith("base_")
        record = {"name": look.label, "key": look.key, "bones": bones(look),
                  "body": look.base, "parts": [part.serialize() for part in person(look, bare=bare, inner=True).parts]}
        if look == HERO:
            record["poses"] = [
                {"name": gear.name, "frames": [bones(HERO, pose_hands(gear, pose)) for pose in POSE_NAMES]}
                for gear in GEAR
            ]
        models.append(record)
    props = [{"name": gear.name, "key": gear.ident,
              "parts": [part.serialize() for part in weapon(gear).parts]} for gear in GEAR]
    destination.parent.mkdir(parents=True,exist_ok=True)
    destination.write_text(json.dumps({"people":models,"gear":props},separators=(",",":")))


def contact_sheet(renderer):
    image = Image.new("RGB", (1500, 990), "#22202a")
    draw = ImageDraw.Draw(image)
    title = ImageFont.truetype("DejaVuSerif-Bold.ttf", 35)
    label = ImageFont.truetype("DejaVuSans.ttf", 17)
    small = ImageFont.truetype("DejaVuSans.ttf", 13)
    draw.text((37, 31), "Saafiya’s Revenge  /  Sprite kit", font=title, fill="#f0d8bb")
    draw.text((39, 82), "Adult cast presets with interchangeable body, hair and clothing",font=label,fill="#c9aca1")
    for index, look in enumerate(LOOKS):
        x, y = 38+(index%5)*288, 122+(index//5)*300
        draw.rounded_rectangle((x,y,x+268,y+279),radius=8,fill="#302a33",outline="#57414b")
        model = renderer.render(person(look), pixels=(250,225), view=2.16,
                                focus=(0,0,.94), elevation=.60, heading=.38)
        image.paste(model,(x+9,y+2),model)
        draw.text((x+12,y+234),look.label,font=label,fill="#f0d8bb")
        draw.text((x+12,y+256),f"{look.base.title()} body  ·  {look.hair.replace('_',' ').title()}",
                  font=small,fill="#cbb7ad")
    draw.line((38,742,1462,742),fill="#755647",width=1)
    draw.text((39,758),"Overhead equipment",font=label,fill="#f0d8bb")
    for i, gear in enumerate(GEAR):
        x = 39+i*158
        render = renderer.render(weapon(gear),pixels=(143,60),view=VIEW,focus=FOCUS)
        image.paste(render,(x,799),render)
        label_text = gear.name if gear.action != "pump" else "Pump shotgun"
        draw.text((x,872),label_text,font=small,fill="#dcc1ad")
    DOCS.mkdir(parents=True, exist_ok=True)
    image.save(DOCS / "cast-and-weapons.jpg", quality=93, subsampling=0)


def wallpaper(renderer):
    width, height = 1920, 1080
    yy, xx = np.mgrid[:height,:width]
    rng = np.random.default_rng(691)
    aura = np.exp(-((xx-1328)/660)**2-((yy-455)/510)**2)
    grain = rng.normal(0,.85,xx.shape)
    colors = np.stack((16+43*aura+grain,13+20*aura+grain,22+34*aura+grain),axis=-1)
    image = Image.fromarray(np.clip(colors,0,255).astype(np.uint8),"RGB")
    draw = ImageDraw.Draw(image)
    blurred = Image.new("RGBA", image.size)
    halo = ImageDraw.Draw(blurred)
    for inset in [0,12,35,54]:
        halo.ellipse((913+inset,94+inset,1771-inset,952-inset), outline=(160,101,71,125-inset),width=2)
    image.paste(blurred, mask=blurred)
    look = replace(HERO, top="452d40")
    figure = renderer.render(person(look),pixels=(930,1030),view=1.85,
                             focus=(0,0,.925),elevation=.43,heading=.33,supersample=1.15)
    image.paste(figure,(847,23),figure)
    draw = ImageDraw.Draw(image)
    top = ImageFont.truetype("DejaVuSerif-Bold.ttf", 35)
    name = ImageFont.truetype("DejaVuSerif-Bold.ttf", 102)
    small = ImageFont.truetype("DejaVuSans.ttf", 23)
    draw.line((104,333,760,333),fill="#9d6b56",width=2)
    draw.text((99,276),"PINERIDGE CRISIS",font=top,fill="#d0ab8d")
    draw.text((92,375),"SAAFIYA’S",font=name,fill="#f4ddbb",stroke_width=1,stroke_fill="#281821")
    draw.text((92,486),"REVENGE",font=name,fill="#d69a7c",stroke_width=1,stroke_fill="#281821")
    draw.line((104,633,760,633),fill="#9d6b56",width=2)
    draw.text((103,669),"UPPER PINERIDGE",font=small,fill="#c7a194")
    draw.rectangle((32,32,width-33,height-33),outline="#6d4a4c",width=1)
    image.save(DOCS / "wallpaper-1920x1080.jpg",quality=94,subsampling=0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mesh-dump", type=Path, help="Path for editable model geometry used by Blender.")
    parser.add_argument("--part", choices=["all","cast","weapons","previews","models"], default="all")
    args = parser.parse_args()
    if args.part != "models":
        stage = Renderer()
    if args.part in ["all","cast"]:
        render_characters(stage)
    if args.part in ["all","weapons"]:
        render_weapons(stage)
        render_effects()
        write_catalogue()
    if args.part in ["all","previews"]:
        contact_sheet(stage)
        wallpaper(stage)
    if args.mesh_dump:
        dump_models(args.mesh_dump)
