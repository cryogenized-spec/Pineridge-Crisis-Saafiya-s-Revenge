"""Render stylized crowd gestures in the registered campaign projection."""
import numpy as np
from PIL import Image

from render_crowd_reactions import CELL, OUT, REST, capture, crowd, draw_pose, sample


def key(elbow, hand, lean=0.):
    pose = np.array(REST)
    pose[1, 1] += lean
    pose[8], pose[9] = elbow, hand
    return pose


SWING = [
    (.26, key((.36, .13, 1.51), (.19, .12, 1.84), .07)),
    (.43, key((.39, -.03, 1.68), (.17, -.12, 1.89), .03)),
    (.55, key((.31, -.37, 1.30), (.20, -.59, 1.22), -.15)),
    (.73, key((.33, -.30, 1.21), (.25, -.50, 1.00), -.11)),
    (1., REST),
]
PROTEST = [
    (.29, key((.37, -.14, 1.37), (.27, -.30, 1.62), -.035)),
    (.57, key((.37, -.14, 1.44), (.35, -.46, 1.49), -.075)),
    (.75, key((.37, -.14, 1.32), (.32, -.30, 1.55))),
    (1., REST),
]


def generate(index, name, keys):
    atlas = Image.new("RGBA", (CELL * 4, CELL * 3))
    for frame in range(12):
        phase = frame / 11
        pose = sample(keys, phase, index)
        draw_pose(index, pose)
        if name == "swing":
            # A bright silhouette ties the small stage prop to the animated wrist.
            hand = pose[9]
            reach = np.array((.024, -.135, -.048)) if .43 < phase < .76 else np.array((.035, .09, .084))
            crowd["seg"](hand + reach*.2, hand + reach, .027, crowd["rgb"]("9e969a"))
            crowd["seg"](hand + reach*.78, hand + reach*1.16, .013, crowd["rgb"]("cfc1af"))
        atlas.paste(capture(), ((frame % 4) * CELL, (frame // 4) * CELL))
    atlas.save(OUT / "reactions" / f"{name}_{index:02d}.png", optimize=True)


if __name__ == "__main__":
    crowd["cam"].SetParallelScale(.65 * CELL / 128)
    crowd["win"].SetSize(240, 240)
    for look in (0, 7):
        generate(look, "swing", SWING)
    generate(9, "protest", PROTEST)
