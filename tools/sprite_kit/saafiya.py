"""Saafiya's reference-sheet hair, face, and modular street-goth wardrobe."""
from math import cos, pi, sin, sqrt
import random

import numpy as np

from mesh import color, polygon_rings

INK = "22202a"
PLUM = "342733"
SILVER = "c0b6b2"


def v(x, y, z):
    return np.array((x, y, z), dtype=float)


def loop(mesh, name, center, axis_a, axis_b, gauge, tone, owner, finish="metal", count=18):
    points = [center + axis_a*cos(i*2*pi/count) + axis_b*sin(i*2*pi/count)
              for i in range(count+1)]
    mesh.pipe(name, points, gauge, tone, owner, finish, count=7)


def buckle(mesh, name, point, width, height, owner, tone=SILVER):
    x, y, z = point
    mesh.pipe(name, [(x-width,y,z-height),(x+width,y,z-height),(x+width,y,z+height),
                    (x-width,y,z+height),(x-width,y,z-height)], .0055, tone, owner, "metal")
    mesh.pipe("Buckle pin", [(x-width,y-.002,z), (x+width*.62,y-.002,z)], .0037,
              tone, owner, "metal", 6)


def head(mesh, look, pose, bare):
    center = pose["head"]
    owner = "Body/head"
    skin = color(look.skin)
    mesh.loft("Sculpted face", [
        (*center[:2], center[2]-.138, .035, .047),
        (center[0], center[1]-.013, center[2]-.115, .058, .069),
        (center[0], center[1]-.011, center[2]-.075, .082, .088),
        (center[0], center[1]-.008, center[2]-.031, .101, .099),
        (center[0], center[1], center[2]+.019, .104, .105),
        (center[0], center[1]+.005, center[2]+.066, .096, .097),
        (center[0], center[1]+.009, center[2]+.112, .070, .075),
        (center[0], center[1]+.015, center[2]+.137, .024, .032),
    ], skin, owner, "skin", 36)
    mesh.sweep("Nose bridge",[(center+v(0,-.094,.035),.015),(center+v(0,-.110,.005),.013),
                              (center+v(0,-.125,-.023),.017),
                              (center+v(0,-.115,-.039),.010)],color(look.skin,1.065),owner,"skin")
    for side in [-1,1]:
        mesh.ellipsoid("Ear",center+v(side*.105,.012,-.024),(.019,.026,.039),skin,owner,"skin",18)
        mesh.ellipsoid("Ear contour",center+v(side*.116,-.004,-.021),(.010,.016,.024),
                       color(look.skin,.83),owner,"skin")
        if bare:
            continue
        eye = center + v(side*.043,-.100,.014)
        mesh.ellipsoid("Warm eye white",eye,(.027,.006,.009),"c7a58b",owner,"skin",16)
        mesh.ellipsoid("Brown iris",eye+v(-side*.002,-.005,.0004),
                       (.009,.004,.009),"713f32",owner,"glass",16)
        mesh.ellipsoid("Dark iris center",eye+v(-side*.002,-.007,.001),
                       (.005,.003,.006),"211824",owner,"glass")
        mesh.ellipsoid("Catchlight",eye+v(-.003,-.009,.003),(.0017,.0015,.0017),
                       "ebc9af",owner,"glass")
        mesh.sweep("Winged liner",[(eye+v(-side*.023,-.002,-.002),.0032),
                   (eye+v(-side*.009,-.007,.006),.0041),
                   (eye+v(side*.013,-.004,.008),.0045),
                   (eye+v(side*.032,.007,.014),.002)],
                   "211821",owner,"leather",count=8)
        hair = "32202a"
        mesh.sweep("Shaped brow",[(center+v(side*.020,-.099,.039),.006),
                   (center+v(side*.041,-.100,.049),.007),
                   (center+v(side*.074,-.073,.048),.005),
                   (center+v(side*.085,-.063,.039),.002)],hair,owner,"hair",count=8)
    lip_tone = color(look.skin,.75) if bare else color("34212b")
    mesh.sweep("Lip contour",[(center+v(-.032,-.094,-.074),.0032),
               (center+v(-.012,-.103,-.070),.0065),(center+v(0,-.105,-.074),.005),
               (center+v(.013,-.103,-.070),.0064),(center+v(.032,-.094,-.074),.003)],
               lip_tone,owner,"skin",count=10)
    mesh.ellipsoid("Lower lip",center+v(0,-.105,-.080),(.025,.008,.007),
                   color(look.skin,.88) if bare else "4c2835",owner,"leather",20)
    if not bare:
        curls(mesh, center)


def curls(mesh, center):
    group = "Hair/head"
    base = "271b25"
    rng = random.Random(474)
    mesh.ellipsoid("Hair roots",center+v(0,.033,.062),(.113,.112,.094),
                   base,group,"hair",24)
    bun = center + v(.004,.130,.116)
    mesh.ellipsoid("Gathered curl volume",bun,(.122,.115,.091),"2d202a",group,"hair",24)
    # Individually swept locks follow the oval volume from the hairline toward the tie.
    for index in range(59):
        turn = index*2.399
        altitude = .94 - (index/58)*1.72 + rng.uniform(-.026,.026)
        radial = sqrt(1-altitude**2)
        origin = bun + v(radial*cos(turn)*.141, radial*sin(turn)*.127, altitude*.108)
        axis = v(radial*cos(turn),radial*sin(turn),altitude)
        side = v(-sin(turn),cos(turn),0)
        rise = np.cross(axis,side)
        gauge = rng.uniform(.012,.019)
        offset = rng.uniform(0.,2*pi)
        path = []
        for step in range(17):
            t = step/16.0
            bend = offset+t*4.75
            amplitude = .038*(.62+.38*sin(pi*t))
            point = origin+side*(amplitude*cos(bend))+rise*(amplitude*sin(bend))
            point += axis*(.016+.016*sin(pi*t)) + rise*(.03*(t-.5))
            path.append((point, gauge*(1.09-.74*t*t)))
        palette = ["4b2e3f","6c414f","523447","442a39","784655","48303e"]
        mesh.sweep("Burgundy curl",path,color(palette[index%len(palette)],rng.uniform(.85,1.05)),
                   group,"hair",count=10)
    for index in range(6):
        center_lock = center+v((index-2.5)*.034,-.044,.110)
        points = [(center_lock+v(.017*cos(i*.44+index*.3),-.034*sin(i*.23),.038-i*.005),.013-i*.0005)
                  for i in range(13)]
        mesh.sweep("Swept fringe",points,"4b2f40",group,"hair",count=10)
    for side in [-1,1]:
        for i in range(3):
            path = []
            for step in range(12):
                t = step/11
                point = center+v(
                    side*(.092 + .027*t + .011*sin(t*9+i*.9)),
                    -.060-.042*t+.014*cos(t*10+i) + .018*i,
                    .136-.185*t + .027*i,
                )
                path.append((point,.016*(1.06-.73*t)))
            mesh.sweep("Face-framing tendril",path,"543044" if i==1 else "3c2633",
                       group,"hair",count=10)
        temple = center+v(side*.10,.018,.102)
        mesh.pipe("Silver hair pins",[temple+v(0,.025,.015),temple+v(side*.018,-.021,-.020)],
                  .0052,SILVER,"Jewelry/head","metal")
        ear = center + v(side*.121,.010,-.070)
        loop(mesh,"Silver hoop",ear,v(0,.026,0),v(0,0,.043),.0055,SILVER,"Jewelry/head")
        mesh.ellipsoid("Ear stud",ear+v(0,0,.043),(.008,.008,.008),"ded2c9","Jewelry/head","metal")
    for side in [-1,1]:
        apex = center+v(side*.060,-.071,.145)
        local_up = v(0,-.018,.034)
        owner = "Sunglasses/head"
        # Frames tilt back into the crown, so their silhouette also reads overhead.
        orientation = [[1,0,0],[0,.884,-.468],[0,.468,.884]]
        mesh.ellipsoid("Smoked sunglass lens",apex,(.053,.008,.037),
                       "35303d",owner,"glass",20,orientation)
        loop(mesh,"Silver sunglass rim",apex,v(.055,0,0),local_up,.0048,"b6a5a4",owner)
        mesh.pipe("Sunglass temple",[apex+v(side*.048,.008,.002),apex+v(side*.059,.065,.009),
                  apex+v(side*.052,.129,-.015)],.006,"aca3a0",owner,"metal")
    mesh.pipe("Sunglass bridge",[center+v(-.013,-.078,.148),center+v(0,-.081,.154),
              center+v(.013,-.078,.148)],.0044,"c5b4b0","Sunglasses/head","metal")


def bust_depth(x, z, frontal, pose):
    # Use a broad, pronounced 36DD silhouette that reads at the overhead sprite scale.
    level = (z-pose["bob"])/pose["height"]
    vertical = max(0., 1.-((level-1.312)/.143)**2)**2
    center = .094 * pose["width"]
    radius = .083 * pose["width"]
    lateral = np.exp(-((x-center)/radius)**2) + np.exp(-((x+center)/radius)**2)
    return .175 * vertical * lateral * frontal


def rounded_torso(mesh, name, sections, pose, tone, group, finish, *, corset=False):
    data = np.asarray(sections)
    levels = data[:, 2]

    def surface(z, theta):
        cx, cy, rx, ry = (np.interp(z, levels, data[:, i]) for i in (0, 1, 3, 4))
        x = cx + rx*cos(theta)
        front = max(0., -sin(theta))
        if corset:
            # Gentle sweetheart neckline follows the continuous corset shell.
            upper = max(0., 1. - (levels[-1]-z)/.060)
            dip = .030 * np.exp(-(x/.037)**2)
            lift = .017 * np.exp(-((abs(x)-.089)/.055)**2)
            z += (lift-dip)*front*upper
        y = cy + ry*sin(theta) - bust_depth(x,z,front,pose)
        return v(x,y,z)

    angles = np.linspace(0, 2*pi, 64, endpoint=False)
    fine_levels = np.linspace(levels[0], levels[-1], 34)
    rings = [[surface(z,theta) for theta in angles] for z in sorted(set(levels) | set(fine_levels))]
    mesh.add(name,polygon_rings(rings),tone,group,finish)
    return surface


def top(mesh, look, pose, body_surface):
    owner = "Corset/spine"
    waist, hips = pose["waist"], pose["pelvis_width"]
    height, lean, bob = pose["height"], pose["lean"], pose["bob"]
    y = -.014-lean*.39
    low = 1.00*height+bob
    high = 1.355*height+bob
    corset_sections = [
        (0,y,low-.05,hips*.93,.105),(0,y,low,hips*.99,.113),
        (0,y,low+.091,waist*1.10,.105),(0,y-.009,1.22*height+bob,waist*1.23,.116),
        (0,y-.013,1.305*height+bob,pose["shoulder_width"]*.96,.128),
        (0,y-.013,high,pose["shoulder_width"]*.96,.135),
    ]
    surface = rounded_torso(mesh,"Rounded corset",corset_sections,pose,
                           "302630",owner,"leather",corset=True)

    def front_trim(z, theta):
        return surface(z,theta) + v(0,-.005,0)

    binding = [front_trim(high,theta) + v(0,0,.0015)
               for theta in np.linspace(-pi,0,32)]
    mesh.pipe("Corset binding",binding,.0048,"574250",owner,"leather",count=9)
    for theta in [-2.20,-1.88,-1.25,-.93]:
        path = [front_trim(z,theta) for z in np.linspace(low-.017,high-.018,16)]
        mesh.pipe("Vertical boning",path,.0037,"503d4b",owner,"leather",count=8)

    band = "Belts/spine"
    for height_offset in [.04,.104,.177]:
        z = low+height_offset
        path = [front_trim(z,theta) for theta in np.linspace(-2.29,-.85,9)]
        mesh.pipe("Corset buckle strap",path,.012,"211c27",band,"leather",count=10)
        buckle(mesh,"Front corset buckle",front_trim(z,-1.55)+v(.011,-.015,0),
               .020,.015,band,"b4a79f")
        mesh.ellipsoid("Strap stud",front_trim(z,-1.94)+v(0,-.013,0),(.007,.005,.007),
                       SILVER,band,"metal")
    # The fitted lace runs around the upper back and frames the open neckline.
    lace_torso(mesh,pose)
    lace_group = "Lace top/spine"
    for side in [-1,1]:
        shoulder = v(side*.159,-lean,1.425*height+bob)
        mesh.ellipsoid("Lace shoulder panel",shoulder,(.071,.076,.063),
                       color(look.skin,.81),lace_group,"fabric",18)
        lace_lattice(mesh,shoulder+v(0,0,.025),shoulder-v(0,.012,.077),
                     .069,.081,lace_group)
    neck_y = -.035-lean
    neck_z = 1.53*height+bob
    neck = "Jewelry/neck"
    mesh.loft("Wide black choker",[(0,neck_y,neck_z-.018,.072,.067),
              (0,neck_y,neck_z+.029,.072,.066)],"201b24",neck,"leather")
    loop(mesh,"Choker O ring",v(.009,neck_y-.068,neck_z+.006),
         v(.017,0,0),v(0,0,.018),.0045,SILVER,neck)
    for x in [-.047,.047]:
        mesh.ellipsoid("Choker stud",v(x,neck_y-.051,neck_z+.008),(.007,.004,.006),
                       SILVER,neck,"metal")
    chain = [body_surface(neck_z-.016-.096*sin(pi*t)**.86,-2.57+2.*t) + v(0,-.007,0)
             for t in np.linspace(0,1,25)]
    mesh.pipe("Necklace",chain,.0037,"c3b4a8",neck,"metal")
    crescent = [
        body_surface(neck_z-.129+.020*sin(.55+i*.37),-pi/2+.088*cos(.55+i*.37))
        + v(0,-.009,0)
        for i in range(15)
    ]
    mesh.sweep("Crescent pendant",[(pt,.003+.004*sin(pi*i/14)) for i,pt in enumerate(crescent)],
               "e1d1c4",neck,"metal",count=8)
    jacket_tails(mesh, pose)


def lace_torso(mesh, pose):
    group = "Lace top/spine"
    h, bob, lean = pose["height"], pose["bob"], pose["lean"]
    shoulder = pose["shoulder_width"]

    def point(angle, t):
        z = 1.335 + .168*t
        levels = (1.33, 1.425, 1.467, 1.514)
        width = np.interp(z, levels, (shoulder*.99, shoulder, shoulder*.79, .063)) + .006
        depth = np.interp(z, levels, (.116, .101, .083, .061)) + .007
        y = np.interp(z, levels, (-.018, -.024, -.022, -.025)) - lean*(z-.84)/.65
        return v(width*cos(angle),y+depth*sin(angle),z*h+bob)

    left, right = -.66, pi+.66
    for row in range(6):
        t = row/5.
        edge = .28*t
        path = [point(left+edge+(right-left-2*edge)*i/38,t) for i in range(39)]
        mesh.pipe("Lace edge" if row in (0,5) else "Lace back mesh",path,.004 if row==5 else .0025,
                  "2a202c",group,"fabric",count=5)
    for index in range(22):
        angle = left + (right-left)*(index+.5)/22
        for sign in [-1,1]:
            path = [point(max(left+.28*t,min(right-.28*t,angle+sign*.58*t)),t)
                    for t in np.linspace(0,1,12)]
            mesh.pipe("Lace cross thread",path,.0028,"27202a",group,"fabric",count=5)
        if index%2 == 0:
            for t in (.19,.46,.72):
                flower = point(angle,.99*t)
                for petal in range(4):
                    spin = petal*pi/2
                    mesh.ellipsoid("Lace flower",flower+v(.006*cos(spin),.002,.007*sin(spin)),
                                   (.006,.004,.006),"322632",group,"fabric",9)


def jacket_tails(mesh, pose):
    waist = pose["hips"]
    owner = "Oversized jacket/spine"
    for side in [-1,1]:
        rings = []
        for row in range(5):
            t = row/4.
            ring = []
            for index in range(9):
                s = index/8.
                x = side*(.019+.135*s+t*(.035+.096*s))
                y = .125+.113*t+.038*sin(pi*s)+.032*sin(s*5*pi)*t
                hem = .49-.10*s+.018*cos(3*pi*s)
                z = .988*(1-t)+hem*t
                ring.append(waist+v(x,y,z-.875))
            rings.append(ring)
        for row in range(4):
            for index in range(8):
                faces = [rings[row][index],rings[row+1][index],
                         rings[row+1][index+1],rings[row][index+1]]
                mesh.add("Long jacket drape",(faces,[(0,1,2,3)]),
                         color("302730",.8+.17*((index+row)%3)),owner,"leather",False)
        mesh.pipe("Drape edge",[ring[-1] for ring in rings],.008,"4a3844",owner,"fabric",count=8)


def lace_lattice(mesh, start, end, start_radius, end_radius, group, flowers=True):
    direction = end-start
    forward = direction/max(np.linalg.norm(direction),.001)
    guide = v(0,1,0) if abs(forward[1]) < .90 else v(1,0,0)
    side = np.cross(guide,forward)
    side /= max(np.linalg.norm(side),.001)
    up = np.cross(forward,side)
    for offset in range(9):
        phase = 2*pi*offset/9
        for sign in [-1,1]:
            points = []
            for i in range(17):
                t = i/16
                angle = phase+sign*t*3.2*pi
                radius = start_radius*(1-t)+end_radius*t
                points.append(start+direction*t+(side*cos(angle)+up*sin(angle))*radius)
            mesh.pipe("Lace thread",points,.0025,"27202a",group,"fabric",count=5)
    for at in [.17,.42,.68,.93] if flowers else []:
        radius = start_radius*(1-at)+end_radius*at
        for i in range(6):
            angle = i*pi/3+at*6
            point = start+direction*at+(side*cos(angle)+up*sin(angle))*radius
            mesh.ellipsoid("Lace rosette",point,(.011,.009,.009),"312432",group,"fabric",10)


def arms(mesh, look, pose):
    skin = color(look.skin)
    for side, suffix in [(1,"R"),(-1,"L")]:
        shoulder, elbow, hand = (pose[name+"."+suffix] for name in ("shoulder","elbow","hand"))
        jacket_start = shoulder*.61+elbow*.39+v(side*.015,.014,-.002)
        cuff = elbow*.24+hand*.76+v(0,.011,0)
        lace_owner = "Lace top/upper_arm."+suffix
        mesh.sweep("Sheer sleeve base",[(shoulder-v(side*.024,0,.004),.069),
                   (jacket_start,.062),(elbow,.056)],color(look.skin,.78),lace_owner,"skin")
        lace_lattice(mesh,shoulder,jacket_start,.067,.065,lace_owner)
        mesh.sweep("Visible forearm",[(cuff,.041),(hand,.033)],
                   skin,"Body/forearm."+suffix,"skin")
        upper = {"upper_arm."+suffix:1.0}
        middle = {"upper_arm."+suffix:.47,"forearm."+suffix:.53}
        lower = {"forearm."+suffix:1.0}
        owner = "Oversized jacket/forearm."+suffix
        mesh.sweep("Dropped jacket sleeve",[(jacket_start,.089),(jacket_start*.42+elbow*.58,.107),
                   (elbow+v(side*.024,.017,-.018),.116),(elbow*.62+cuff*.38+v(side*.025,.011,-.01),.102),
                   (elbow*.30+cuff*.70,.086),(cuff,.052)],PLUM,owner,"fabric",count=20,
                   weights=[upper,middle,middle,lower,lower,lower])
        mesh.ellipsoid("Folded off-shoulder rim",jacket_start+v(side*.035,.031,.011),
                       (.073,.079,.046),"392e3b",owner,"leather",16)
        for index in range(3):
            fold_center = elbow*.67+cuff*.33+v(side*.053,.011,.050-index*.027)
            mesh.pipe("Jacket sleeve fold",[fold_center+v(-side*.063,-.042,.026),
                      fold_center+v(side*.020,0,.041),fold_center+v(side*.043,.059,.004)],
                      .012-index*.002,color(PLUM,1.19-index*.08),owner,"leather",count=9)
        lateral = elbow+v(side*.068,-.087,.005)
        mesh.pipe("Jacket seam", [jacket_start+v(side*.050,-.056,.016), lateral,
                  cuff+v(side*.019,-.044,.010)],.0048,"5d4959",owner,"leather")
        mesh.pipe("Heavy cuff", [cuff*.97+elbow*.03,cuff*.90+hand*.10],.052,
                  "28222c",owner,"leather")
        mesh.ellipsoid("Cuff hardware",cuff+v(side*.017,-.024,.044),(.011,.013,.006),
                       SILVER,"Jewelry/forearm."+suffix,"metal")
        hand_owner = "Body/hand."+suffix
        mesh.ellipsoid("Hand",hand,(.041,.056,.034),skin,hand_owner,"skin",20)
        mesh.ellipsoid("Thumb",hand+v(-side*.030,-.014,.008),(.016,.028,.019),
                       color(look.skin,1.04),hand_owner,"skin")
        for index in range(3):
            digit = hand+v(side*(.021-.017*index),-.036-.004*(index%2),.006)
            mesh.ellipsoid("Black manicure",digit+v(0,-.009,.016),
                           (.008,.014,.005),"291f2b",hand_owner,"leather")
        for x in [-.017,.013]:
            loop(mesh,"Silver ring",hand+v(side*x,-.023,.022),v(.009,0,0),v(0,.005,.003),
                 .003,SILVER,"Jewelry/hand."+suffix,count=10)


def skirt(mesh, pose):
    group = "Pleated skirt/pelvis"
    hips = pose["hips"]
    segments = 48
    skirt_rings = []
    for row, (radius_x, radius_y, relative_z) in enumerate([
        (.169,.115,.133),(.187,.136,.079),(.227,.169,-.008),(.267,.211,-.095),(.293,.235,-.173),
    ]):
        points = []
        for i in range(segments):
            angle = i*2*pi/segments
            pleat = (i%3 == 1) * (.003+.0032*row)
            uneven = .010*sin(angle*3)+.006*sin(angle*7)
            points.append(hips+v((radius_x+pleat)*cos(angle), (radius_y+pleat)*sin(angle),
                                relative_z + uneven*(row/4)))
        skirt_rings.append(points)
    points, faces = polygon_rings(skirt_rings)
    # All facets share the same geometry and color except the folds.
    for shade_index, tone in enumerate(["2d2430","372b39","231d27"]):
        panels = [face for i,face in enumerate(faces[1:-1]) if i%3 == shade_index]
        if shade_index == 0:
            panels.extend((faces[0],faces[-1]))
        mesh.add("Pleated skirt fabric",(points,panels),tone,group,"fabric",False)
    for y,z,rx,ry in [(-.004,.116,.177,.119),(-.003,.088,.179,.125)]:
        belt = "Belts/pelvis"
        mesh.loft("Waist belt",[(0,hips[1]+y,hips[2]+z-.014,rx,ry),
                  (0,hips[1]+y,hips[2]+z+.013,rx,ry)],"201a23",belt,"leather")
        buckle(mesh,"Skirt belt clasp",hips+v(-.032,-ry-.009,z),.028,.013,belt)
    for strand in range(2):
        for index in range(22):
            t = index/21
            link = hips+v(-.153+.311*t, -.101-.080*sin(pi*t),
                          .104-.108*sin(pi*t)-strand*.023+.011*t)
            ellipse = v(.010,0,.002) if index%2 else v(.009,.003,.007)
            loop(mesh,"Draped hip chain",link,ellipse,v(0,.005,.008),.0033,
                 "cbb9a6","Jewelry/pelvis",count=10)


def legs(mesh, look, pose, inner):
    skin = color(look.skin)
    for side,suffix in [(1,"R"),(-1,"L")]:
        hip,knee,ankle = (pose[name+"."+suffix] for name in ("hip","knee","ankle"))
        boot_top = knee*.96+ankle*.04
        owner = "Stockings/thigh."+suffix
        thigh = "thigh."+suffix
        shin = "shin."+suffix
        skin_stations = [(hip,.092),(hip*.62+knee*.38,.076),(hip*.21+knee*.79,.061),(knee,.055)]
        if not inner:
            mesh.sweep("Warm skin below fishnet",skin_stations,skin,"Body/"+thigh,"skin",count=18)
        # The open weave follows the animated thigh rather than sliding over it.
        start = hip*.66+knee*.34
        lace_lattice(mesh,start,knee,.080,.058,owner,flowers=False)
        if suffix == "L":
            group = "Thigh strap/"+thigh
            strap = hip*.425+knee*.575
            axis = (knee-hip)/np.linalg.norm(knee-hip)
            mesh.sweep("Leather thigh band",[(strap-axis*.020,.071),(strap+axis*.020,.070)],
                       "25202a",group,"leather",count=18)
            buckle(mesh,"Thigh fastening",strap+v(-.018,-.073,0),.019,.019,group)
        boot = "Platform boots/"+shin
        center = ankle*.47+boot_top*.53
        mesh.sweep("Knee-high boot leather",[(ankle-v(0,0,.025),.061),(ankle,.065),
                   (center,.080),(boot_top-v(0,0,.034),.075),(boot_top,.077)],
                   "2c2631",boot,"leather",count=22)
        foot = "Platform boots/foot."+suffix
        mesh.ellipsoid("Thick platform",ankle+v(0,-.068,-.067),(.082,.149,.026),
                       "26222a",foot,"leather",20)
        mesh.ellipsoid("Rounded toe",ankle+v(0,-.091,-.033),(.074,.137,.045),
                       "322934",foot,"leather",22)
        for i in range(7):
            mesh.bar("Tread",ankle+v(0,-.177+i*.033,-.084),(.145,.022,.016),
                     "302734",foot,"leather",.004)
        for index in range(4):
            fraction = .29+index*.195
            band = ankle*(1-fraction)+boot_top*fraction
            strap_radius = .077 if index < 3 else .081
            axis = (boot_top-ankle)/np.linalg.norm(boot_top-ankle)
            mesh.sweep("Boot buckle strap",[(band-axis*.014,strap_radius),(band+axis*.014,strap_radius)],
                       "201b23",boot,"leather",count=18)
            buckle(mesh,"Square boot buckle",band+v(side*.042,-.070,0),.017,.016,boot)
