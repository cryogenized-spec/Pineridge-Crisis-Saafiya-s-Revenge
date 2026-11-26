"""Render original orthographic Pineridge scenery with VTK, NumPy and Pillow."""
from collections import defaultdict
from math import cos, pi, sin
from pathlib import Path
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import vtk
from vtk.util.numpy_support import vtk_to_numpy

ROOT = Path(__file__).resolve().parents[1] / "assets"
LIGHT_SLOPE = np.array((.48, -.39))
ELEVATION = 67 * pi / 180
VIEW_NORMAL = np.array((0, -cos(ELEVATION), sin(ELEVATION)))
VIEW_UP = np.array((0, sin(ELEVATION), cos(ELEVATION)))
SCALE = 2


def tint(hex_color, brightness):
    return tuple(min(1, int(hex_color[i:i + 2], 16) / 255 * brightness)
                 for i in (0, 2, 4))


class Stage:
    def __init__(self):
        self.renderer = vtk.vtkRenderer()
        self.renderer.SetBackgroundAlpha(0)
        self.renderer.AutomaticLightCreationOff()
        self.window = vtk.vtkRenderWindow()
        self.window.SetOffScreenRendering(1)
        self.window.SetAlphaBitPlanes(1)
        self.window.SetMultiSamples(0)
        self.window.AddRenderer(self.renderer)
        for location, intensity, color in [
            ((-4, 5, 8), .96, (1, .92, .80)),
            ((4, -4, 6), .38, (.74, .87, 1)),
            ((0, 7, 2), .16, (1, .97, .91)),
        ]:
            light = vtk.vtkLight()
            light.SetLightTypeToSceneLight()
            light.SetPosition(*location)
            light.SetFocalPoint(0, 0, .4)
            light.SetIntensity(intensity)
            light.SetColor(*color)
            self.renderer.AddLight(light)
        self.camera = self.renderer.GetActiveCamera()
        self.camera.ParallelProjectionOn()
        self.camera.SetViewUp(*VIEW_UP)

    def render(self, model, size, view_width, filename, focal_z=0, heading=0):
        width, height = (pixels * SCALE for pixels in size)
        self.window.SetSize(width, height)
        focal = np.array((0, 0, focal_z))
        self.camera.SetPosition(*(focal + VIEW_NORMAL * 25))
        self.camera.SetFocalPoint(*focal)
        self.camera.SetParallelScale(view_width * height / width / 2)
        for (color, gloss, smooth), mesh in model.meshes.items():
            mesh.Update()
            normals = vtk.vtkPolyDataNormals()
            normals.SetInputConnection(mesh.GetOutputPort())
            normals.SetComputePointNormals(smooth)
            normals.SetComputeCellNormals(True)
            normals.SetConsistency(True)
            normals.SetAutoOrientNormals(True)
            mapper = vtk.vtkPolyDataMapper()
            mapper.SetInputConnection(normals.GetOutputPort())
            actor = vtk.vtkActor()
            actor.SetMapper(mapper)
            actor.SetOrientation(0, 0, heading)
            prop = actor.GetProperty()
            prop.SetColor(*color)
            prop.SetAmbient(.35)
            prop.SetDiffuse(.67)
            prop.SetSpecular(gloss)
            prop.SetSpecularPower(30)
            if not smooth:
                prop.SetInterpolationToFlat()
            self.renderer.AddActor(actor)
        self.renderer.ResetCameraClippingRange()
        self.window.Render()
        pixels = vtk.vtkWindowToImageFilter()
        pixels.SetInput(self.window)
        pixels.SetInputBufferTypeToRGBA()
        pixels.ReadFrontBufferOff()
        pixels.Update()
        rgba = vtk_to_numpy(pixels.GetOutput().GetPointData().GetScalars())
        objects = Image.fromarray(rgba.reshape(height, width, 4)[::-1].copy())
        shadows = Image.new("RGBA", objects.size)
        rotation = heading * pi / 180
        for length, depth, elevation, density in model.shadows:
            mask = Image.new("L", objects.size)
            draw = ImageDraw.Draw(mask)
            polygon = []
            for x, y in [(-length/2, -depth/2), (length/2, -depth/2),
                         (length/2, depth/2), (-length/2, depth/2)]:
                ground = np.array((x*cos(rotation) - y*sin(rotation),
                                   x*sin(rotation) + y*cos(rotation)))
                ground += LIGHT_SLOPE * elevation
                screen_y = np.dot((*ground, -focal_z), VIEW_UP)
                polygon.append((width/2 + ground[0]*width/view_width,
                                height/2 - screen_y*width/view_width))
            draw.polygon(polygon, fill=density)
            shade = Image.new("RGBA", objects.size, (25, 25, 30, 0))
            shade.putalpha(mask.filter(ImageFilter.GaussianBlur(max(1, width/view_width*.07))))
            shadows.alpha_composite(shade)
        # Fade contact shadows before the texture edge. The object render still
        # uses the full camera frame and remains independently registered.
        horizontal = np.minimum(np.arange(width), np.arange(width)[::-1])
        vertical = np.minimum(np.arange(height), np.arange(height)[::-1])
        distance = np.minimum(vertical[:, None], horizontal)
        fade = np.clip(distance / max(2, width / view_width * .14), 0, 1)
        alpha = np.asarray(shadows.getchannel("A"), dtype=float)
        shadows.putalpha(Image.fromarray((alpha*fade*fade*(3-2*fade)).astype(np.uint8)))
        shadows.alpha_composite(objects)
        dest = ROOT / filename
        dest.parent.mkdir(parents=True, exist_ok=True)
        shadows.resize(size, Image.Resampling.LANCZOS).save(dest, optimize=True)
        self.renderer.RemoveAllViewProps()


class Model:
    def __init__(self):
        self.meshes = defaultdict(vtk.vtkAppendPolyData)
        self.shadows = []

    def add(self, source, color, gloss=0, smooth=False):
        rgb = tint(color, 1) if isinstance(color, str) else color
        self.meshes[(rgb, gloss, smooth)].AddInputData(source)

    def mesh(self, vertices, faces, color, gloss=0):
        points = vtk.vtkPoints()
        for point in vertices:
            points.InsertNextPoint(*point)
        cells = vtk.vtkCellArray()
        for face in faces:
            cells.InsertNextCell(len(face))
            for index in face:
                cells.InsertCellPoint(index)
        mesh = vtk.vtkPolyData()
        mesh.SetPoints(points)
        mesh.SetPolys(cells)
        self.add(mesh, color, gloss)

    def quad(self, vertices, color, gloss=0):
        self.mesh(vertices, [(0, 1, 2, 3)], color, gloss)

    def box(self, center, size, color, gloss=0):
        cube = vtk.vtkCubeSource()
        cube.SetCenter(*center)
        cube.SetXLength(size[0])
        cube.SetYLength(size[1])
        cube.SetZLength(size[2])
        cube.Update()
        self.add(cube.GetOutput(), color, gloss)

    def ellipsoid(self, center, radii, color):
        sphere = vtk.vtkSphereSource()
        sphere.SetThetaResolution(12)
        sphere.SetPhiResolution(8)
        transform = vtk.vtkTransform()
        transform.Translate(*center)
        transform.Scale(*radii)
        shape = vtk.vtkTransformPolyDataFilter()
        shape.SetTransform(transform)
        shape.SetInputConnection(sphere.GetOutputPort())
        sphere.SetRadius(1)
        shape.Update()
        self.add(shape.GetOutput(), color, smooth=True)

    def tube(self, start, end, radius, color, gloss=0, sides=24):
        line = vtk.vtkLineSource()
        line.SetPoint1(*start)
        line.SetPoint2(*end)
        cylinder = vtk.vtkTubeFilter()
        cylinder.SetInputConnection(line.GetOutputPort())
        cylinder.SetRadius(radius)
        cylinder.SetNumberOfSides(sides)
        cylinder.CappingOn()
        cylinder.Update()
        self.add(cylinder.GetOutput(), color, gloss, True)

    def shell(self, rings, color, gloss=0):
        count = len(rings[0])
        faces = [tuple(reversed(range(count)))]
        for start in range(0, (len(rings) - 1)*count, count):
            for j in range(count):
                after = (j + 1) % count
                faces.append((start+j, start+after, start+after+count, start+j+count))
        faces.append(tuple(range((len(rings)-1)*count, len(rings)*count)))
        self.mesh([vertex for ring in rings for vertex in ring], faces, color, gloss)


def car(style, paint):
    model = Model()
    dark = "232a2f"
    glass = "405965"
    bright_glass = "6a8590"
    chrome = "9a9b92"
    length = 2.2 if style != "hatchback" else 2.08
    hood = .83 if style in ("utility", "security") else .67
    shoulder = .74 if style in ("utility", "security") else .63
    width = .91 if style in ("utility", "security") else .86
    model.shadows += [(4.3, 1.76, .08, 118), (4.05, 1.6, .52, 53)]
    rings = []
    for x, w, z in [
        (-length, width*.79, shoulder-.082), (-length+.075, width*.91, shoulder-.018),
        (-length+.24, width, shoulder), (-1.35, width, shoulder+.017),
        (.58, width, shoulder+.025), (length-.34, width*.98, hood-.021),
        (length-.095, width*.93, hood-.052), (length, width*.79, hood-.10),
    ]:
        rings.append([(x, y, h) for y, h in [
            (-w*.86, .23), (-w, .32), (-w, z-.10), (-w*.88, z),
            (w*.88, z), (w, z-.10), (w, .32), (w*.86, .23),
        ]])
    model.shell(rings, paint, .54)
    model.box((0, 0, .24), (3.92, 1.28, .19), dark)
    for axle in (-1.37, 1.38):
        for side in (-1, 1):
            wheel_y = side * width
            model.tube((axle, wheel_y-.14, .28), (axle, wheel_y+.14, .28), .28, "24252a")
            model.tube((axle, wheel_y+.141*side, .28),
                       (axle, wheel_y+.161*side, .28), .17, chrome, .25)
            model.tube((axle, wheel_y+.161*side, .28),
                       (axle, wheel_y+.176*side, .28), .056, dark)
            for spoke in range(5):
                angle = spoke * 2*pi/5
                model.tube((axle, wheel_y + .168*side, .28),
                           (axle + cos(angle)*.13, wheel_y+.168*side, .28 + sin(angle)*.13),
                           .018, "cdccc3", .1, 8)
    if style in ("utility", "security"):
        rear, back_top, cabin_height = -.84, -.71, 1.44
    elif style == "hatchback":
        rear, back_top, cabin_height = -1.97, -1.62, 1.35
    else:
        rear, back_top, cabin_height = -1.48, -.93, 1.29
    front, front_top = 1.15, .48
    base = shoulder+.038
    glass_width = width*.87
    top_width = width*.70
    rings = [
        [(rear, -glass_width, base), (rear, glass_width, base),
         (front, glass_width, base), (front, -glass_width, base)],
        [(back_top, -top_width, cabin_height), (back_top, top_width, cabin_height),
         (front_top, top_width, cabin_height), (front_top, -top_width, cabin_height)],
    ]
    model.shell(rings, glass, .45)
    for edge, roof_edge, hue, facing in [(rear, back_top, glass, -1), (front, front_top, bright_glass, 1)]:
        def glass_point(height, across):
            return (edge + (roof_edge-edge)*height + .012*facing,
                    across*(glass_width + (top_width-glass_width)*height),
                    base+(cabin_height-base)*height)
        for row in range(9):
            start = row/9
            end = (row+1)/9
            gloss = .72 + .38 * sin(pi * (row+1)/10)
            model.quad([glass_point(start, -.91), glass_point(start, .91),
                        glass_point(end, .91), glass_point(end, -.91)],
                       tint(hue, gloss), .56)
    model.shell([
        [(back_top-.035, -top_width, cabin_height),
         (back_top-.035, top_width, cabin_height), (front_top+.04, top_width, cabin_height),
         (front_top+.04, -top_width, cabin_height)],
        [(back_top+.06, -top_width*.94, cabin_height+.045),
         (back_top+.06, top_width*.94, cabin_height+.045),
         (front_top-.04, top_width*.94, cabin_height+.045),
         (front_top-.04, -top_width*.94, cabin_height+.045)],
    ], paint, .52)
    for side in (-1, 1):
        lower, upper = side*glass_width, side*top_width
        model.tube((rear, lower, base+.01), (front, lower, base+.01), .034, dark, sides=10)
        model.tube((rear, lower, base), (back_top, upper, cabin_height), .04, paint, sides=10)
        model.tube((front, lower, base), (front_top, upper, cabin_height), .041, paint, sides=10)
        model.tube(((rear+front)*.5, lower, base), ((back_top+front_top)*.5, upper, cabin_height),
                   .035, dark, sides=10)
        model.box((.48, side*(width+.055), base), (.19, .19, .09), paint, .26)
        model.box((-.12, side*width*.994, shoulder-.115), (.16, .029, .04), chrome, .22)
        model.tube((-1.82, side*width, .43), (1.93, side*width, .43), .018, dark, sides=8)
        model.box((length-.077, side*width*.67, hood-.17), (.19, .32, .092), "ede2bc", .4)
        model.box((-length+.05, side*width*.64, shoulder-.16), (.15, .37, .11), "a33837", .3)
        bonnet_z = shoulder + .025 + (hood - shoulder - .046) * (1.23 - .58) / (length - .34 - .58)
        model.quad([(1.23, side*.49-.01, bonnet_z+.012), (1.23, side*.49+.01, bonnet_z+.012),
                    (length-.34, side*.53+.01, hood-.009), (length-.34, side*.53-.01, hood-.009)],
                   tint(paint, 1.10), .24)
    model.box((length+.015, 0, .41), (.09, 1.47, .13), dark)
    model.box((-length-.015, 0, .35), (.10, 1.45, .10), dark)
    model.box((-length-.07, 0, .42), (.023, .41, .085), "dfdac4")
    model.box((length+.07, 0, .39), (.022, .39, .073), "e0dccc")
    if style in ("utility", "security"):
        model.box((-1.43, 0, shoulder+.03), (1.19, 1.31, .10), "333b3d")
        for rib in range(7):
            model.box((-1.44, (rib-3)*.17, shoulder+.09), (1.12, .036, .025), "55605e")
        for y in [-.76, .76]:
            model.box((-1.45, y, shoulder+.12), (1.25, .11, .13), paint)
    if style == "security":
        model.box((-.08, 0, cabin_height+.086), (.25, 1.17, .084), dark)
        for y, color in [(-.41, "426d95"), (.41, "ad7352")]:
            model.box((-.08, y, cabin_height+.14), (.22, .30, .072), color, .4)
    return model


def house(roof_color, stucco, wide=False, shutters=False):
    model = Model()
    w, d = (7.9, 3.6) if wide else (7.5, 4.10)
    eave, ridge = 1.60, 2.65
    model.shadows += [(w-.18, d-.25, .06, 106), (w, d, 1.4, 70)]
    model.box((0, 0, .09), (w-.27, d-.13, .18), "65635c")
    model.box((0, 0, .86), (w-.52, d-.44, 1.52), stucco)
    # Eaves, gutters and tiled gables. Each row overlaps the row below it.
    for side in (-1, 1):
        edge_y = side*d*.5
        model.quad([(-w*.5, edge_y, eave), (w*.5, edge_y, eave),
                    (w*.5, 0, ridge), (-w*.5, 0, ridge)], tint(roof_color, .71))
        model.tube((-w*.5, edge_y, eave-.012), (w*.5, edge_y, eave-.012), .055, "525353", sides=10)
    for side in (-1, 1):
        x = side*(w/2-.26)
        model.mesh([(x, -d*.5+.18, eave), (x, d*.5-.18, eave), (x, 0, ridge)],
                   [(0, 1, 2)], stucco)
    rng = random.Random(736)
    rows, cols = 11, 38
    for side in (-1, 1):
        for row in range(rows):
            step_y = d/2/rows
            low = row*step_y
            high = (row+1)*step_y + .014
            for col in range(cols+1):
                step_x = w/cols
                start = max(0, (col - .5*(row%2))*step_x) - w*.5
                stop = min(w, (col+1 - .5*(row%2))*step_x) - w*.5 - .012
                if stop <= start:
                    continue
                start_z = ridge - low/(d*.5)*(ridge-eave) + .014
                stop_z = ridge - high/(d*.5)*(ridge-eave) + .03
                color = tint(roof_color, rng.uniform(.89, 1.075))
                model.quad([(start, side*low, start_z), (stop, side*low, start_z),
                            (stop, side*high, stop_z), (start, side*high, stop_z)], color)
    model.tube((-w/2, 0, ridge+.033), (w/2, 0, ridge+.033), .064, roof_color, sides=12)
    for x in (-w*.31, w*.29):
        y = -d/2+.214
        model.box((x, y, .94), (1.18, .08, .72), "42454a")
        model.box((x, y-.055, .94), (1.04, .045, .56), "8e948c" if shutters else "5b7780")
        for bar in range(4 if shutters else 2):
            model.box((x-.42+bar*(.28 if shutters else .84), y-.082, .94),
                      (.05, .035, .60), "bbb4a0")
        model.box((x, y-.11, .60), (1.24, .17, .08), "b2a18a")
    y = -d/2+.18
    model.box((0, y, .66), (.85, .10, 1.25), "55463e")
    model.box((0, y-.18, .07), (1.15, .45, .14), "827c6f")
    model.box((-.83, .65, 2.42), (.29, .37, .84), "786f66")
    model.box((-.83, .65, 2.84), (.42, .51, .13), "51484c")
    return model


def shop(awning):
    model = Model()
    model.shadows += [(8, 3.1, .05, 109), (8, 3.1, 1.25, 72)]
    model.box((0, 0, .79), (8.15, 3.0, 1.58), "a39986")
    model.box((0, 0, 1.60), (8.23, 3.10, .12), "474e56")
    for i in range(21):
        model.box(((i-10)*.381, 0, 1.67), (.37, 2.78, .04),
                  tint("636b71", (.95, .90, .99, 1.01)[i%4]))
    for y in [-1.51, 1.51]:
        model.box((0, y, 1.70), (8.26, .13, .17), "aaa390")
    for i in range(6):
        x = (i-2.5)*1.29
        model.box((x, -1.53, .82), (1.12, .081, 1.21), "434d54")
        model.box((x, -1.58, .85), (1.02, .04, 1.06), "577480", .35)
        model.box((x, -1.615, .43), (.96, .032, .14), "90836b")
    model.box((0, -1.60, 1.46), (8.20, .20, .17), awning)
    for i in range(21):
        x = (i-10)*.38
        model.quad([(x-.19, -1.59, 1.43), (x+.19, -1.59, 1.43),
                    (x+.19, -2.10, 1.10), (x-.19, -2.10, 1.10)],
                   awning if i%2 else tint(awning, 1.23))
    for x in [-2.3, 1.8]:
        model.box((x, .53, 1.80), (1.26, .74, .20), "777d7e")
        for rib in range(5):
            model.box((x, .53+(rib-2)*.10, 1.91), (1.06, .025, .033), "444b54")
    return model


def roadside(kind):
    model = Model()
    if kind in ("fence", "gate"):
        model.shadows.append((2.8, .14, .48, 72))
        for x in [-1.37, 1.37]:
            model.box((x, 0, .40), (.10, .13, .80), "acaa9c")
            model.box((x, 0, .79), (.14, .16, .085), "c3b9a4")
        metal = "63726a" if kind == "gate" else "a4a398"
        for z in [.18, .61]:
            model.box((0, 0, z), (2.68, .05, .048), metal)
        for i in range(13):
            x = (i-6)*.207
            model.box((x, 0, .42), (.037, .05, .64), metal)
        if kind == "gate":
            for x in [-.66, .66]:
                model.tube((x-.60, -.035, .19), (x+.60, -.035, .61), .025, metal, sides=8)
    elif kind == "gate_open":
        for side in [-1, 1]:
            hinge = np.array((side*1.31, 0))
            leaf = np.array((side*.94, .99))
            model.box((*hinge, .40), (.15, .15, .80), "a8a597")
            model.box((*hinge, .80), (.19, .19, .07), "c3b9a4")
            for z in [.18, .62]:
                model.tube((*hinge, z), (*leaf, z), .035, "63726a", sides=8)
            for step in range(1, 7):
                base = hinge + (leaf-hinge)*step/6
                model.box((*base, .41), (.042, .042, .59), "829084")
    elif kind in ("curb", "wall"):
        height = .25 if kind == "curb" else .80
        model.shadows.append((3.2, .23, height*.7, 69))
        for i in range(8):
            x = (i-3.5)*.39
            shade = (.92, 1.01, .97, .95)[i%4]
            model.box((x, 0, height*.47), (.378, .30, height*.94), tint("a7a293", shade))
            model.box((x, 0, height*.974), (.386, .34, height*.10), tint("c7bdab", shade))
    elif kind == "parking":
        model.box((0, 0, .035), (6.6, 1.9, .07), "77796f")
        for step in range(4):
            x = (step-1.5)*1.61
            model.box((x, 0, .074), (.035, 1.65, .016), "bdb7a5")
        for x in [-3.15, 3.15]:
            for y in [-.83, .83]:
                model.box((x, y, .35), (.11, .11, .7), "5b6461")
                model.box((x, y, .70), (.18, .18, .09), "b0ada2")
        for y in [-.83, .83]:
            model.box((0, y, .66), (6.35, .068, .084), "93978e")
        for x in [-3.15, -.9, .9, 3.15]:
            model.box((x, 0, .66), (.067, 1.67, .073), "88928d")
    elif kind == "bin":
        model.shadows.append((.64, .59, .43, 99))
        model.shell([
            [(-.26, -.22, .085), (.26, -.22, .085), (.26, .22, .085), (-.26, .22, .085)],
            [(-.34, -.30, .69), (.34, -.30, .69), (.34, .30, .69), (-.34, .30, .69)],
        ], "425f55", .18)
        model.box((0, 0, .72), (.72, .64, .10), "293d38", .18)
        for x in [-.21, 0, .21]:
            model.box((x, 0, .772), (.05, .47, .013), "4a5c51")
        model.tube((-.34, .28, .09), (-.24, .28, .09), .09, "262b2a")
        model.tube((.24, .28, .09), (.34, .28, .09), .09, "262b2a")
    elif kind == "crate":
        model.shadows.append((.64, .53, .28, 93))
        model.box((0, 0, .20), (.65, .55, .40), "725347")
        for i in range(6):
            model.box(((i-2.5)*.106, 0, .407), (.10, .56, .033), tint("a48765", .89+.05*(i%3)))
        for y in [-.20, .20]:
            model.box((0, y, .43), (.66, .062, .035), "c0a180")
    return model


def shrub(color, seed):
    rng = random.Random(seed)
    model = Model()
    model.shadows += [(.66, .61, .05, 96), (.61, .61, .40, 61)]
    model.ellipsoid((0, 0, .22), (.35, .32, .24), tint(color, .72))
    for index in range(19):
        angle = index * 2.399
        radius = .29 * (index / 19)**.5
        size = rng.uniform(.085, .15)
        z = .44 - radius*.70 + rng.uniform(-.025, .04)
        model.ellipsoid((radius*cos(angle), radius*sin(angle), z), (size, size, size*.76),
                        tint(color, rng.uniform(.76, 1.14)))
    return model


def asphalt_grain():
    rng = random.Random(827)
    tile = Image.new("RGBA", (192, 192))
    pixels = []
    for _ in range(192*192):
        level = rng.random()
        color = (32, 28, 31) if level < .57 else (185, 168, 153)
        pixels.append((*color, rng.randrange(3, 24) if level < .87 else rng.randrange(23, 46)))
    tile.putdata(pixels)
    tile.save(ROOT / "environment/roadside/asphalt_grain.png", optimize=True)


def held(kind):
    model = Model()
    if kind == "slingshot_icon":
        amber, walnut = "c39a6c", "7d5038"
        model.tube((0, -.41, .14), (0, -.01, .17), .083, walnut)
        for x in [-1, 1]:
            model.tube((0, -.11, .16), (x*.18, .12, .19), .072, walnut)
            model.tube((x*.18, .12, .19), (x*.24, .39, .22), .062, amber)
            model.tube((x*.24, .39, .23), (x*.059, .16, .24), .029, "bd8745")
        model.box((0, .16, .24), (.14, .078, .036), "493930")
        for i in range(5):
            y = -.39+i*.034
            model.tube((-.075, y, .172), (.075, y, .172), .019, "3e3732")
    elif kind == "club_icon":
        model.tube((0, -.45, .13), (0, .09, .15), .068, "76533b")
        model.tube((0, .03, .15), (.045, .40, .17), .11, "aa7951")
        for i in range(5):
            model.tube((-.065, -.40+i*.043, .17), (.064, -.40+i*.043, .17), .017, "443a35")
    elif kind == "brick":
        model.shell([
            [(-.35, -.19, .025), (.35, -.19, .025), (.35, .19, .025), (-.35, .19, .025)],
            [(-.35, -.19, .15), (.35, -.19, .15), (.35, .19, .15), (-.35, .19, .15)],
            [(-.31, -.15, .19), (.31, -.15, .19), (.31, .15, .19), (-.31, .15, .19)],
        ], "a46851")
        for x in [-.18, 0, .18]:
            model.box((x, 0, .194), (.082, .105, .006), "563e35")
    return model


if __name__ == "__main__":
    stage = Stage()
    for ident, model, color in [
        ("sedan_silver", "sedan", "9babb0"),
        ("sedan_ochre", "sedan", "ae8c74"),
        ("hatchback_russet", "hatchback", "a96354"),
        ("hatchback_sage", "hatchback", "748b7c"),
        ("utility_ivory", "utility", "cec7ad"),
        ("security", "security", "a4aeaa"),
        ("saafiya_car", "sedan", "725055"),
    ]:
        car_model = car(model, color)
        for direction, angle in [("east", 0), ("west", 180)]:
            stage.render(car_model, (288, 136), 5.74,
                         f"environment/vehicles/{ident}_{direction}.png", focal_z=.48, heading=angle)
    for ident, roof, wall, wide, shutters in [
        ("house_terracotta", "9a7366", "bbb29e", False, False),
        ("house_slate", "727d83", "a7a79b", False, False),
        ("house_stone", "8d8074", "b1a795", False, False),
        ("barricaded_house", "6c7882", "aba99d", True, True),
    ]:
        stage.render(house(roof, wall, wide, shutters), (512, 320), 9.1,
                     f"environment/architecture/{ident}.png", focal_z=.87)
    for name, color in [("retail_copper", "925e50"), ("retail_teal", "4e7473"), ("retail_sand", "a48258")]:
        stage.render(shop(color), (512, 274), 9.1, f"environment/architecture/{name}.png", focal_z=.68)
    for kind, size, width, z, orientation in [
        ("fence", (192, 56), 3.2, .24, 0),
        ("gate", (192, 56), 3.2, .24, 0),
        ("gate_open", (192, 110), 3.2, .23, 0),
        ("wall", (192, 62), 3.45, .25, 0),
        ("curb", (192, 36), 3.24, .12, 0),
        ("parking", (512, 184), 7.0, .32, 0),
        ("bin", (96, 96), 1.06, .31, 0),
        ("crate", (96, 96), .98, .17, 0),
    ]:
        stage.render(roadside(kind), size, width, f"environment/roadside/{kind}.png", focal_z=z, heading=orientation)
    stage.render(roadside("fence"), (66, 192), 1.02, "environment/roadside/fence_vertical.png", focal_z=.24, heading=90)
    for index, color in enumerate(("63755a", "68785a", "536c5d")):
        stage.render(shrub(color, 273+index), (96, 96), 1.04,
                     f"environment/roadside/shrub_{index}.png", focal_z=.18)
    asphalt_grain()
    for kind in ("slingshot_icon", "club_icon", "brick"):
        stage.render(held(kind), (128, 128), 1.02, f"props/rendered/{kind}.png", focal_z=.15)
