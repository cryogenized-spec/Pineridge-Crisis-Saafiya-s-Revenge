"""Render non-graphic articulated motion using the original VTK crowd wardrobe.

Each page is a 5×2 grid of 176px cells. The center, camera and world-to-pixel
scale stay fixed. The larger cells provide room around the approved 128px stance.
"""
from math import acos, cos, degrees, pi, sin
from pathlib import Path

import numpy as np
from PIL import Image
import vtk
from vtk.util.numpy_support import vtk_to_numpy

SOURCE = Path(__file__).with_name("render_crowd.py")
crowd = {"__file__": str(SOURCE)}
exec(compile(SOURCE.read_text().split("manifest=[];review=")[0], str(SOURCE), "exec"), crowd)
OUT = Path(__file__).resolve().parents[1] / "assets/characters"
CELL = 176
FRAMES = 10

# Coordinates in the original rig: +X is screen right, −Y forward, +Z up.
# Each key describes pelvis, chest, and paired knee/ankle and elbow/hand joints.
# The neck and shoulders follow the articulated spine between pelvis and chest.
REST = [
    (0, 0, .86), (0, -.015, 1.28),
    (-.105, -.035, .46), (-.108, 0, .10), (.105, -.035, .46), (.108, 0, .10),
    (-.253, -.02, 1.14), (-.261, -.035, .96), (.253, -.02, 1.14), (.261, -.035, .96),
]
MOTIONS = {
    "forward": [
        (.23, [(0,-.025,.73), (0,-.23,1.05),
               (-.12,-.12,.35), (-.12,.05,.10), (.12,-.21,.38), (.13,-.18,.10),
               (-.33,-.20,.92), (-.30,-.44,.82), (.30,-.29,.87), (.32,-.54,.76)]),
        (.58, [(0,.13,.25), (0,-.28,.43),
               (-.15,-.04,.15), (-.16,.39,.11), (.13,-.15,.11), (.19,.39,.10),
               (-.33,-.29,.19), (-.33,-.51,.10), (.27,-.44,.20), (.12,-.65,.10)]),
        (1, [(0,.14,.155), (-.055,-.27,.19),
             (-.165,.22,.10), (-.19,.57,.10), (.18,.21,.10), (.32,.46,.10),
             (-.38,-.26,.094), (-.34,-.50,.08), (.19,-.44,.09), (.40,-.56,.08)]),
    ],
    "backward": [
        (.21, [(0,.05,.79), (.02,.20,1.19),
               (-.14,-.09,.44), (-.18,-.15,.10), (.13,-.15,.44), (.15,-.21,.10),
               (-.38,.04,1.20), (-.49,-.22,1.25), (.32,.12,1.26), (.45,.23,1.43)]),
        (.64, [(0,-.11,.30), (.06,.25,.47),
               (-.18,-.29,.42), (-.24,-.49,.10), (.20,-.27,.49), (.25,-.43,.10),
               (-.36,.23,.24), (-.52,.36,.13), (.32,.33,.24), (.47,.44,.13)]),
        (1, [(0,-.12,.15), (.055,.30,.16),
             (-.17,-.29,.15), (-.28,-.57,.10), (.19,-.26,.21), (.34,-.46,.10),
             (-.35,.19,.09), (-.47,.40,.08), (.32,.38,.09), (.37,.64,.08)]),
    ],
    "side_left": [
        (.25, [(-.13,0,.68), (-.29,.03,1.06),
               (-.25,-.04,.25), (-.24,-.12,.10), (.16,.09,.29), (.31,.25,.11),
               (-.49,.08,.82), (-.58,.06,.54), (.07,-.08,1.13), (.17,-.32,1.20)]),
        (.62, [(-.02,.10,.26), (-.36,.03,.48),
               (-.03,-.11,.16), (.26,-.22,.10), (.26,.27,.21), (.46,.39,.10),
               (-.52,-.11,.22), (-.64,-.22,.10), (-.08,-.18,.38), (-.25,-.33,.30)]),
        (1, [(.105,.09,.15), (-.32,.04,.18),
             (.18,-.18,.11), (.48,-.29,.10), (.30,.24,.17), (.54,.21,.10),
             (-.46,-.18,.09), (-.66,-.19,.08), (-.14,-.17,.15), (-.37,-.32,.08)]),
    ],
    "side_right": [
        (.20, [(.115,-.06,.77), (.26,-.20,1.13),
               (-.17,.04,.42), (-.25,.21,.10), (.175,-.21,.36), (.23,-.26,.10),
               (-.18,-.15,1.03), (-.19,-.37,.99), (.48,-.21,1.16), (.54,-.37,.99)]),
        (.56, [(.095,-.065,.28), (.37,-.17,.55),
               (-.16,.20,.26), (-.40,.35,.10), (.26,-.35,.14), (.17,-.48,.10),
               (.06,-.29,.47), (.27,-.46,.23), (.59,-.08,.25), (.72,-.15,.10)]),
        (1, [(-.075,-.025,.17), (.33,-.14,.22),
             (-.22,.21,.24), (-.46,.27,.10), (-.27,-.21,.11), (-.51,-.28,.10),
             (.14,-.33,.10), (.32,-.39,.085), (.49,.03,.09), (.59,.27,.08)]),
    ],
    "kneeling": [
        (.25, [(0,.03,.68), (-.02,-.18,1.05),
               (-.15,-.24,.30), (-.15,-.27,.10), (.13,-.04,.25), (.16,.27,.10),
               (-.29,-.16,.82), (-.24,-.38,.69), (.26,-.14,.86), (.18,-.29,.70)]),
        (.56, [(0,.07,.49), (-.05,-.10,.89),
               (-.16,-.26,.15), (-.19,.17,.10), (.15,-.18,.12), (.19,.40,.10),
               (-.27,-.22,.62), (-.21,-.35,.48), (.21,-.13,.59), (.15,-.24,.44)]),
        (1, [(-.06,.16,.30), (-.155,-.145,.57),
             (-.19,-.20,.12), (-.17,.24,.10), (.13,-.16,.12), (.15,.45,.10),
             (-.34,-.28,.26), (-.36,-.48,.10), (.09,-.31,.34), (.11,-.43,.17)]),
    ],
    "seated": [
        (.24, [(0,.16,.69), (.07,.16,1.11),
               (-.13,-.13,.38), (-.13,-.20,.10), (.16,-.10,.38), (.22,-.13,.10),
               (-.34,.19,.86), (-.51,.30,.73), (.33,.13,.97), (.32,-.08,1.04)]),
        (.65, [(0,.22,.14), (.055,.23,.55),
               (-.14,-.06,.39), (-.19,-.30,.10), (.20,-.06,.31), (.27,-.30,.10),
               (-.32,.31,.35), (-.43,.39,.10), (.32,.26,.33), (.36,.42,.10)]),
        (1, [(.03,.23,.15), (.13,.12,.55),
             (-.14,-.09,.38), (-.29,-.35,.10), (.21,-.14,.19), (.36,-.50,.10),
             (-.21,.01,.36), (-.13,-.20,.33), (.34,.17,.34), (.37,.34,.09)]),
    ],
    "stumble": [
        (.28, [(-.025,.035,.76), (-.07,.13,1.13),
               (-.14,-.12,.40), (-.13,-.23,.10), (.16,.05,.41), (.17,.21,.10),
               (-.33,.05,1.04), (-.39,-.20,1.02), (.27,.09,1.15), (.35,-.14,1.22)]),
        (.61, [(.015,.02,.79), (.07,-.11,1.19),
               (-.11,-.08,.41), (-.115,-.20,.10), (.13,.035,.43), (.13,.13,.11),
               (-.24,-.15,1.04), (-.19,-.21,.93), (.29,-.10,1.08), (.28,-.24,.92)]),
        (1, REST),
    ],
}


def sample(keys, phase, index):
    # Variation is applied to posture and staggering, while foot contacts and
    # the common root remain fixed. Wider characters keep their wardrobe build.
    before = 0
    previous = np.array(REST)
    for after, pose in keys:
        if phase <= after:
            t = (phase - before) / (after - before)
            t = t*t*(3 - 2*t)
            pose = previous + (np.array(pose) - previous)*t
            accent = sin(phase*pi*.5) * ((index % 4)-1.5)
            pose[1, 0] += .018*accent
            pose[6, 2] += .021*accent
            pose[9, 1] -= .035*accent
            return pose
        before, previous = after, np.array(pose)
    return previous


def unit(vector):
    return vector / np.linalg.norm(vector)


def oriented_ell(center, scale, material, vertical):
    ell = crowd["ell"](center, scale, material)
    axis = np.cross((0, 0, 1), vertical)
    if np.linalg.norm(axis) > 1e-5:
        ell.RotateWXYZ(degrees(acos(np.clip(vertical[2], -1, 1))), *unit(axis))


def draw_pose(index, joints):
    crowd["cursor"] = 0
    _, skin, top, trousers, jacket, longs, hat, hair, build = crowd["ROSTER"][index]
    rgb, tone, ell, seg = (crowd[name] for name in ("rgb", "tone", "ell", "seg"))
    skin, top, trousers = rgb(skin), rgb(top), rgb(trousers)
    sole, shoe, hair_color = rgb("a39d94"), rgb("30343b"), rgb("29232a")
    pelvis, chest, knee_l, ankle_l, knee_r, ankle_r, elbow_l, hand_l, elbow_r, hand_r = joints
    up = unit(chest-pelvis)
    right = unit(np.cross((0, 1, 0), up) + np.array((.0001, 0, 0)))
    forward = unit(np.cross(right, up))
    head_up = unit(up + np.array((0, -.10, .27)))
    for sign, knee, ankle, elbow, hand in [
        (-1, knee_l, ankle_l, elbow_l, hand_l), (1, knee_r, ankle_r, elbow_r, hand_r),
    ]:
        hip = pelvis + sign * .102 * build * right
        seg(hip, knee, .084*build, trousers)
        seg(knee, ankle, .052*build, trousers if longs else skin)
        sandal = not longs and index%3 == 0
        ell(ankle + (0,-.065,-.059), (.064,.127,.019), rgb("504a47") if sandal else sole)
        ell(ankle + (0,-.065,-.028), (.063,.126,.045), skin if sandal else shoe)
        for position in [-.05] if sandal else [-.027,-.05,-.073]:
            ell(ankle + (0,position,.012), (.042,.014,.012), shoe if sandal else tone(shoe,1.8))
        shoulder = chest + .12*up + sign * .204 * build * right
        seg(shoulder, elbow, .069, top if jacket else skin)
        seg(shoulder, (shoulder+elbow)/2, .081, top)
        seg(elbow, hand, .050, top if jacket else skin)
        ell(hand, (.043,.05,.063), skin)
    oriented_ell(pelvis, (.18*build,.116,.14), trousers, up)
    oriented_ell(pelvis + (chest-pelvis)*.36, (.166*build,.104,.22), top, up)
    oriented_ell(chest, (.219*build,.125,.236), top, up)
    oriented_ell(chest + .18*up, (.076,.068,.073), tone(top,.65), up)
    oriented_ell(chest + .21*up, (.060,.055,.084), skin, up)
    if jacket:
        seg(chest + forward*.13 - up*.19, chest + forward*.13 + up*.14, .012, tone(top,.55))
        ell(chest + forward*.137 + up*.073, (.009,.012,.021), rgb("989395"))
    head = chest + .35*up + forward*.025
    oriented_ell(head, (.094,.101,.121), skin, head_up)
    oriented_ell(head - forward*.014 + head_up*.035, (.098,.102,.1), hair_color, head_up)
    for sign in [-1, 1]:
        oriented_ell(head + sign*.093*right - head_up*.008, (.022,.035,.042), skin, head_up)
    ell(head + forward*.10 - head_up*.017, (.023,.026,.030), skin)
    if hair == "curl":
        for strand in range(14):
            angle, radius = strand*2.399, .075*((strand+1)/14)**.5
            ell(head + radius*(cos(angle)*right+sin(angle)*forward) + head_up*.092,
                (.036,.036,.029), tone(hair_color,1.05+(strand%3)*.09))
    if hair == "bun":
        ell(head-forward*.093+head_up*.063, (.068,.069,.066), hair_color)
    if hair == "pony":
        oriented_ell(head-forward*.125-head_up*.025, (.051,.071,.105), hair_color, head_up)
    if hat == "beanie":
        oriented_ell(head+right*.016-forward*.018+head_up*.058, (.108,.113,.080), rgb("42434d"), head_up)
    if hat == "cap":
        oriented_ell(head+head_up*.062, (.107,.111,.080), rgb("565b60"), head_up)
        oriented_ell(head+forward*.125+head_up*.025, (.106,.074,.018), rgb("565b60"), head_up)
    if hat == "band":
        oriented_ell(head+head_up*.025, (.099,.104,.027), rgb("a99570"), head_up)
    for actor in crowd["actors"][crowd["cursor"]:]:
        actor.SetVisibility(False)


def capture():
    window = crowd["win"]
    window.Render()
    pixels = vtk.vtkWindowToImageFilter()
    pixels.SetInput(window)
    pixels.SetInputBufferTypeToRGBA()
    pixels.ReadFrontBufferOff()
    pixels.Update()
    rgba = vtk_to_numpy(pixels.GetOutput().GetPointData().GetScalars())
    return Image.fromarray(rgba.reshape(240, 240, 4)[::-1].copy()).resize((CELL, CELL), Image.Resampling.LANCZOS)


if __name__ == "__main__":
    crowd["cam"].SetParallelScale(.65*CELL/128)
    crowd["win"].SetSize(240, 240)
    reactions = OUT / "reactions"
    reactions.mkdir(exist_ok=True)
    for index in range(12):
        # Use the original approved stance at the entry/exit edge of each strip.
        idle = Image.new("RGBA", (CELL, CELL))
        idle.paste(Image.open(OUT / "crowd" / f"npc_{index:02d}_idle.png"), ((CELL-128)//2, (CELL-128)//2))
        atlas = Image.new("RGBA", (CELL*5, CELL*2*len(MOTIONS)))
        for motion, (name, keys) in enumerate(MOTIONS.items()):
            for frame in range(FRAMES):
                if frame == 0 or (name == "stumble" and frame == FRAMES-1):
                    sprite = idle
                else:
                    draw_pose(index, sample(keys, frame/(FRAMES-1), index))
                    sprite = capture()
                atlas.paste(sprite, ((frame%5)*CELL, (motion*2+frame//5)*CELL))
        atlas.save(reactions / f"npc_{index:02d}.png", optimize=True)
        print(f"Rendered seven reaction strips for crowd preset {index:02d}", flush=True)
