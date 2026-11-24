"""Render 12 eight-frame sideways collapse atlases from the original VTK crowd mesh.

Requires vtk, numpy and Pillow. Produces transparent 512x256 PNG atlases
with eight 128x128 frame cells. No generated-image model is used.
"""
import math
from pathlib import Path
import numpy as np
import vtk
from PIL import Image

source_path=Path(__file__).with_name("render_crowd.py")
source=source_path.read_text()
ns={"__file__":str(source_path)}
exec(compile(source.split("manifest=[];review=")[0],str(source_path),"exec"),ns)
body=ns["body"]
capture=ns["capture"]
cam=ns["cam"]
actors=ns["actors"]
out=Path(__file__).resolve().parents[1]/"assets/characters/crowd"
out.mkdir(parents=True,exist_ok=True)

for idx in range(12):
    atlas=Image.new("RGBA",(512,256),(0,0,0,0))
    for frame in range(8):
        t=frame/7.0
        easing=t*t*(3-2*t)
        cam.SetParallelScale(.65+.45*easing)
        cam.SetFocalPoint(.34*easing,0,.87)
        body(idx,"idle",0)
        angle=math.radians(76*easing)
        rotation=np.array([
            [math.cos(angle),0,math.sin(angle)],
            [0,1.,0],
            [-math.sin(angle),0,math.cos(angle)]
        ])
        pivot=np.array([0.,0.,.55])
        shift=pivot-rotation@pivot+np.array([0.,0.,-.36*easing])
        matrix=vtk.vtkMatrix4x4()
        for row in range(3):
            for col in range(3):
                matrix.SetElement(row,col,float(rotation[row,col]))
            matrix.SetElement(row,3,float(shift[row]))
        matrix.SetElement(3,3,1)
        for actor in actors:
            actor.SetUserMatrix(matrix if actor.GetVisibility() else None)
        atlas.paste(capture(),((frame%4)*128,(frame//4)*128))
    atlas.save(out/f"npc_{idx:02d}_down_side.png",optimize=True)
    print(f"Rendered sideways fall atlas {idx:02d}",flush=True)
