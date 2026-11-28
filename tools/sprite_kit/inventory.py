"""Render the inventory portrait and outfit icons from Saafiya's campaign model."""
from PIL import Image, ImageDraw
import numpy as np

from mesh import ROOT, Renderer
from people import person
from presets import HERO

DEST = ROOT / "assets/ui/inventory"
OUTFIT = {
    "glasses": ("Sunglasses/",),
    "choker": ("Jewelry/neck",),
    "lace": ("Lace top/", "Corset/"),
    "coat": ("Oversized jacket/",),
    "skirt": ("Pleated skirt/", "Stockings/"),
    "chain": ("Belts/", "Jewelry/pelvis"),
    "boots": ("Platform boots/",),
}


def accessory(key):
    image = Image.new("RGBA", (256, 256))
    d = ImageDraw.Draw(image)
    edge, metal, glow = "#bba18c", "#776b70", "#e6c2a0"
    if key == "phone":
        d.rounded_rectangle((70, 26, 185, 226), radius=17, fill="#262531", outline=edge, width=5)
        d.rounded_rectangle((80, 43, 175, 208), radius=9, fill="#3d5663", outline="#698490", width=3)
        d.polygon([(93, 194), (93, 54), (139, 54)], fill="#627d84")
        d.rounded_rectangle((111, 33, 149, 39), radius=3, fill=metal)
        d.line((110, 214, 147, 214), fill=edge, width=3)
    elif key == "backpack":
        for x in [69, 169]:
            d.rounded_rectangle((x, 45, x + 24, 215), radius=12, fill="#28212c", outline="#5b4d54", width=4)
        d.rounded_rectangle((104, 25, 153, 64), radius=12, outline=edge, width=7)
        d.rounded_rectangle((58, 54, 199, 224), radius=28, fill="#424653", outline="#8e8290", width=5)
        d.rounded_rectangle((69, 115, 189, 209), radius=14, fill="#58616a", outline="#a39891", width=3)
        d.line([(74, 137), (181, 137)], fill="#c9a68b", width=4)
        d.line([(113, 134), (114, 154)], fill="#e6c2a0", width=5)
        d.arc((64,62,196,158), 192, 343, fill="#aba495", width=3)
    elif key == "keys":
        d.ellipse((52, 30, 126, 106), outline=edge, width=9)
        d.rounded_rectangle((93, 73, 173, 146), radius=18, fill="#36313b", outline=edge, width=4)
        d.rounded_rectangle((112, 91, 151, 122), radius=5, fill="#6b595a")
        d.polygon([(112, 143), (153, 143), (153, 193), (145, 193), (145, 214), (129, 226),
                   (113, 210)], fill=metal, outline=glow, width=4)
        d.line([(124, 153), (124, 207)], fill=glow, width=4)
    elif key == "torch":
        d.rounded_rectangle((95, 78, 163, 220), radius=16, fill="#524852", outline=edge, width=4)
        for y in range(128, 207, 12):
            d.line((102, y, 157, y), fill="#25242c", width=3)
        d.rounded_rectangle((79, 46, 179, 105), radius=12, fill=metal, outline=edge, width=4)
        d.ellipse((78, 27, 180, 70), fill="#372e36", outline=glow, width=6)
        d.ellipse((94, 39, 165, 57), fill="#f1dbac")
    else:
        d.rounded_rectangle((84, 53, 172, 218), radius=22, fill="#476964", outline="#9dbbb0", width=5)
        d.rounded_rectangle((105, 27, 151, 61), radius=8, fill="#393c46", outline=edge, width=4)
        d.rounded_rectangle((88, 106, 168, 169), radius=10, fill="#a2b8a0")
        d.line((101, 119, 101, 155), fill="#dfd5b3", width=6)
        d.line((102, 72, 101, 93), fill="#bcd1bb", width=6)
    return image.resize((128, 128), Image.Resampling.LANCZOS)


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    renderer = Renderer()
    model = person(HERO)
    portrait = {"pixels": (346, 652), "view": 1.16, "focus": (0, 0, .99),
                "elevation": .12, "heading": .12}
    hero = renderer.render(model, **portrait)
    hero.save(DEST / "saafiya.png", optimize=True)
    original = np.asarray(hero, dtype=np.int16)
    for key, groups in OUTFIT.items():
        without = renderer.render(model, **portrait,
                                  selection=lambda part: not part.group.startswith(groups))
        difference = np.max(np.abs(original - np.asarray(without, dtype=np.int16)), axis=2)
        alpha = np.minimum(original[:, :, 3], np.clip((difference - 12) * 14, 0, 236))
        shadow = np.zeros(original.shape, dtype=np.uint8)
        shadow[:, :, :3] = (47, 35, 51)
        shadow[:, :, 3] = alpha.astype(np.uint8)
        Image.fromarray(shadow).save(DEST / f"doll_{key}.png", optimize=True)
        view = renderer.render(model, pixels=(416, 640), view=1.25, focus=(0, 0, .97),
                               elevation=.17, heading=.19,
                               selection=lambda part: part.group.startswith(groups))
        cropped = view.crop(view.getbbox())
        cropped.thumbnail((113, 113), Image.Resampling.LANCZOS)
        icon = Image.new("RGBA", (128, 128))
        icon.alpha_composite(cropped, ((128 - cropped.width) // 2, (128 - cropped.height) // 2))
        icon.save(DEST / f"{key}.png", optimize=True)
    for key in ("phone", "backpack", "keys", "torch", "water"):
        accessory(key).save(DEST / f"{key}.png", optimize=True)


if __name__ == "__main__":
    main()
