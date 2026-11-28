"""Bake low stances and game-only gestures for the live campaign."""
from math import cos, pi, sin

import numpy as np

from generate import GEAR, HERO, POSE_NAMES, SPRITES, save
from mesh import BODY_VIEW, CELL, Renderer, atlas, color
from people import joints, person, v
from presets import pose_hands


def crouch(phase, moving, hands=None):
    pose = joints(HERO, "walk" if moving else "idle", phase, hands)
    lower = .35 if not moving else .35 - .018 * (1-cos(4*pi*phase))
    pose["bob"] -= lower
    pose["hips"][2] -= lower
    pose["head"][2] -= lower
    for side, suffix in [(1, "R"), (-1, "L")]:
        stride = sin(2*pi*phase + (pi if side < 0 else 0)) if moving else side*.31
        pose["hip."+suffix] += v(side*.026, .035, -lower)
        pose["ankle."+suffix] += v(side*.065, .04+stride*.05, 0)
        pose["knee."+suffix] += v(side*.061, -.19+stride*.055, -.15)
        pose["shoulder."+suffix] += v(0, 0, -lower)
        for part in ["elbow", "hand"]:
            pose[part+"."+suffix][2] -= lower
    return pose


def low_art(renderer):
    frames = [renderer.render(person(HERO, layer="lower", pose=crouch(i/16,True))) for i in range(16)]
    save(atlas(frames,(CELL,CELL),4), SPRITES/"saafiya_crouch_walk.png")
    save(renderer.render(person(HERO,layer="lower",pose=crouch(0,False))), SPRITES/"saafiya_crouch_idle.png")
    frames = [renderer.render(person(HERO,layer="upper",pose=crouch(0,False,pose_hands(item,pose))))
              for item in GEAR for pose in POSE_NAMES]
    save(atlas(frames,(CELL,CELL),4), SPRITES/"saafiya_crouch_upper.png")


def gesture_art(renderer, name):
    frames = []
    for i in range(12):
        t = i/11
        bend = sin(pi*t)**1.25
        sweep = sin(t*2*pi) * bend
        pose = joints(HERO)
        drop = (.28 if name == "pickup" else .10) * bend
        pose["bob"] -= drop
        pose["head"] += v(.04*sweep, -.14*bend, -drop)
        pose["hips"][2] -= drop
        for side, suffix in [(1,"R"),(-1,"L")]:
            for part in ["hip","shoulder","elbow","hand"]:
                pose[part+"."+suffix][2] -= drop
            pose["knee."+suffix] += v(side*.04*bend, -.10*bend, -drop*.44)
        if name == "swipe":
            pose["elbow.R"] += v(.13*bend, -.15*bend, .18*bend)
            pose["hand.R"] += v(.28*sweep+.11*bend, -.34*bend, .24*bend)
            pose["elbow.L"] += v(-.065*bend, -.09*bend, .13*bend)
        else:
            pose["elbow.R"] += v(-.053*bend, -.26*bend, -.19*bend)
            pose["hand.R"] += v(-.12*bend, -.37*bend, -.35*bend)
        model = person(HERO, pose=pose)
        if name == "swipe":
            h = pose["hand.R"]
            end = h + v(.08*sweep, -.17, .04)
            model.pipe("Glint",[h,end],.027,color("b8abb0"),"Prop","metal")
            model.pipe("Glint edge",[end,end+v(0,-.075,0)],.014,color("ded4cf"),"Prop","metal")
        tile = 176
        frames.append(renderer.render(model,pixels=(tile,tile),view=BODY_VIEW*tile/CELL))
    save(atlas(frames,(tile,tile),4),SPRITES/f"saafiya_{name}.png")


if __name__ == "__main__":
    renderer = Renderer()
    low_art(renderer)
    gesture_art(renderer,"swipe")
    gesture_art(renderer,"pickup")

    from generate import FOCUS, PROPS, SIZE, VIEW, weapon
    rig = weapon(GEAR[2])
    art = [renderer.render(rig,pixels=SIZE,view=VIEW,focus=FOCUS,
                           selection=lambda part: part.group.startswith(category+"/")
                           and "stock" not in part.name.lower())
           for category in ("Receiver","Action","Magazine")]
    save(atlas(art,SIZE,3), PROPS/"campaign_compact_rifle.png")
