"""Generate the HUD's independent RGBA ornaments and typography with Pillow."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parents[1] / "assets/ui"
RESAMPLE = Image.Resampling.LANCZOS
HEART = [
    (48, 85), (12, 55), (5, 41), (6, 26), (14, 15), (26, 11),
    (37, 14), (48, 25), (59, 14), (70, 11), (82, 15), (90, 26),
    (91, 41), (84, 55),
]
NAMEPLATES = {
    "beretta_84fs": (["BERETTA 84FS"], ".380 ACP"),
    "pump_shotgun": (["MOSSBERG-STYLE", "PUMP SHOTGUN"], "12 GA"),
    "norinco_akm": (["NORINCO AKM"], "7.62×39 mm"),
    "canik_tp9": (["CANIK TP9"], "9×19 mm"),
    "sw_revolver_engraved": (["S&W MODEL 640"], ".357 MAGNUM"),
    "fairbairn_sykes": (["FAIRBAIRN–SYKES"], "FIGHTING KNIFE"),
    "spetsnaz_sf": (["SPETSNAZ SF"], "COMBAT KNIFE"),
    "akm_bayonet": (["AKM BAYONET"], "CUBAN ISSUE"),
    "cz75_p07": (["CZ 75 P-07"], ""),
}


def heart(state):
    scale = 4
    size = (96 * scale, 96 * scale)
    shape = [(x * scale, y * scale) for x, y in HEART]
    frame = Image.new("RGBA", size)
    draw = ImageDraw.Draw(frame)
    draw.polygon([(x, y + 3 * scale) for x, y in shape], fill="#180d11")
    draw.polygon(shape, fill="#32171d")
    draw.line(shape + shape[:1], fill="#b98560", width=7 * scale, joint="curve")
    draw.line(shape + shape[:1], fill="#4d2630", width=3 * scale, joint="curve")
    mask = Image.new("L", size)
    inner = [((48 + (x - 48) * .86) * scale, (46 + (y - 46) * .85) * scale) for x, y in HEART]
    ImageDraw.Draw(mask).polygon(inner, fill=255)
    enamel = Image.new("RGBA", size)
    paint = ImageDraw.Draw(enamel)
    for y in range(size[1]):
        t = y / size[1]
        empty = (60 - int(35 * t), 34 - int(17 * t), 40 - int(19 * t))
        red = (int(200 - 99 * t), int(70 - 55 * t), int(82 - 52 * t))
        paint.line((0, y, size[0], y), fill=empty)
        filled = size[0] if state == "full" else size[0] // 2 if state == "half" else 0
        if filled:
            paint.line((0, y, filled, y), fill=red)
    paint.arc((12 * scale, 16 * scale, 42 * scale, 45 * scale), 185, 294,
              fill="#ed9f8d" if state != "empty" else "#795057", width=2 * scale)
    if state == "half":
        paint.line((48 * scale, 27 * scale, 48 * scale, 82 * scale),
                   fill="#c66d61", width=scale)
    frame.paste(enamel, mask=mask)
    return frame.resize((96, 96), RESAMPLE)


def ankh():
    size = 192
    image = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(image)
    draw.ellipse((15, 3, 177, 189), fill="#2a191d", outline="#784f45", width=5)
    draw.ellipse((21, 9, 171, 183), outline="#493136", width=4)
    draw.ellipse((65, 24, 127, 103), outline="#9c644d", width=13)
    draw.line((95, 94, 95, 163), fill="#9c644d", width=17)
    draw.line((49, 106, 142, 106), fill="#9c644d", width=15)
    draw.ellipse((67, 26, 124, 98), outline="#e2b987", width=5)
    draw.line((92, 94, 92, 162), fill="#e2b987", width=5)
    draw.line((50, 103, 141, 103), fill="#e2b987", width=5)
    return image.resize((96, 96), RESAMPLE)


def nameplate(lines, subtitle):
    image = Image.new("RGBA", (384, 176))
    draw = ImageDraw.Draw(image)
    title_size = 44 if len(lines) == 1 else 32
    serif = "DejaVuSerif-Bold.ttf"
    title = ImageFont.truetype(serif, title_size)
    while max(title.getlength(line) for line in lines) > 365:
        title_size -= 1
        title = ImageFont.truetype(serif, title_size)
    body = ImageFont.truetype("DejaVuSans-Bold.ttf", 31)
    center_y = 67 if subtitle else 88
    line_height = title_size + 6
    for index, line in enumerate(lines):
        y = center_y + (index - (len(lines) - 1) / 2) * line_height
        draw.text((192, y), line, font=title, anchor="mm", fill="#f5d8af",
                  stroke_width=2, stroke_fill="#26141a")
    if subtitle:
        draw.text((192, 129), subtitle, font=body, anchor="mm", fill="#dea881",
                  stroke_width=2, stroke_fill="#26141a")
    return image


if __name__ == "__main__":
    (OUT / "vitality").mkdir(exist_ok=True)
    (OUT / "nameplates").mkdir(exist_ok=True)
    for state in ("empty", "half", "full"):
        heart(state).save(OUT / "vitality" / f"{state}.png", optimize=True)
    ankh().save(OUT / "vitality" / "ankh.png", optimize=True)
    for ident, (lines, subtitle) in NAMEPLATES.items():
        nameplate(lines, subtitle).save(OUT / "nameplates" / f"{ident}.png", optimize=True)
