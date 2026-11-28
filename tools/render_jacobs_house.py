"""Render the Jacobs house side-mission props, portraits and character poses."""
from math import cos, pi, sin, tau
from pathlib import Path
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw

from render_environment import Model, Stage
from render_crowd_gestures import CELL, OUT, REST, capture, crowd, draw_pose, key, sample

sys.path.insert(0, str(Path(__file__).with_name("sprite_kit")))
from mesh import ROOT, Renderer
from people import person
from presets import HERO, Look

UI = ROOT / "assets/ui/jacobs_house"


def tree():
    model = Model()
    rng = np.random.default_rng(602)
    model.shadows += [(2.9, 2.8, 1.25, 67), (1.0, .83, .06, 72)]
    model.tube((0, 0, .03), (.09, .07, 1.58), .135, "55463a")
    for limb in range(7):
        angle = limb * tau / 7 + .13
        x, y = cos(angle), sin(angle)
        top = (x*.85, y*.74, 1.77 + rng.uniform(-.09, .33))
        model.tube((.05, .06, 1.04), top, .063, "675549")
        model.tube((.02, -.01, .11), (x*.33, y*.36, .035), .046, "5d5041")
        model.ellipsoid(top, (.60, .58, .38), ["436650", "547957", "53694b"][limb % 3])
        for leaf in range(27):
            spin = leaf * 2.399
            spread = rng.uniform(.14, .56)
            center = (top[0] + cos(spin)*spread, top[1] + sin(spin)*spread,
                      top[2] + rng.uniform(.07, .37))
            model.ellipsoid(center, (rng.uniform(.13, .27), .18, .14),
                            ["3d624d", "5d7a52", "648353", "4c7354"][leaf % 4])
    model.ellipsoid((.05, .04, 2.28), (.73, .68, .46), "62845b")
    return model


def house():
    model = Model()
    model.shadows += [(7.8, 4.5, .07, 112), (7.3, 4.2, 2.35, 71)]
    model.box((0, 0, .12), (7.6, 4.35, .24), "77746d")
    model.box((0, 0, 1.18), (7.45, 4.18, 2.20), "bca88e")
    model.box((0, 0, 2.37), (7.51, 4.20, .18), "9b8b7b")
    model.box((0, .09, 3.26), (7.2, 3.88, 1.70), "ddc8a6")
    for x in [-2.7, -.98, 1.02, 2.68]:
        for z, y, height in [(1.53, -2.13, .82), (3.27, -1.88, .80)]:
            model.box((x, y, z), (1.10, .13, height), "756b61")
            model.box((x, y-.07, z), (.81, .07, height-.19), "526868", .24)
            model.box((x, y-.11, z), (.047, .03, height-.20), "c4aea0")
            model.box((x, y-.11, z-height*.45), (1.16, .24, .085), "c6b3a1")
    model.box((.55, -2.12, .93), (.84, .12, 1.54), "795849")
    model.box((.56, -2.25, .19), (1.61, .35, .15), "968b7b")
    for side in [-1, 1]:
        y = .08 + side * 2.12
        model.quad([(-3.84, y, 4.03), (3.84, y, 4.03), (3.84, .08, 5.19), (-3.84, .08, 5.19)],
                   "765453" if side > 0 else "93695e")
        for row in range(9):
            start = row / 9
            end = (row + .96) / 9
            lo, hi = y + (.08 - y) * start, y + (.08 - y) * end
            z0, z1 = 4.05 + 1.16*start, 4.05 + 1.16*end
            for tile in range(25):
                x = -3.8 + tile*.305
                color = ["946e62", "8b625a", "895f58", "a17366", "7d5d58"][(row*3+tile*2) % 5]
                model.quad([(x, lo, z0), (x+.297, lo, z0+.012), (x+.297, hi, z1), (x, hi, z1)], color)
    for x in [-3.69, 3.69]:
        model.mesh([(x, -2.04, 4.0), (x, 2.2, 4.0), (x, .08, 5.17)], [(0, 1, 2)], "a89180")
    model.tube((-3.86, .08, 5.19), (3.86, .08, 5.19), .072, "735856")
    model.box((2.4, .50, 5.02), (.47, .56, .89), "8d635b")
    model.box((2.4, .50, 5.48), (.60, .70, .14), "b19888")
    return model


def portrait(renderer, key_name, look, heading):
    image = renderer.render(person(look), pixels=(360, 400), view=.61, focus=(0, 0, 1.50),
                            elevation=.17, heading=heading, supersample=1.4)
    image.save(UI / f"{key_name}.png", optimize=True)


def pose_atlas(name, frames):
    sheet = Image.new("RGBA", (CELL * 4, CELL * 3))
    crowd["cam"].SetParallelScale(.65 * CELL / 128)
    crowd["win"].SetSize(240, 240)
    for frame, pose in enumerate(frames):
        draw_pose(7, pose)
        sheet.paste(capture(), ((frame % 4) * CELL, (frame // 4) * CELL))
    sheet.save(OUT / "reactions" / f"{name}_07.png", optimize=True)


def gear_icon():
    image = Image.new("RGBA", (128, 128))
    ink = ImageDraw.Draw(image)
    ink.polygon([(48, 19), (82, 22), (80, 90), (75, 106), (42, 103), (38, 91)],
                fill="#464651", outline="#d5baa1", width=3)
    ink.rounded_rectangle((43, 96, 81, 109), radius=4, fill="#78727b", outline="#bca49a", width=2)
    ink.line((46, 29, 43, 91), fill="#a8a1a4", width=3)
    for y in [43, 56, 70, 83]:
        ink.ellipse((63, y, 68, y+5), fill="#22212a")
    image.save(ROOT / "assets/ui/inventory/magazine.png", optimize=True)


def knock():
    rate = 22050
    time = np.arange(round(rate*.55)) / rate
    signal = np.zeros(time.shape)
    rng = np.random.default_rng(223)
    for start, gain in [(0.015, .30), (.209, .26)]:
        age = time - start
        decay = np.exp(-np.maximum(age, 0) * 44) * (age >= 0)
        signal += gain * decay * (sinusoidal(age, 146) + .43*sinusoidal(age, 227)
                                  + .31*rng.uniform(-1, 1, len(time)))
    with wave.open(str(ROOT / "assets/audio/jacobs_door_knock.wav"), "wb") as record:
        record.setparams((1, 2, rate, 0, "NONE", "not compressed"))
        record.writeframes(np.int16(signal*32767).tobytes())


def sinusoidal(time, frequency):
    return np.sin(time * tau * frequency)


if __name__ == "__main__":
    UI.mkdir(parents=True, exist_ok=True)
    environment = Stage()
    environment.render(tree(), (278, 256), 3.78, "environment/roadside/jacobs_tree.png", focal_z=1.30)
    environment.render(house(), (480, 300), 8.9, "environment/architecture/jacobs_house.png", focal_z=2.38)
    renderer = Renderer()
    portrait(renderer, "saafiya", HERO, .27)
    portrait(renderer, "jacobs", Look("jacobs", "Mr. Jacobs", "male", "broad", "965b3c",
             "fade", "d6c291", "646575", "403938", "knit", "e3d0a3"), -.24)
    portrait(renderer, "looter", Look("looter", "Looter", "male", "slim", "c48b65",
             "coils", "7b5270", "45424c", "292831", "windbreaker", "bda6a2"), -.26)
    tap = key((.30, -.25, 1.37), (.16, -.43, 1.51), -.08)
    hold = key((.31, -.19, 1.39), (.15, -.28, 1.50), -.035)
    knocking = [(.17, hold), (.25, tap), (.42, hold), (.49, tap), (.65, hold), (1.0, REST)]
    pose_atlas("knock", [sample(knocking, i/11, 7) for i in range(12)])
    up = np.array(REST)
    up[6] = (-.35, -.03, 1.51)
    up[7] = (-.33, -.10, 1.76)
    up[8] = (.35, -.03, 1.51)
    up[9] = (.33, -.10, 1.76)
    pose_atlas("hands_up", [sample([(.64, up), (1., up)], i/11, 7) for i in range(12)])
    gear_icon()
    knock()
