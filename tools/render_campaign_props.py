"""Render game props, a minibus and its sliding-door states."""
from math import cos, pi, sin

from PIL import Image
from render_environment import Model, ROOT, Stage


def prop(name):
    m = Model()
    if name == "bottle":
        m.tube((0,-.41,.10),(0,.22,.10),.092,"5c745a",.43)
        m.ellipsoid((0,.22,.10),(.092,.10,.090),"809174")
        m.tube((0,.23,.10),(0,.43,.10),.041,"68856b",.50)
        m.tube((0,.40,.10),(0,.46,.10),.055,"92887c",.38)
        m.tube((0,-.19,.10),(0,.052,.10),.096,"bcb192",.18)
    elif name == "tyre":
        for radius, height, tone in [(.37,.04,"303138"),(.36,.13,"3d4246"),(.35,.202,"34353d")]:
            ring = [(cos(i*pi/20)*radius,sin(i*pi/20)*radius,height) for i in range(41)]
            for a,b in zip(ring, ring[1:]):
                m.tube(a,b,.052,tone,.08,8)
        for i in range(24):
            t=i*pi/12
            m.tube((.383*cos(t),.383*sin(t),.15),(.391*cos(t+.046),.391*sin(t+.046),.06),.016,"22242b",.11,6)
    elif name == "carton":
        m.box((0,0,.14),(.65,.43,.28),"a4815d")
        m.box((0,-.02,.282),(.041,.42,.008),"c7a478")
        m.box((.13,-.03,.284),(.12,.19,.010),"716250")
        m.box((0,.188,.154),(.66,.014,.041),"65503f")
    elif name == "rubble":
        for x,y,z,r in [(-.24,.1,.109,.17),(.086,-.05,.126,.28),(.27,.175,.092,.143),(-.18,-.23,.063,.11)]:
            m.shell([[(x-r,y-r*.58,.014),(x+r*.76,y-r*.72,.014),
                      (x+r,y+r*.45,.014),(x-r*.62,y+r*.79,.014)],
                     [(x-r*.62,y-r*.42,z),(x+r*.47,y-r*.49,z*1.07),
                      (x+r*.73,y+r*.28,z),(x-r*.41,y+r*.58,z*.71)]],
                    "888276" if x < 0 else "9a9088")
    elif name == "blade":
        m.tube((0,-.36,.07),(0,-.054,.07),.057,"3f3b41",.12)
        # An intentionally stylized broad silhouette for the small overhead sprite.
        m.shell([[(-.051,-.055,.061),(.09,-.047,.061),(.11,.32,.05),(.028,.46,.05),(-.033,.33,.05)],
                 [(-.047,-.051,.092),(.075,-.043,.094),(.09,.31,.075),(.028,.441,.060),(-.030,.32,.07)]],
                "afaab2",.55)
        m.tube((-.094,-.072,.082),(.095,-.072,.082),.026,"69706e",.24)
    elif name == "pebble":
        m.ellipsoid((0,0,.12),(.24,.20,.13),"958f7c")
        m.ellipsoid((-.022,.037,.18),(.19,.128,.074),"b1a792")
    return m


def taxi(door):
    m = Model()
    m.windscreen = [(1.88,-.60,.97),(1.88,.60,.97),(1.18,.64,1.33),(1.18,-.64,1.33)]
    m.side_windows = {side:[
        [(lo,side*.808,.91),(hi,side*.808,.91),(hi,side*.808,1.23),(lo,side*.808,1.23)]
        for lo,hi in [(-2.00,-1.26),(-1.10,-.15)]
    ] for side in [-1,1]}
    m.shadows += [(4.72,1.89,.09,115),(4.32,1.75,.71,56)]
    white, gray, glass, trim = "ded8cc", "c7c4bc", "3b5663", "353740"
    m.box((0,0,.62),(4.55,1.68,.77),white,.29)
    m.box((-.30,0,1.06),(3.83,1.47,.35),"53565a",.12)
    m.box((-.34,.785,1.08),(3.62,.075,.39),glass,.24)
    m.box((-.68,0,1.38),(3.62,1.70,.13),white,.32)
    m.box((-.69,0,1.46),(3.03,1.44,.039),"e5ddd3",.27)
    for side in [-1,1]:
        y = side*.815
        for x in [-2.12,-1.14,.04,1.09]:
            m.box((x,y,1.09),(.075,.063,.42),gray,.32)
        m.box((-.42,y,.83),(3.72,.059,.043),"bc9774",.24)
        m.box((-.42,y,.72),(3.72,.062,.078),"8a8570",.23)
        for x in [-1.53,1.37]:
            m.tube((x,y-.17,.28),(x,y+.15,.28),.275,"2a2932",.15)
            m.tube((x,y+side*.157,.28),(x,y+side*.17,.28),.151,"8f9294",.32)
        m.box((2.167,side*.61,.73),(.11,.29,.14),"ecdaa4",.30)
        m.box((-2.21,side*.71,.72),(.10,.13,.24),"a84946",.28)
    m.shell([[(-2.16,-.74,.97),(-2.16,.74,.97),(1.94,.73,.92),(1.94,-.73,.92)],
             [(-2.10,-.72,1.39),(-2.10,.72,1.39),(1.126,.69,1.38),(1.126,-.69,1.38)]],glass,.42)
    m.box((1.91,0,.9),(1.02,1.63,.146),white,.35)
    m.box((2.26,0,.54),(.11,1.70,.16),trim,.22)
    m.box((-2.31,0,.52),(.12,1.71,.17),trim,.20)
    m.box((2.324,0,.67),(.035,.47,.097),"c8bdb0",.20)
    m.box((-.31,-.834,1.03),(1.27,.039,.50),"272b35",.12)
    panel_x = -.42 - door*1.03
    m.box((panel_x,-.875,.89),(1.17,.072,.60),white,.31)
    m.box((panel_x,-.915,1.071),(.99,.03,.22),glass,.35)
    m.box((panel_x-.31,-.933,.84),(.151,.037,.035),"c1b6a4",.35)
    return m


if __name__ == "__main__":
    stage = Stage()
    for name in ("bottle","rubble","tyre","carton","blade","pebble"):
        stage.render(prop(name),(128,128),1.21,f"props/rendered/{name}.png",focal_z=.10)
    files = ROOT/"environment/vehicles"
    for ending, angle in [("east",0),("west",180)]:
        if angle == 0:
            stage.render(taxi(0),(288,136),5.74,"environment/vehicles/taxi_east.png",
                         focal_z=.48,heading=angle)
            continue
        for step in range(5):
            stage.render(taxi(step/4),(288,136),5.74,f"environment/vehicles/taxi_{ending}_{step}.png",
                         focal_z=.48,heading=angle)
        frames = [Image.open(files/f"taxi_{ending}_{step}.png") for step in range(5)]
        sheet = Image.new("RGBA",(288*5,136))
        for step, frame in enumerate(frames):
            sheet.paste(frame,(288*step,0))
            frame.close()
            if step:
                (files/f"taxi_{ending}_{step}.png").unlink()
        sheet.save(files/f"taxi_{ending}_door.png",optimize=True)
        (files/f"taxi_{ending}_0.png").rename(files/f"taxi_{ending}.png")
