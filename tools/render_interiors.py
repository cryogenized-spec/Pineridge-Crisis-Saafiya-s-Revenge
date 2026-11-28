"""Render cutaways registered to the gameplay footprints in the three room layouts."""
from math import cos, sin
import random

from render_environment import ELEVATION, Model, Stage, tint

UNIT = .026
PLASTER = "d3b89c"
WOOD = "8f684c"
TRIM = "6e5449"


class Interior:
    def __init__(self, size):
        self.size = size
        self.model = Model()

    def xyz(self, x, y, z):
        return ((x-self.size[0]/2)*UNIT, (self.size[1]/2-y)*UNIT/sin(ELEVATION), z)

    def box(self, rect, z, height, material, gloss=0):
        x, y, w, h = rect
        self.model.box(self.xyz(x+w/2, y+h/2, z+height/2),
                       (w*UNIT, h*UNIT/sin(ELEVATION), height), material, gloss)

    def cushion(self, rect, z, height, material):
        x, y, w, h = rect
        self.model.ellipsoid(self.xyz(x+w/2, y+h/2, z+height*.49),
                             (w*UNIT*.52, h*UNIT*.53/sin(ELEVATION), height*.64), material)

    def round(self, point, radius, z, height, material, gloss=0):
        x, y = point
        self.model.tube(self.xyz(x,y,z), self.xyz(x,y,z+height), radius*UNIT, material, gloss, 20)

    def floor(self, rect, material, planks=True, lift=0):
        x,y,w,h = rect
        self.box((x-5,y-5,w+10,h+10), -.22, .20, "55413e")
        self.box(rect, -.13+lift, .15, tint(material,.70))
        rng = random.Random(808)
        step_x, step_y = (13,46) if planks else (20,20)
        for i, left in enumerate(range(x,x+w,step_x)):
            offset = (i%3)*15 if planks else 0
            for j, top in enumerate(range(y-offset,y+h,step_y)):
                low, high = max(top,y), min(top+step_y,y+h)
                if high-low <= 1:
                    continue
                shade = rng.uniform(.9,1.08) if planks else (.86 if (i+j)%2 else 1.03)
                self.box((left,low,min(step_x-.7,x+w-left), high-low-.65), .017+lift, .024,
                         tint(material,shade), .06)
                if planks and high-low > 11:
                    self.box((left+2,low+2,.65,high-low-6), .042+lift, .002, tint(material, shade*.88))

    def wall(self, rect, height=.94):
        x,y,w,h = rect
        self.box((x-3,y+3,w+6,h+3), .045, .009, "6c514a")
        self.box(rect, .044, height, PLASTER)
        self.box((x-1,y-1,w+2,h+2), height, .105, "96796c", .07)
        self.box((x-1,y-1,w+2,h+2), .045, .14, TRIM)

    def rug(self, rect, material):
        x,y,w,h = rect
        self.box(rect, .045, .025, material)
        self.box((x+5,y+6,w-10,h-12), .068, .005, tint(material,1.38))
        self.box((x+9,y+10,w-18,h-20), .072, .004, tint(material,.91))
        for i in range(x+12,x+w-10,12):
            for d in (y+15,y+h-17):
                self.box((i,d,4,3), .077, .002, "c49777")
        for i in range(x+4,x+w-4,4):
            for d in (y-2,y+h):
                self.box((i,d,1.3,2.7), .048, .006, "bf9879")

    def legs(self, rect, height, material=TRIM):
        x,y,w,h = rect
        for cx in (x+5,x+w-8):
            for cy in (y+5,y+h-8):
                self.box((cx,cy,3,3), .044, height, material)

    def table(self, rect, height=.54):
        x,y,w,h = rect
        self.legs(rect, height)
        self.box((x+4,y+4,w-8,h-8), height-.09, .11, "6e4c3c")
        self.box(rect, height, .109, "987451", .20)
        for i in range(1,4):
            self.box((x+1,y+i*h/4,w-2,.72), height+.108, .003, "896247")

    def cabinet(self, rect, height=.8, material="7c7867", countertop="a79e91"):
        x,y,w,h = rect
        self.box(rect, .044, height, material)
        self.box((x-1.5,y-1.5,w+3,h+3), height, .073, countertop, .18)
        for left in range(x+4,x+w-12,16):
            self.box((left,y+h-.5,10,1.4), .47, .046, "594944")
            self.box((left+3,y+h+.4,4,1.4), .62, .043, "bbb5a0", .25)

    def sofa(self, rect, color="647873"):
        x,y,w,h = rect
        self.legs(rect,.15)
        self.box((x+3,y+1,w-6,h-2), .14, .35, tint(color,.82))
        self.box((x,y+3,10,h-6), .42, .47, color)
        for top in (y+2,y+h-13):
            self.cushion((x+2,top,w-2,11), .40,.30,color)
        for i in range(3):
            self.cushion((x+10,y+12+i*(h-22)/3, w-15,(h-23)/3), .42,.19,tint(color,1.14))
        self.cushion((x+11,y+23,13,19), .58,.18,"ae7e69")

    def planter(self, point, radius, seed):
        x,y = point
        self.round(point,radius,.045,.31,"9c6955")
        self.round(point,radius+1,.31,.08,"b9896d")
        self.round(point,radius-1,.385,.016,"504738")
        rng = random.Random(seed)
        for i in range(10):
            angle = i * 2.399
            width = rng.uniform(.13,.26)
            dx, dy = cos(angle)*width, sin(angle)*width
            stem = self.xyz(x,y,.39)
            tip = tuple(stem[a] + (dx,dy,rng.uniform(.21,.52))[a] for a in range(3))
            self.model.tube(stem,tip,.014,"73845b")
            self.model.ellipsoid(tip,(.14,.10,.075),["687c50","8f975f","537453"][i%3])

    def stairs(self, rect, rising=True):
        x,y,w,h = rect
        for step in range(10):
            fraction = (step+1 if rising else 10-step)/10
            self.box((x+step*w/10,y,w/10+.25,h),.044,.12+fraction*.67,
                     tint(WOOD,.88+fraction*.19))
            self.box((x+step*w/10,y,1.4,h),.16+fraction*.67,.028,"b09373")
        for side_y in [y+1,y+h-2]:
            for i in (0,3,6,9):
                top = .30+(i if rising else 9-i)*.07
                self.model.tube(self.xyz(x+3+i*w/10,side_y,.045), self.xyz(x+3+i*w/10,side_y,top+.38),
                                .035,"655051")
            z0,z1 = (.65,1.25) if rising else (1.25,.65)
            self.model.tube(self.xyz(x+3,side_y,z0),self.xyz(x+w-5,side_y,z1),.049,"977260")

    def bed(self, rect):
        x,y,w,h = rect
        self.legs(rect,.20)
        self.box(rect,.18,.30,"695250")
        self.box((x-1,y-1,9,h+2),.20,.72,"8d6f60")
        self.cushion((x+8,y+3,w-13,h-6),.44,.21,"cec0a4")
        self.box((x+30,y+6,w-35,h-12),.60,.105,"758d87")
        self.box((x+31,y+7,7,h-14),.705,.014,"a4b4a4")
        for i in range(x+45,x+w-7,9):
            self.box((i,y+7,1,h-14),.704,.012,"869f95")
        for top in (y+9,y+h/2+3):
            self.cushion((x+5,top,23,h/2-10),.60,.19,"e1d2b7")


def jacobs_lower():
    room = Interior((900,506))
    room.model.shadows.append((18.9,8.3,.03,77))
    room.floor((308,40,280,76),"a4a28a",False)
    for edge in [(308,40,84,5),(501,40,87,5),(308,40,6,70),(582,40,6,70)]:
        room.wall(edge,.41)
    for index,pot in enumerate([(332,64),(567,66),(548,103)]):
        room.planter(pot,9,index+56)
    room.floor((92,116,716,310),"a87952")
    room.floor((492,121,308,295),"c3b7a2",False,.075)
    for wall in [(92,110,331,14),(475,110,333,14),(91,115,9,311),(800,115,8,311),
                 (96,420,314,6),(487,420,317,6),(413,140,12,137),(470,270,12,104)]:
        room.wall(wall)
    room.rug((188,189,193,138),"975d5c")
    room.sofa((122,178,56,122))
    room.table((225,221,107,56),.49)
    room.round((265,247),10,.61,.092,"cfad77",.24)
    room.round((265,247),6,.698,.021,"a17c52")
    room.box((296,238,18,12),.611,.065,"58605e")
    room.cabinet((200,331,121,35),.61,"74564a","a0795e")
    room.cabinet((530,138,233,44),.91)
    room.cabinet((691,183,72,57),.91,"75817b","a4aba2")
    room.table((546,226,103,57),.69)
    room.box((551,144,53,29),.983,.044,"b5bcb1",.33)
    room.box((557,150,40,16),1.024,.007,"687c7a",.25)
    room.model.tube(room.xyz(576,145,1.02),room.xyz(576,148,1.25),.040,"bec3b2",.42)
    room.box((643,142,50,34),.984,.053,"48474c",.43)
    for x in (653,680):
        for y in (150,166):
            room.round((x,y),5,1.04,.022,"7d7c78",.35)
            room.round((x,y),3,1.063,.009,"393941")
    for x in (572,617):
        room.round((x,252),9,.802,.054,"dcd2ac",.20)
        room.round((x,252),5,.854,.019,"aead9a")
    room.stairs((708,343,78,56))
    return room


def jacobs_upper():
    room = Interior((900,506))
    room.model.shadows.append((18.9,8.3,.03,77))
    room.floor((92,116,716,310),"a27959")
    room.floor((466,121,331,155),"44404d",False,.075)
    for wall in [(92,112,713,11),(92,117,8,307),(800,117,8,307),(96,419,708,7),
                 (92,279,181,14),(327,279,253,14),(634,279,174,14),(446,117,14,170)]:
        room.wall(wall)
    room.rug((275,162,62,110),"677975")
    room.bed((142,149,114,76))
    room.cabinet((143,242,74,26),.55,"856656","a4846b")
    room.cabinet((353,143,54,102),1.30,"896854","a6896b")
    for y in (160,179,207,228):
        room.box((351,y,3,7),.80,.08,"bcab94",.24)
    room.box((580,279,54,14),.044,1.04,"8a6354")
    room.box((587,292,40,2),.12,.80,"a38069")
    room.round((622,293),2,.64,.075,"d5b58a",.48)
    room.stairs((708,343,78,56),False)
    return room


def front_room():
    room = Interior((550,240))
    room.floor((189,40,304,176),"a87852")
    for wall in [(186,37,310,9),(185,43,8,172),(488,43,9,172),(189,209,130,8),(357,209,133,8)]:
        room.wall(wall,.72)
    room.rug((263,69,156,100),"925b5d")
    room.cabinet((202,57,60,58),.57,"795f57","ae8c6d")
    room.sofa((429,59,47,96),"597773")
    room.table((284,84,78,37),.46)
    room.round((326,103),8,.571,.127,"c3b185")
    room.planter((463,186),9,702)
    return room


if __name__ == "__main__":
    stage = Stage()
    for key, scene in [("jacobs_ground", jacobs_lower()), ("jacobs_upper", jacobs_upper()),
                       ("barricaded_front_room", front_room())]:
        stage.render(scene.model, tuple(int(size*1.5) for size in scene.size),
                     scene.size[0]*UNIT, f"environment/interiors/{key}.png")
