"""Build articulated adult characters from interchangeable body, hair and garment parts."""
from math import cos, pi, sin
import random

import numpy as np

from mesh import Mesh, color
from presets import BODY_BASES
import saafiya as costume


def v(x, y, z):
    return np.array((x, y, z), dtype=float)


def joints(look, gait="idle", phase=0., hands=None):
    height, breadth, hip = BODY_BASES[look.base]
    shoulder = (.195 if look.sex == "female" else .222) * breadth
    waist = (.137 if look.sex == "female" else .158) * breadth
    pelvis = (.171 if look.sex == "female" else .158) * hip
    stride = .30 if gait == "run" else .185 if gait == "walk" else 0.
    lift = .17 if gait == "run" else .065 if gait == "walk" else 0.
    bob = (1-cos(phase*4*pi))*(.015 if gait == "run" else .007) if stride else 0.
    lean = .08 if gait == "run" else .032 if hands is not None else .012
    locations = {
        "height": height, "width": breadth, "hip": hip, "waist": waist,
        "pelvis_width": pelvis, "shoulder_width": shoulder, "bob": bob, "lean": lean,
        "head": v(0,-.036-lean,1.65*height + bob),
        "hips": v(0,0,.875*height+bob),
    }
    for side, suffix in [(1,"R"), (-1,"L")]:
        beat = phase*2*pi + (pi if side < 0 else 0)
        step = stride*sin(beat)
        raise_to = lift*max(0., cos(beat))
        hip_point = v(side*pelvis*.57, 0, .885*height+bob)
        knee = v(side*pelvis*.62, .39*step-.052, .48*height+raise_to*.45)
        ankle = v(side*pelvis*.66, step, .105*height+raise_to)
        shoulder_point = v(side*shoulder, -lean-.010, 1.424*height+bob)
        if hands is None:
            elbow = v(side*(shoulder+.036), -.035-.48*step, 1.168*height+bob)
            hand = v(side*(shoulder+.041), -.081-.64*step, .977*height+bob)
        else:
            hand = np.array(hands[0 if side > 0 else 1]) * v(breadth, 1, height)
            elbow = v(side*(shoulder+.029), (hand[1]-lean)*.37, shoulder_point[2]-.16)
        for name, pt in [("hip",hip_point), ("knee",knee), ("ankle",ankle),
                         ("shoulder",shoulder_point), ("elbow",elbow), ("hand",hand)]:
            locations[name+"."+suffix] = pt
    return locations


def torso_slices(look, pose):
    height, bob, lean = (pose[key] for key in ("height","bob","lean"))
    waist, shoulder, hip = (pose[key] for key in ("waist","shoulder_width","pelvis_width"))
    volumes = [
        (.84, 0, hip*.94, .10), (.91, 0, hip, .107), (.99, -.009, waist*1.08, .104),
        (1.10, -.012, waist, .097), (1.22, -.013, (waist+shoulder)*.51, .105),
        (1.33, -.018, shoulder*.99, .116), (1.425, -.024, shoulder, .101),
        (1.467, -.022, shoulder*.79, .083), (1.514, -.025, .063, .061),
    ]
    return [(0, y-lean*(z-.84)/.65, z*height+bob, rx, ry) for z,y,rx,ry in volumes]


def make_head(mesh, look, pose, bare):
    head = pose["head"]
    skin = color(look.skin)
    head_group = "Body/head"
    mesh.ellipsoid("Head", head, (.107,.107,.145), skin, head_group, "skin", 22)
    mesh.ellipsoid("Jaw", head + v(0,-.019,-.067), (.084,.078,.070), skin, head_group, "skin", 18)
    mesh.ellipsoid("Nose", head + v(0,-.105,-.014), (.017,.026,.028),
                   color(look.skin, 1.05), head_group, "skin")
    mesh.ellipsoid("Lips", head+v(0,-.098,-.069), (.031,.012,.006),
                   color(look.skin,.79), head_group, "skin")
    for side in [-1, 1]:
        mesh.ellipsoid("Ear", head + v(side*.106,.003,-.007), (.022,.027,.040),
                       color(look.skin,.92), head_group, "skin")
        mesh.pipe("Brow", [head+v(side*.020,-.096,.032),head+v(side*.065,-.082,.034)],
                  .0055, "392b30", head_group, "hair")
        mesh.ellipsoid("Eye", head + v(side*.043,-.097,.009), (.027,.009,.007),
                       "2b2329", head_group, "skin")
    if bare:
        return
    if look.detail == "beard":
        mesh.ellipsoid("Short beard", head + v(0,-.056,-.085), (.083,.065,.050),
                       "423137", "Accessories/head", "hair")
    make_hair(mesh, look, head)
    if look.detail == "hoops":
        for side in [-1,1]:
            center = head + v(side*.120,-.001,-.070)
            ring = [center+v(0,.034*cos(t*2*pi/18),.044*sin(t*2*pi/18)) for t in range(19)]
            mesh.pipe("Bronze hoop", ring, .0055, "d0a776", "Accessories/head", "metal")
    if look.detail == "glasses":
        for side in [-1,1]:
            p = head + v(side*.051,-.108,.012)
            mesh.ellipsoid("Smoked lens", p, (.042,.014,.025), "575760", "Accessories/head", "glass")
            mesh.pipe("Temple arm", [p+v(side*.034,0,0), p+v(side*.052,.079,-.001)], .005,
                      "9a8774", "Accessories/head", "metal")


def make_hair(mesh, look, head):
    style = look.hair
    group = "Hair/head"
    deep = "382d30" if style == "waves" else "2b2529"
    if style == "shaved":
        mesh.ellipsoid("Close shave", head+v(0,.011,.063), (.103,.095,.082),
                       color(look.skin,.63), group, "hair")
        return
    base_radii = (.112,.112,.106) if style == "coils" else (.106,.107,.092)
    mesh.ellipsoid("Scalp silhouette", head+v(0,.026,.067), base_radii, deep, group, "hair", 22)
    rng = random.Random(style)
    if style in ["coils","puff","twists","waves"]:
        count = 29
        top_tone = "514038" if style == "waves" else "393032"
        for index in range(count):
            angle = index * 2.399
            radius = .104*((index+1)/count)**.5
            p = head+v(cos(angle)*radius, sin(angle)*radius+.025,
                       .16-.083*((index+1)/count)+rng.uniform(-.009,.011))
            size = rng.uniform(.024,.037)
            axes = (size, size*.96, size*(1.18 if style == "twists" else .78))
            mesh.ellipsoid("Curl", p, axes, color(top_tone,rng.uniform(.76,1.14)), group, "hair", 12)
    if style == "fade":
        for row in range(6):
            y = -.065+row*.024
            mesh.pipe("Fade texture", [head+v(-.073,y,.119),head+v(0,y,.144),head+v(.074,y,.124)],
                      .010, color(deep,1.17), group, "hair")
    if style in ["puff","bun","ponytail","braids"]:
        if style == "puff":
            center = head+v(0,.104,.117)
            mesh.ellipsoid("Afro puff",center,(.105,.093,.085),deep,group,"hair",20)
            for i in range(17):
                angle = i*2.399
                r = .083*((i+1)/17)**.5
                mesh.ellipsoid("Puff curl", center+v(cos(angle)*r,sin(angle)*r,.067-r*.24),
                               (.034,.032,.031),color("3f3239",rng.uniform(.77,1.1)),group,"hair")
        elif style in ["bun","ponytail"]:
            center = head+v(0,.134,.069)
            mesh.ellipsoid("Tied base",center,(.066,.054,.057),deep,group,"hair")
            mesh.pipe("Hair tie",[center+v(-.043,.026,0),center+v(0,.038,.029),center+v(.043,.026,0)],
                      .008, look.accent, group, "fabric")
            if style == "ponytail":
                mesh.sweep("Ponytail",[(center,.051),(head+v(.007,.185,.002),.055),
                           (head+v(.047,.201,-.145),.039),(head+v(.061,.17,-.233),.011)],
                           "382932",group,"hair")
        else:
            count = 10
            for i in range(count):
                direction = (i / (count-1) - .5) * pi * 1.08
                x, y = sin(direction), cos(direction)
                stations = []
                for step in range(8):
                    t = step / 7
                    spread = .103 + .04*t
                    wiggle = .009*sin(step*1.9+i)
                    stations.append((head+v(x*spread+wiggle,.025+y*spread,.098-.28*t),.027-.009*t))
                mesh.sweep("Braid",stations,color(deep,.8+.07*(i%4)),group,"hair",12)
                if style == "braids":
                    mesh.ellipsoid("Braided end", stations[-1][0],(.015,.018,.024),
                                   color(look.accent,.79+.06*(i%4)), group,"fabric")


def garment(mesh, look, pose, slices):
    top = color(look.top)
    accent = color(look.accent)
    fitted = look.style in ("leather","wrap","blouse","knit")
    expand = .014 if fitted else .025
    groups = "Clothing/spine"
    hem = 1 if look.style in ("raincoat","wrap") else 2
    fitted_slices = [(x,y,z,rx+expand,ry+expand*.78) for x,y,z,rx,ry in slices[hem:-1]]
    x, y, z, rx, ry = fitted_slices[0]
    flare = .015 if look.style in ("raincoat","wrap") else .0
    fitted_slices.insert(0,(x,y,z-.03,rx+flare,ry+flare*.7))
    mesh.loft(look.style.title()+" torso", fitted_slices, top, groups,
              "leather" if look.style == "leather" else "fabric")
    neck_z = 1.463*pose["height"]+pose["bob"]
    neck_y = -.025-pose["lean"]
    if look.style in ("leather","workwear","denim","raincoat","bomber","windbreaker"):
        mesh.loft("Raised collar", [(0, neck_y+.002,neck_z-.038,.102,.077),
                  (0,neck_y,neck_z+.034,.076,.071),(0,neck_y,neck_z+.044,.072,.065)],
                  color(look.top,.79),groups,"leather" if look.style == "leather" else "fabric")
        path = [v(.012,y-ry-expand*.83,z) for _,y,z,_,ry in fitted_slices[1:-1]]
        mesh.pipe("Front seam", path, .0085, color(look.top,.58), groups)
        clasp = path[-2]
        mesh.bar("Jacket pull", clasp+v(0,-.006,0), (.018,.014,.045), accent, groups, "metal")
    if look.style == "raincoat":
        mesh.ellipsoid("Folded rain hood", (0,.076,neck_z-.045), (.110,.105,.054),
                       color(look.top,.82), groups, "fabric")
    if look.style == "knit":
        mesh.loft("Ribbed neckline", [(0,neck_y,neck_z-.012,.091,.074),
                  (0,neck_y,neck_z+.026,.078,.065)], color(look.top,.74), groups)
    if look.style == "wrap":
        path = [v(.079, -.064-pose["lean"], neck_z-.018),
                v(.02,-.163,neck_z-.17),v(-.117,-.126,neck_z-.39)]
        mesh.pipe("Wrap edge", path, .014, accent, groups)
    if look.style in ("workwear","denim"):
        for side in [-1,1]:
            pocket = v(side*.09,-.121-pose["lean"]*.75,1.267*pose["height"]+pose["bob"])
            mesh.bar("Chest pocket",pocket,(.084,.020,.084),color(look.top,.87),groups,"fabric")
            mesh.bar("Pocket flap",pocket+v(0,-.016,.030),(.087,.009,.021),accent,groups,"fabric")
    if look.style in ("bomber","windbreaker","raincoat","leather"):
        x,y,z,rx,ry = fitted_slices[0]
        mesh.loft("Structured hem",[(x,y,z-.009,rx*.96,ry*.98),(x,y,z+.018,rx,ry)],
                  color(look.top,.73),groups,"leather" if look.style == "leather" else "fabric")


def arms(mesh, look, pose, bare, weapon_ready, inner):
    skin = color(look.skin)
    top = color(look.top)
    for side, suffix in [(1,"R"),(-1,"L")]:
        shoulder, elbow, hand = (pose[name+"."+suffix] for name in ("shoulder","elbow","hand"))
        width = pose["width"]
        part = "Arms/" if bare else "Body/"
        upper_bone = "upper_arm."+suffix
        lower_bone = "forearm."+suffix
        upper = {upper_bone:1.0}
        elbow_weights = {upper_bone:.48, lower_bone:.52}
        lower = {lower_bone:1.0}
        if bare or inner:
            mesh.sweep("Arm", [(shoulder-v(side*.033,0,.014),.064*width),
                       (shoulder,.069*width),(shoulder*.54+elbow*.46,.058*width),
                       (elbow,.047*width),(elbow*.43+hand*.57,.041*width),(hand,.032*width)],
                       skin,part+upper_bone,"skin",weights=[upper,upper,upper,elbow_weights,lower,lower])
        hand_group = "Arms/hand."+suffix
        mesh.ellipsoid("Palm", hand, (.040,.060 if weapon_ready else .048,.036), skin, hand_group, "skin", 16)
        mesh.ellipsoid("Thumb", hand+v(-side*.032,-.018,.007),(.017,.035,.020),
                       color(look.skin,1.065),hand_group,"skin")
        if bare:
            continue
        cuff_length = .61 if look.style == "blouse" else .76 if look.style == "workwear" else .86
        forearm = hand*cuff_length+elbow*(1.0-cuff_length)
        if not inner:
            mesh.sweep("Exposed wrist", [(forearm*.89+elbow*.11,.041*width),(hand,.032*width)],
                       skin,part+lower_bone,"skin")
        sleeve_finish = "leather" if look.style == "leather" else "fabric"
        cuff_group = "Sleeves/"+lower_bone
        sleeve_width = (.94 if look.style in ["blouse","knit","wrap"] else 1.0)*width
        mesh.sweep("Sleeve",[(shoulder-v(side*.036,0,.009),.077*sleeve_width),
                   (shoulder,.085*sleeve_width),(shoulder*.54+elbow*.46,.075*sleeve_width),
                   (elbow,.059*sleeve_width),(elbow*.64+forearm*.36,.059*sleeve_width),
                   (forearm,.042*width)],top,"Sleeves/"+upper_bone,sleeve_finish,
                   count=16,weights=[upper,upper,upper,elbow_weights,lower,lower])
        mesh.ellipsoid("Shoulder seam",shoulder-v(side*.039,0,.017),
                       (.076*sleeve_width,.072*sleeve_width,.078*sleeve_width),
                       top,"Sleeves/"+upper_bone,sleeve_finish)
        mesh.pipe("Cuff", [forearm*.94+elbow*.06, forearm*.91+hand*.09], .043*width,
                  color(look.top,.72),cuff_group,sleeve_finish)
        if look.style in ["leather","denim","windbreaker","bomber"]:
            mesh.pipe("Shoulder piping", [shoulder+v(0,-.04,.077), shoulder*.66+elbow*.34+v(0,-.054,.067),
                      elbow+v(0,-.041,.035)],.007,color(look.top,1.34),"Sleeves/upper_arm."+suffix,"fabric")


def legs(mesh, look, pose, bare, inner):
    skin = color(look.skin)
    pants = color(look.pants)
    for side, suffix in [(1,"R"),(-1,"L")]:
        hip, knee, ankle = (pose[name+"."+suffix] for name in ("hip","knee","ankle"))
        width = pose["hip"]
        calf = knee*.69+ankle*.31+v(0,.021,0)
        upper_bone, lower_bone = "thigh."+suffix, "shin."+suffix
        weights = [{upper_bone:1.0}]*3 + [{upper_bone:.48,lower_bone:.52}] + [{lower_bone:1.0}]*3
        centers = [hip+v(0,0,.034), hip, hip*.53+knee*.47, knee, calf,
                   knee*.29+ankle*.71, ankle]
        if inner or bare:
            radii = [.099,.097,.079,.057,.065,.054,.035]
            mesh.sweep("Leg",[(pt,radius*width) for pt,radius in zip(centers,radii)],
                       skin,"Body/"+upper_bone,"skin",count=16,weights=weights)
        if bare:
            mesh.ellipsoid("Foot", ankle+v(0,-.063,-.042),(.057,.127,.045),skin,"Body/foot."+suffix,"skin")
            continue
        cuff = .046 if look.style in ("leather","windbreaker","wrap") else .062
        radii = [.111,.112,.094,.071,.079,.063,cuff]
        mesh.sweep("Trousers",[(pt,radius*width) for pt,radius in zip(centers,radii)],
                   pants,"Trousers/"+upper_bone,count=18,weights=weights)
        if look.style == "workwear":
            mesh.ellipsoid("Cargo patch", hip*.62+knee*.38+v(side*.071,-.035,0),
                           (.042,.077,.069),color(look.pants,.84),"Trousers/"+upper_bone,"fabric")
        outside = side*.071*width
        mesh.pipe("Side seam", [hip+v(side*.096,0,.011), (hip+knee)*.5+v(outside,-.02,0),
                  knee+v(side*.059,-.008,.04)],.006,color(look.pants,1.23),"Trousers/thigh."+suffix)
        shoe = "Footwear/foot."+suffix
        tread = "74675d"
        mesh.ellipsoid("Outsole", ankle+v(0,-.079,-.069),(.065,.141,.021),tread,shoe,"fabric")
        mesh.ellipsoid("Upper shoe", ankle+v(0,-.075,-.041),(.061,.132,.042),
                       look.footwear,shoe,"leather",18)
        mesh.ellipsoid("Toe reinforcement", ankle+v(0,-.138,-.030),(.055,.066,.034),
                       color(look.footwear,1.23),shoe,"leather")
        if look.style in ("workwear","raincoat","denim"):
            mesh.loft("Boot shaft",[(ankle[0],ankle[1],ankle[2]-.02,.055,.065),
                      (ankle[0],ankle[1]+.014,ankle[2]+.108,.052,.066)],look.footwear,shoe,"leather")
        for index in range(3):
            offset = -.044-.019*index
            mesh.pipe("Lace", [ankle+v(-.031,offset-.006,-.002), ankle+v(.031,offset,.001)],
                      .0048,color(look.footwear,1.62),shoe,"fabric")


def person(look, gait="idle", phase=0., hands=None, bare=False, layer="all", inner=False):
    pose = joints(look, gait, phase, hands)
    mesh = Mesh()
    skin = color(look.skin)
    slices = torso_slices(look, pose)
    is_saafiya = look.key == "saafiya"
    if layer != "lower":
        if layer != "arms":
            if bare or inner:
                mesh.loft("Torso",slices if layer == "all" else slices[2:],
                          skin,"Body/spine","skin",28)
            neck_center = pose["head"] - v(0,-.018,.128)
            mesh.ellipsoid("Neck",neck_center,(.062,.063,.088),skin,"Body/neck","skin")
            make_face = costume.head if is_saafiya else make_head
            make_face(mesh,look,pose,bare)
            if not bare:
                if is_saafiya:
                    if not inner:
                        mesh.loft("Shoulders and clavicle",slices[4:],skin,"Body/spine","skin",28)
                    costume.top(mesh,look,pose)
                else:
                    garment(mesh,look,pose,slices)
        if is_saafiya and not bare:
            if inner:
                skin_mesh = Mesh()
                arms(skin_mesh,look,pose,True,hands is not None,True)
                for part in skin_mesh.parts:
                    if part.name == "Arm":
                        part.group = part.group.replace("Arms/","Body/")
                        mesh.parts.append(part)
            costume.arms(mesh,look,pose)
        else:
            arms(mesh,look,pose,bare,hands is not None,inner)
    if layer in ("all","lower"):
        if is_saafiya and not bare:
            costume.skirt(mesh,pose)
            if inner:
                legs(mesh,look,pose,True,True)
            costume.legs(mesh,look,pose,inner)
        else:
            if not bare:
                cut = 4 if layer == "lower" else 3
                pelvis = [(x,y,z,rx+.012,ry+.016) for x,y,z,rx,ry in slices[:cut]]
                mesh.loft("Waist of trousers",pelvis,color(look.pants),"Trousers/pelvis")
            legs(mesh,look,pose,bare,inner)
    return mesh


def bones(look, hands=None):
    pose = joints(look, hands=hands)
    head, hips = pose["head"], pose["hips"]
    h = pose["height"]
    result = {
        "pelvis": (hips, v(0,0,1.02*h), None),
        "spine": (v(0,0,1.02*h), v(0,-.023,1.46*h), "pelvis"),
        "neck": (v(0,-.023,1.46*h), head-v(0,0,.054), "spine"),
        "head": (head-v(0,0,.054), head+v(0,0,.126), "neck"),
    }
    for suffix in ("L","R"):
        def bone(label, start, stop, parent):
            result[label+"."+suffix] = (pose[start+"."+suffix],pose[stop+"."+suffix],parent)
        bone("upper_arm","shoulder","elbow","spine")
        bone("forearm","elbow","hand","upper_arm."+suffix)
        hand = pose["hand."+suffix]
        result["hand."+suffix] = (hand,hand+v(0,-.06,-.03),"forearm."+suffix)
        bone("thigh","hip","knee","pelvis")
        bone("shin","knee","ankle","thigh."+suffix)
        foot = pose["ankle."+suffix]
        result["foot."+suffix] = (foot,foot+v(0,-.122,-.03),"shin."+suffix)
    return {name: {"head": point.tolist(), "tail": tip.tolist(), "parent": parent}
            for name,(point,tip,parent) in result.items()}
