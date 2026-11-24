"""Render non-graphic, code-only 3D fall/down atlas using the approved crowd mesh."""
import sys, math
from pathlib import Path
import numpy as np
import vtk
from PIL import Image, ImageDraw
source=Path(__file__).with_name('render_crowd.py').read_text()
prefix=source.split('manifest=[];review=')[0]
ns={"__file__":str(Path(__file__).with_name('render_crowd.py'))}
exec(compile(prefix,str(Path(__file__).with_name('render_crowd.py')),'exec'),ns)
OUT=Path(__file__).resolve().parents[1]/'assets/characters/crowd'
roster=ns['ROSTER'];body=ns['body'];capture=ns['capture'];cam=ns['cam'];actors=ns['actors']
cam.SetParallelScale(.65)
review=Image.new('RGB',(768,4*180),(37,40,49))
for idx in range(12):
    atlas=Image.new('RGBA',(512,256),(0,0,0,0))
    for frame in range(8):
        frac=frame/7.0
        ease=frac*frac*(3-2*frac)
        cam.SetParallelScale(.65+.45*ease)
        cam.SetFocalPoint(0,-.35*ease,.87)
        body(idx,'idle',0)
        # Tilt from upright to horizontal; the whole mesh is transformed as 3D
        # geometry before rasterization, never by 2D rotation of a flat atlas.
        angle=math.radians(80*ease)
        R=np.array([[1.,0.,0.],[0.,math.cos(angle),-math.sin(angle)],[0.,math.sin(angle),math.cos(angle)]])
        pivot=np.array([0.,0.,.55]);z_shift=np.array([0.,0.,-.40*ease])
        shift=pivot-R@pivot+z_shift
        matrix=vtk.vtkMatrix4x4()
        for row in range(3):
            for col in range(3): matrix.SetElement(row,col,float(R[row,col]))
            matrix.SetElement(row,3,float(shift[row]))
        matrix.SetElement(3,3,1)
        for actor in actors:
            if actor.GetVisibility():
                actor.SetUserMatrix(matrix)
            else:
                actor.SetUserMatrix(None)
        im=capture()
        atlas.paste(im,((frame%4)*128,(frame//4)*128))
        if idx in (0,1,4,7):
            row=[0,1,4,7].index(idx)
            review.paste(im.resize((140,140),Image.Resampling.NEAREST),(frame*95,row*180+20),im.resize((140,140),Image.Resampling.NEAREST))
    atlas.save(OUT/f'npc_{idx:02d}_down.png',optimize=True)
    print('Render down',idx,flush=True)
review.save(Path(__file__).resolve().parents[1]/'down_pose_review.png')