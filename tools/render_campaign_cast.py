"""Render three bespoke minibus passengers and live crowd action strips."""
from math import cos, pi, sin

import numpy as np
from PIL import Image

from render_crowd_gestures import key
from render_crowd_reactions import (CELL, MOTIONS, OUT, REST, capture, crowd, draw_pose,
                                    sample, unit)

CREW = [
    ("Bucket cap / brown leather", "9d6245", "614644", "465462", 1, 1, "none", "short", 1.14),
    ("Wine jacket / heavy boots", "b38264", "803e4b", "4e5369", 1, 1, "beanie", "short", 1.19),
    ("Face wrap / charcoal leather", "795844", "383c52", "595263", 1, 1, "none", "short", 1.23),
]


def draw(index, joints, prop=""):
    draw_pose(index, joints)
    rgb, ell, seg = (crowd[name] for name in ("rgb", "ell", "seg"))
    if index >= 12:
        pelvis, chest = joints[:2]
        up = unit(chest-pelvis)
        head = chest + .35*up + np.array((0,-.025,0))
        if index == 12:
            ell(head+(.005,0,.089),(.145,.145,.033),rgb("64655c"))
            ell(head+(.007,.008,.137),(.095,.103,.054),rgb("77796a"))
        elif index == 14:
            ell(head+(0,.013,.05),(.105,.105,.119),rgb("252832"))
            ell(head+(0,-.065,-.020),(.094,.058,.081),rgb("292d3a"))
            ell(head+(0,-.107,.015),(.069,.020,.026),rgb("765545"))
            for hand in joints[[7,9]]:
                ell(hand,(.050,.055,.068),rgb("2c2d38"))
    if prop == "cudgel":
        h = joints[9]
        seg(h+(0,.047,.023),h+(.13,-.23,.072),.025,rgb("76553f"))
        seg(h+(.13,-.23,.072),h+(.159,-.27,.072),.033,rgb("8c694a"))
    elif prop == "sling":
        midpoint = joints[7]*.50+joints[9]*.50
        base = midpoint+(0,-.022,.001)
        tip = base+(0,-.165,.045)
        seg(base,tip,.025,rgb("71513e"))
        for sign in [-1,1]:
            seg(tip,tip+(.079*sign,-.063,.016),.018,rgb("9d7e56"))
    elif prop == "blade":
        h = joints[9]
        seg(h,h+(.13,-.19,.073),.028,rgb("b2aab2"))


def render_strip(index, name, pose, prop):
    sheet = Image.new("RGBA",(CELL*4,CELL*3))
    for i in range(12):
        draw(index,pose(i/11),prop)
        sheet.paste(capture(),((i%4)*CELL,(i//4)*CELL))
    sheet.save(OUT/"reactions"/f"{name}_{index:02d}.png",optimize=True)


def cuff_pose(t):
    return sample([(.35,key((.41,-.093,1.36),(.45,.12,1.53),.05)),
                   (.55,key((.34,-.22,1.29),(.15,-.58,1.38),-.16)),
                   (.75,key((.30,-.18,1.17),(.17,-.46,1.16),-.10)),(1,REST)],t,4)


def sling_pose(t):
    pose = np.array(REST)
    raise_up = .53 + sin(pi*t)*.46
    pose[6] = (-.25,-.10,1.19)
    pose[7] = (-.11,-.19-raise_up*.22,1.21+raise_up*.09)
    pose[8] = (.31,-.12,1.18)
    pose[9] = (.14,-.21-raise_up*.22,1.22+raise_up*.10)
    return pose


def gait(t, distance):
    pose = np.array(REST)
    for side, signed in enumerate([-1,1]):
        wave = sin(t*2*pi+side*pi)
        height = max(0.,cos(t*2*pi+side*pi))
        pose[2+side*2] += (signed*.014,wave*distance*.54,height*distance*.20)
        pose[3+side*2] += (signed*.016,wave*distance,height*distance*.34)
        pose[6+side*2] += (signed*.022,-wave*distance*.42,.03)
        pose[7+side*2] += (signed*.022,-wave*distance*.66,.05)
    return pose


def member(index):
    for mode, distance in [("idle",0),("walk",.17),("run",.28)]:
        count = 1 if mode == "idle" else 8
        canvas = Image.new("RGBA",(128,128) if count == 1 else (512,256))
        for i in range(count):
            draw(index, np.array(REST) if count == 1 else gait(i/count,distance))
            crop = (CELL-128)//2
            image = capture().crop((crop,crop,crop+128,crop+128))
            canvas.paste(image,((i%4)*128,(i//4)*128))
        canvas.save(OUT/"crowd"/f"npc_{index:02d}_{mode}.png",optimize=True)
    atlas = Image.new("RGBA",(CELL*5,CELL*2*len(MOTIONS)))
    for motion, keys in enumerate(MOTIONS.values()):
        for i in range(10):
            draw(index,sample(keys,i/9,index))
            atlas.paste(capture(),((i%5)*CELL,(motion*2+i//5)*CELL))
    atlas.save(OUT/"reactions"/f"npc_{index:02d}.png",optimize=True)


if __name__ == "__main__":
    crowd["ROSTER"].extend(CREW)
    crowd["cam"].SetParallelScale(.65*CELL/128)
    crowd["win"].SetSize(240,240)
    for index in (3,4,5):
        render_strip(index,"cudgel",cuff_pose,"cudgel")
    for index in (5,6,10):
        render_strip(index,"slingshot",sling_pose,"sling")
    for index in (12,13,14):
        member(index)
        if index != 14:
            render_strip(index,"swipe",cuff_pose,"blade")
