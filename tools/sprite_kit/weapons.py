"""Original game-prop meshes with independent visible moving parts."""
from math import cos, pi, sin

from mesh import Mesh, color

VIEW = 2.84
SIZE = (256, 96)
FOCUS = (0, 0, .168)


def pistol(gear):
    mesh = Mesh()
    nickel = gear.ident == "beretta_84fs"
    polymer = "28292f" if gear.ident != "canik_tp9" else "6e6254"
    top = "a6a4a1" if nickel else ("73737b" if gear.ident == "canik_tp9" else "45484f")
    edge = "d5c8b4" if nickel else ("b8a897" if gear.ident == "canik_tp9" else "686e79")
    grip = "604638" if nickel else polymer
    receiver = "Receiver/weapon"
    action = "Action/weapon"
    mag = "Magazine/weapon"
    muzzle = gear.muzzle
    back = -.34 if nickel else -.38
    slide_width = .225 if nickel else .254
    mesh.bar("Frame", ((muzzle+back)*.45,0,.112),
             (muzzle-back-.052,slide_width+.008,.106),polymer,receiver,"leather")
    mesh.bar("Grip core",(-.134,0,-.011),(.405,.260,.192), grip,receiver,"leather",.044)
    mesh.bar("Dust cover",(.40,0,.075),(.42,slide_width*.91,.103),polymer,receiver,"leather")
    mesh.pipe("Guard",[(-.219,-.139,.015),(.048,-.150,-.033),(.236,-.135,.032),(.220,-.081,.088)],
              .027,polymer,receiver,"leather")
    mesh.pipe("Barrel highlight",[(back+.165,0,.160),(muzzle-.008,0,.160)],.062,
              "6d6867" if nickel else "3b3e46",receiver,"metal",20)
    mesh.pipe("Muzzle rim",[(muzzle-.018,0,.160),(muzzle,0,.160)],.059,edge,receiver,"metal",20)
    mesh.bar("Magazine floor plate",(-.269,-.022,-.078),(.154,.238,.081),polymer,mag,"leather",.020)
    for side in [-1,1]:
        mesh.bar("Grip insert",(-.16,side*.131,-.009),(.26,.018,.113),grip,receiver,"leather")
        for line in range(6):
            mesh.bar("Grip texture",(-.26+line*.041,side*.141,.007),(.012,.009,.086),
                     color(grip,.7+.06*(line%3)),receiver,"leather",.004)
    if nickel:
        # Framed open silhouette shows the contrasting barrel below it.
        for side in [-1,1]:
            mesh.bar("Polished side rail",(.235,side*.089,.217),
                     (muzzle-back-.058,.056,.106),top,action,"metal",.020)
            mesh.bar("Beveled rail reflection",(.244,side*.104,.273),
                     (.99,.015,.011),edge,action,"metal",.005)
        mesh.bar("Breech top",(-.233,0,.221),(.232,.224,.114),top,action)
        mesh.bar("Nose cap",(muzzle-.068,0,.208),(.108,.227,.094),top,action)
    else:
        slide_center = (muzzle+back)*.5-.015
        slide_length = muzzle-back-.046
        mesh.bar("Slide",(slide_center,0,.218),(slide_length,slide_width,.124),
                 top,action,"metal",.031)
        mesh.bar("Recessed top plate", (gear.port,0,.281),(.164,.121,.012), "24252b",action)
        for side in [-1,1]:
            mesh.bar("Long machined bevel",(slide_center,side*.092,.281),
                     (slide_length*.83,.018,.012),edge,action,"metal",.004)
    for step in range(6):
        x = back+.052+step*.030
        for side in [-1,1]:
            y = side*(.087 if nickel else .104)
            mesh.bar("Slide serration",(x,y,.275),(.012,.053,.014),
                     color(top,.53),action,"metal",.003)
    for x,z,w in [(back+.023,.29,.154),(muzzle-.083,.287,.035)]:
        mesh.bar("Sight",(x,0,z),(.040,w,.033),"26242a",action,"metal",.007)
    mesh.bar("Sight highlight",(muzzle-.083,0,.307),(.017,.016,.007),"ddd1a4",action)
    return mesh


def long_gun(gear):
    mesh = Mesh()
    pump = gear.action == "pump"
    receiver, action, mag = "Receiver/weapon", "Action/weapon", "Magazine/weapon"
    wood = "504746" if pump else "82533d"
    edge = "9a8a7c" if pump else "ad7853"
    steel = "4f4e55" if pump else "41434a"
    dark = "282832"
    mesh.bar("Receiver",(.084,0,.137),(.703,.286,.176),steel,receiver,"metal",.040)
    mesh.bar("Top surface",(.076,0,.215),(.670,.242,.084),color(steel,1.17),receiver)
    mesh.pipe("Barrel",[(.34,0,.177),(gear.muzzle,0,.177)], .052,steel,receiver,"metal",20)
    mesh.pipe("Muzzle band",[(gear.muzzle-.074,0,.177),(gear.muzzle,0,.177)],
              .065,"2e2f35",receiver,"metal",20)
    mesh.bar("Stock wrist",(-.574,0,.092),(.49,.22,.169),wood,receiver,"leather",.043)
    mesh.bar("Shoulder stock",(-.942,0,.086),(.483,.343,.188),wood,receiver,"leather",.062)
    mesh.bar("Stock end",(-1.148,0,.087),(.105,.332,.182),dark,receiver,"leather",.027)
    for side in [-1,1]:
        mesh.bar("Stock bevel",(-.954,side*.121,.182),(.356,.024,.017),edge,receiver,
                 "leather",.007)
    mesh.bar("Grip",(-.217,0,-.014),(.181,.228,.152),dark,receiver,"leather")
    mesh.bar("Receiver port",(gear.port,-.007,.257),(.264,.135,.016),
             "22262f",receiver,"metal",.004)
    mesh.bar("Receiver lip",(gear.port,+.074,.267),(.303,.015,.013),
             "8e8d91",receiver,"metal",.004)
    if pump:
        mesh.pipe("Under-barrel tube",[(.45,0,.085),(1.178,0,.085)],
                  .071,dark,receiver,"metal",16)
        mesh.bar("Ribbed fore-end",(.673,0,.106),(.482,.320,.199),wood,action,"leather",.043)
        for i in range(8):
            mesh.bar("Fore-end rib",(.473+i*.059,0,.218),(.020,.284,.024),
                     "78696a",action,"leather",.008)
        mesh.bar("Shell glint",(.253,0,.256),(.138,.076,.024),"ae6c46",receiver)
    else:
        mesh.bar("Fore-end",(.598,0,.129),(.492,.308,.195),wood,receiver,"leather",.047)
        for side in [-1,1]:
            mesh.bar("Fore-end bevel",(.590,side*.108,.229),(.390,.021,.022),
                     edge,receiver,"leather")
        mesh.bar("Exposed action accent",(gear.port,.009,.258),(.142,.086,.024),
                 "9b9693",action)
        mesh.bar("Bolt handle",(gear.port,-.166,.206),(.075,.138,.066),
                 color(steel,1.28),action)
        mesh.sweep("Magazine shell",[((.165,-.03,-.010),(.113,.143)),
                   ((.273,-.079,-.083),(.114,.145)),((.406,-.164,-.196),(.107,.123)),
                   ((.461,-.241,-.256),(.126,.105))], "353742",mag,"metal")
        mesh.bar("Magazine heel",(.457,-.236,-.261),(.172,.159,.045),"4b4750",mag)
    mesh.bar("Front sight",(gear.muzzle-.080,0,.246),(.058,.046,.096),dark,receiver)
    mesh.bar("Rear sight",(-.184,0,.282),(.105,.125,.051),dark,receiver)
    return mesh


def revolver(gear):
    mesh = Mesh()
    frame, action = "Receiver/weapon", "Action/weapon"
    faded = "918d8d"
    steel = "aba8a6"
    mesh.pipe("Barrel",[(.16,0,.165),(gear.muzzle,0,.165)],.070,faded,frame,"metal",24)
    mesh.bar("Barrel rib",(.481,0,.225),(.441,.095,.068),steel,frame)
    mesh.bar("Revolver frame",(-.09,0,.133),(.354,.219,.160),faded,frame)
    mesh.bar("Walnut grip",(-.33,0,-.004),(.309,.245,.225),"68483d",frame,"leather",.049)
    mesh.pipe("Trigger guard",[(-.248,-.117,.018),(-.095,-.145,-.055),
              (.117,-.116,-.010),(.139,-.071,.074)],.024,faded,frame,"metal")
    mesh.pipe("Fluted cylinder",[(-.117,0,.158),(.243,0,.158)],.155,steel,action,"metal",30)
    for index in range(6):
        angle = 2*pi*index/6
        y,z = sin(angle)*.150,.158+cos(angle)*.151
        mesh.pipe("Cylinder flute",[(-.077,y,z),(.149,y,z)],.020,"67636a",action,"metal")
    for index in range(4):
        x = -.221+index*.112
        ring = [(x+.039*cos(j*2*pi/14),-.052+.029*sin(j*2*pi/14),.269)
                for j in range(15)]
        mesh.pipe("Etched scroll motif",ring,.0037,"dcc5ae",frame,"metal",6)
    mesh.bar("Front bead",(gear.muzzle-.065,0,.269),(.032,.037,.054),"383139",frame)
    return mesh


def blade(gear):
    mesh = Mesh()
    frame = "Receiver/weapon"
    length = gear.muzzle
    handle = .43 if gear.ident != "akm_bayonet" else .52
    if gear.ident == "fairbairn_sykes":
        shape = [(0,-.050,.183),(.17,-.074,.183),(length-.18,-.047,.178),
                 (length,0,.164),(length-.18,.047,.180),(.17,.074,.183),(0,.050,.183)]
    elif gear.ident == "spetsnaz_sf":
        shape = [(0,-.075,.183),(.21,-.109,.183),(length-.13,-.073,.179),
                 (length,-.027,.164),(length-.23,.072,.180),(.10,.097,.183),(0,.066,.183)]
    else:
        shape = [(0,-.071,.183),(.29,-.083,.185),(length-.25,-.079,.180),
                 (length,-.022,.165),(length-.20,.068,.181),(.12,.084,.183),(0,.057,.183)]
    center = (length*.47, 0, .213)
    points = shape + [center]
    for index in range(len(shape)):
        triangle = [points[index],points[(index+1)%len(shape)],center]
        mesh.add("Ground blade facet",(triangle,[(0,1,2)]),
                 "b7bdbe" if index < 3 else "727781",frame,"metal",False)
    mesh.pipe("Blade spine",[(.017,0,.216),(.47*length,0,.219),(length-.035,0,.171)],
              .009,"bec4c2",frame,"metal")
    hilt = "524339" if gear.ident == "fairbairn_sykes" else "282b32"
    mesh.pipe("Guard",[(.009,-.139,.136),(.008,.139,.136)],.037,"98908b",frame,"metal",20)
    if gear.ident == "akm_bayonet":
        loop = [(0, -.176+.066*cos(i*2*pi/20), .16+.052*sin(i*2*pi/20)) for i in range(21)]
        mesh.pipe("Mount silhouette", loop, .017, "777880", frame, "metal")
    elif gear.ident == "spetsnaz_sf":
        mesh.bar("Guard scallop",(-.020,.085,.14),(.085,.155,.090),"535159",frame)
        mesh.bar("Dark fuller",(.349,-.023,.202),(.335,.019,.014),"5c6870",frame,"metal",.003)
    mesh.pipe("Grip",[(-handle,0,.128),(-.020,0,.128)],.075,hilt,frame,"leather",20)
    for i in range(7):
        x = -handle+.050+i*(handle-.08)/7
        mesh.pipe("Grip knurl",[(x,0,.127),(x+.011,0,.127)],.077,
                  color(hilt,1.35),frame,"leather",12)
    mesh.bar("Pommel",(-handle,0,.134),(.064,.153,.105),"6b6771",frame)
    return mesh


def weapon(gear):
    makers = {"slide":pistol, "bolt":long_gun, "pump":long_gun, "revolver":revolver, "blade":blade}
    return makers[gear.action](gear)


def casing(shape):
    mesh = Mesh()
    barrel = "Casing/case"
    if shape == "shell":
        mesh.pipe("Husk",[(-.335,0,.12),(.279,0,.12)],.100,"883d42",barrel,"leather",22)
        mesh.pipe("Base",[(-.448,0,.12),(-.32,0,.12)],.109,"bd9560",barrel,"metal",24)
    else:
        reach = .41 if shape == "long" else .28
        mesa = .078 if shape == "long" else .091
        mesh.pipe("Brass shell",[(-reach,0,.1),(reach,0,.1)],mesa,"c69a53",barrel,"metal",24)
        mesh.pipe("Extraction band",[(-reach-.043,0,.1),(-reach+.031,0,.1)],
                  mesa*1.12,"99815f",barrel,"metal",24)
        mesh.pipe("Open rim",[(reach-.045,0,.1),(reach+.015,0,.1)],
                  mesa*1.045,"e5c58d",barrel,"metal",24)
        mesh.pipe("Shaded mouth",[(reach+.012,0,.1),(reach+.019,0,.1)],
                  mesa*.73,"443631",barrel,"leather",20)
    return mesh
