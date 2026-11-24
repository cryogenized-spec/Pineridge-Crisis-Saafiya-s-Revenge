"""Render a second 3D fall direction from the approved VTK adult crowd mesh."""
import math
from pathlib import Path
import numpy as np
import vtk
from PIL import Image
original=Path(__file__).with_name("render_crowd.py")
source=original.read_text()
namespace={"__file__":str(original)}
exec(compile(source.split("manifest=[];review=")[0],str(original),"exec"),namespace)
root=Path(__file__).resolve().parents[1]
out=root/"assets"/"characters"/"crowd"
out.mkdir(parents=True,exist_ok=True)
body=namespace["body"]
capture=namespace["capture"]
cam=namespace["cam"]
actors=namespace["actors"]
for idx in range(12):
    atlas=Image.new("RGBA",(512,256),(0,0,0,0))
    for frame in range(8):
        fraction=frame/7.0
        ease=fraction*fraction*(3-2*fraction)
        cam.SetParallelScale(.65+.45*ease)
        cam.SetFocalPoint(0,.22*ease,.88)
        body(idx,"idle",0)
        angle=math.radians(-74*ease)
        rot=np.array([[1.,0.,0.],[0.,math.cos(angle),-math.sin(angle)],[0.,math.sin(angle),math.cos(angle)]])
        pivot=np.array([0.,0.,.55])
        offset=pivot-rot@pivot+np.array([0.,0.,-.35*ease])
        matrix=vtk.vtkMatrix4x4()
        for row in range(3):
            for col in range(3):
                matrix.SetElement(row,col,float(rot[row,col]))
            matrix.SetElement(row,3,float(offset[row]))
        matrix.SetElement(3,3,1)
        for actor in actors:
            actor.SetUserMatrix(matrix if actor.GetVisibility() else None)
        atlas.paste(capture(),((frame%4)*128,(frame//4)*128))
    atlas.save(out/f"npc_{idx:02d}_down_back.png", optimize=True)
    print("Alternate collapse",idx,flush=True)
