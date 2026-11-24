import math,json
from pathlib import Path
import vtk,numpy as np
from vtk.util.numpy_support import vtk_to_numpy
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/characters/crowd';OUT.mkdir(parents=True,exist_ok=True)
# name, complexion, top, trousers, jacket, long trousers, headwear, hair, build
ROSTER=[('Sand tee / shorts','8c583b','c9a174','3b4d68',0,0,'none','short',1.04),('Teal jacket / jeans','69432e','537775','344358',1,1,'beanie','curl',.91),('Cream vest / shorts','965b3c','e1d8bd','657e86',0,0,'cap','short',1.12),('Denim / chinos','b17a55','62728c','625b50',1,1,'none','bun',.92),('Burgundy tee / shorts','704431','873f4b','514c54',0,0,'beanie','short',1),('Ochre jacket / jeans','946044','aa8150','3c455a',1,1,'cap','pony',.95),('Blue tee / shorts','805038','65878d','93856d',0,0,'band','curl',1.06),('Plum track jacket','c48b65','7b5270','45424c',1,1,'none','curl',.94),('Olive tee / shorts','9f6948','6c6f47','474f61',0,0,'none','pony',.91),('Navy windbreaker','784c35','4c5d78','7a7464',1,1,'band','short',1.07),('Coral tee / jeans','9b6444','b76e55','41485e',0,1,'beanie','bun',.96),('Sage jacket / shorts','89573f','777c75','615b64',1,0,'none','short',1)]
def rgb(h):return tuple(int(h[i:i+2],16)/255 for i in (0,2,4))
def tone(c,t):return tuple(min(1,max(0,x*t)) for x in c)
ren=vtk.vtkRenderer();ren.SetBackground(0,0,0);ren.SetBackgroundAlpha(0);ren.AutomaticLightCreationOff()
win=vtk.vtkRenderWindow();win.SetOffScreenRendering(1);win.SetAlphaBitPlanes(1);win.SetMultiSamples(0);win.SetSize(160,160);win.AddRenderer(ren)
cam=ren.GetActiveCamera();cam.ParallelProjectionOn();cam.SetParallelScale(.65);cam.SetFocalPoint(0,0,.87);cam.SetPosition(0,0,5);cam.SetViewUp(0,1,0)
for pos,power in [((-3,-4,6),.8),((4,2,5),.40),((0,4,2),.17)]:
 l=vtk.vtkLight();l.SetLightTypeToSceneLight();l.SetPosition(*pos);l.SetFocalPoint(0,0,1);l.SetIntensity(power);ren.AddLight(l)
sphere=vtk.vtkSphereSource();sphere.SetRadius(1);sphere.SetThetaResolution(24);sphere.SetPhiResolution(16);mapper=vtk.vtkPolyDataMapper();mapper.SetInputConnection(sphere.GetOutputPort());actors=[];cursor=0
def ell(p,s,c,angle=0):
 global cursor
 if cursor==len(actors):
  a=vtk.vtkActor();a.SetMapper(mapper);ren.AddActor(a);actors.append(a)
 a=actors[cursor];cursor+=1;a.SetVisibility(1);a.SetPosition(*p);a.SetScale(*s);a.SetOrientation(0,0,angle);pr=a.GetProperty();pr.SetColor(*c);pr.SetAmbient(.28);pr.SetDiffuse(.72);pr.SetSpecular(.11);pr.SetSpecularPower(22);return a
def seg(a,b,r,c):
 a=np.array(a);b=np.array(b);v=b-a;L=np.linalg.norm(v);o=ell((a+b)/2,(r,r,L/2+r*.35),c);z=v/max(L,1e-8);ax=np.cross([0,0,1],z)
 if np.linalg.norm(ax)>1e-8:o.RotateWXYZ(math.degrees(math.acos(np.clip(z[2],-1,1))),*ax)
 elif z[2]<0:o.RotateX(180)
def body(idx,state,phase):
 global cursor
 cursor=0
 name,sk,sh,pa,jacket,longs,hat,hair,b=ROSTER[idx];sk=rgb(sk);sh=rgb(sh);pa=rgb(pa);hc=rgb('29232a');shoe=rgb('30343b');run=state=='run';m=state!='idle';s=(.30 if run else .17)*m;t=phase*math.tau;lean=.09 if run else .015;bob=(.025 if run else .012)*m*(1-math.cos(2*t));hz=.86+bob
 for side in [-1,1]:
  q=t+(math.pi if side>0 else 0);dy=math.sin(q)*s;lift=max(0,math.cos(q))*(.12 if run else .05)*m;hip=(side*.102*b,0,hz);k=(side*.105*b,dy*.42-.035,.46+lift*.35);ank=(side*.108*b,dy,.10+lift)
  seg(hip,k,.084*b,pa);seg(k,ank,.052*b,pa if longs else sk);slop=not longs and idx%3==0
  ell((ank[0],ank[1]-.065,ank[2]-.059),(.064,.127,.019),rgb('504a47') if slop else rgb('a39d94'));ell((ank[0],ank[1]-.065,ank[2]-.028),(.063,.126,.045),sk if slop else shoe)
  if slop:ell((ank[0],ank[1]-.06,ank[2]+.008),(.067,.035,.017),shoe)
  else:
   for j in range(3):ell((ank[0],ank[1]-.027-j*.023,ank[2]+.012),(.036,.009,.012),tone(shoe,1.8))
 ell((0,0,hz),(.18*b,.116,.14),pa);ell((0,-lean*.35,1.01+bob),(.166*b,.104,.22),sh);ell((0,-lean,1.28+bob),(.219*b,.125,.236),sh);ell((0,-lean,1.46+bob),(.076,.068,.073),tone(sh,.65));ell((0,-lean,1.49+bob),(.060,.055,.084),sk)
 if jacket:ell((0,-lean-.124,1.23+bob),(.012,.008,.19),tone(sh,.55));ell((0,-lean-.128,1.33+bob),(.009,.012,.022),rgb('989395'))
 for side in [-1,1]:
  q=t+(math.pi if side<0 else 0);d=math.sin(q)*s*.65;shoulder=(side*.204*b,-lean,1.40+bob);elbow=(side*.253*b,d-.02,1.14+bob);hand=(side*.261*b,d-(.16 if run else .035),.96+bob+(.14 if run else 0));seg(shoulder,elbow,.069,sh if jacket else sk);seg(shoulder,(np.array(shoulder)+np.array(elbow))/2,.081,sh);seg(elbow,hand,.050,sh if jacket else sk);ell(hand,(.043,.05,.063),sk)
 h=1.63+bob;y=-lean-.025;ell((0,y,h),(.094,.101,.121),sk);ell((0,y+.014,h+.035),(.098,.102,.100),hc)
 for side in [-1,1]:ell((side*.093,y,h-.008),(.022,.035,.042),sk)
 ell((0,y-.10,h-.017),(.023,.026,.030),sk)
 if hair=='curl':
  for j in range(14):
   a=j*2.399;r=.075*math.sqrt((j+1)/14);ell((math.cos(a)*r,y+math.sin(a)*r,h+.092),(.036,.036,.029),tone(hc,1.05+(j%3)*.09))
 if hair=='bun':ell((0,y+.093,h+.063),(.068,.069,.066),hc)
 if hair=='pony':ell((0,y+.125,h-.025),(.051,.071,.105),hc,-math.sin(t)*8)
 if hat=='beanie':ell((.016,y+.018,h+.058),(.108,.113,.080),rgb('42434d'),-18)
 if hat=='cap':ell((0,y,h+.062),(.107,.111,.080),rgb('565b60'));ell((0,y-.125,h+.025),(.106,.074,.018),rgb('565b60'))
 if hat=='band':ell((0,y,h+.025),(.099,.104,.027),rgb('a99570'))
 for a in actors[cursor:]:a.SetVisibility(0)
def capture():
 win.Render();w=vtk.vtkWindowToImageFilter();w.SetInput(win);w.SetInputBufferTypeToRGBA();w.ReadFrontBufferOff();w.Update();a=vtk_to_numpy(w.GetOutput().GetPointData().GetScalars()).reshape(160,160,4)[::-1];return Image.fromarray(a.copy()).resize((128,128),Image.Resampling.LANCZOS)
manifest=[];review=Image.new('RGB',(1000,720),'#272b34');d=ImageDraw.Draw(review);d.text((20,15),'PINE RIDGE / CROWD V13 — CODE-RENDERED 3D',fill='#e8e4db',font=ImageFont.truetype('DejaVuSans.ttf',24));font=ImageFont.truetype('DejaVuSans.ttf',14)
for idx,r in enumerate(ROSTER):
 for state in ('idle','walk','run'):
  n=1 if state=='idle' else 8;atlas=Image.new('RGBA',(128 if n==1 else 512,128 if n==1 else 256));ims=[]
  for i in range(n):
   body(idx,state,i/n);im=capture();atlas.paste(im,((i%4)*128,(i//4)*128));ims.append(im)
  atlas.save(OUT/f'npc_{idx:02d}_{state}.png')
  if state=='run':
   if idx==0:ims[0].save(ROOT/'running_preview.gif',save_all=True,append_images=ims[1:],duration=80,loop=0,disposal=2)
   x=12+idx%4*247;y=55+idx//4*218;d.rounded_rectangle((x,y,x+236,y+206),radius=7,fill='#363b45');review.paste(ims[2],(x+54,y+20),ims[2]);d.text((x+12,y+158),f'{idx+1:02d}  {r[0]}',fill='#e8e4db',font=font)
 manifest.append({'id':idx,'name':r[0],'cell':[128,128],'pivot':[64,64],'orientation':'south','walk_frames':8,'run_frames':8,'idle_frames':1});print('Rendered',idx,flush=True)
review.save(ROOT/'crowd_review.png');(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2));print('DONE',flush=True)
# Independent everyday accessory textures. Render on transparent backgrounds.
prop_dir=ROOT/'assets/characters/accessories';prop_dir.mkdir(parents=True,exist_ok=True)
cam.SetParallelScale(.24)
for name in ('backpack','parcel','phone'):
 cursor=0
 if name=='backpack':
  ell((0,0,.10),(.119,.153,.075),rgb('4a5057'));ell((0,-.04,.15),(.095,.075,.032),rgb('626971'));ell((0,.13,.11),(.04,.025,.025),rgb('242931'))
  for x in [-.09,.09]:ell((x,.03,.09),(.015,.14,.025),rgb('333842'))
 elif name=='parcel':
  ell((0,0,.08),(.14,.11,.075),rgb('a88b60'));ell((0,0,.14),(.027,.107,.008),rgb('d5bd92'))
 else:
  ell((0,0,.04),(.063,.115,.018),rgb('242830'));ell((0,0,.056),(.052,.099,.008),rgb('626e7c'))
 for a in actors[cursor:]:a.SetVisibility(0)
 capture().save(prop_dir/f'{name}.png')