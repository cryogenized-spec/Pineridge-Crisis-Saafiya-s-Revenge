"""Small mesh and orthographic renderer shared by the sprite kit sources."""
from dataclasses import dataclass
from math import cos, pi, sin
from pathlib import Path

import numpy as np
from PIL import Image
import vtk
from vtk.util.numpy_support import numpy_to_vtk, numpy_to_vtkIdTypeArray, vtk_to_numpy

ROOT = Path(__file__).resolve().parents[2]
CELL = 128
BODY_VIEW = 1.68
BODY_FOCUS = 1.0
ELEVATION = np.deg2rad(79)
MATERIALS = {
    "skin": (.15, 26),
    "fabric": (.09, 18),
    "leather": (.35, 31),
    "metal": (.63, 41),
    "hair": (.28, 28),
    "glass": (.67, 45),
}


def color(hex_code, multiplier=1.0):
    return tuple(min(1, int(hex_code[i:i+2], 16) / 255 * multiplier) for i in (0, 2, 4))


def unit(vector):
    vector = np.asarray(vector, dtype=float)
    return vector / max(np.linalg.norm(vector), 1e-8)


def polygon_rings(rings):
    columns = len(rings[0])
    faces = [tuple(reversed(range(columns)))]
    for row in range(len(rings) - 1):
        start = row * columns
        for column in range(columns):
            current = start + column
            following = start + (column + 1) % columns
            faces.append((current, following, following + columns, current + columns))
    last = (len(rings) - 1) * columns
    faces.append(tuple(range(last, last + columns)))
    return np.array(rings).reshape((-1, 3)), faces


@dataclass
class Part:
    name: str
    group: str
    tone: tuple
    finish: str
    smooth: bool
    points: np.ndarray
    faces: list
    weights: list | None = None

    def serialize(self):
        return {
            "name": self.name, "group": self.group, "tone": self.tone,
            "finish": self.finish, "smooth": self.smooth,
            "points": np.round(self.points, 5).tolist(), "faces": self.faces,
            "weights": self.weights,
        }


class Mesh:
    def __init__(self):
        self.parts = []

    def add(self, name, geometry, tone, group, finish="fabric", smooth=True):
        points, faces = geometry
        self.parts.append(Part(name, group, color(tone) if isinstance(tone, str) else tone,
                               finish, smooth, np.asarray(points, dtype=float), faces))

    def loft(self, name, slices, tone, group, finish="fabric", count=24):
        # Each section is a centered horizontal oval at (x, y, z).
        rings = [
            [(x + rx*cos(i*2*pi/count), y + ry*sin(i*2*pi/count), z)
             for i in range(count)]
            for x, y, z, rx, ry in slices
        ]
        self.add(name, polygon_rings(rings), tone, group, finish)

    def ellipsoid(self, name, at, axes, tone, group, finish="fabric", detail=14, orientation=None):
        count = detail
        latitudes = np.linspace(-pi/2 + .005, pi/2 - .005, max(7, detail//2 + 1))
        rings = [
            [(axes[0]*cos(p)*cos(i*2*pi/count), axes[1]*cos(p)*sin(i*2*pi/count),
              axes[2]*sin(p)) for i in range(count)]
            for p in latitudes
        ]
        points, faces = polygon_rings(rings)
        if orientation is not None:
            points = points @ np.asarray(orientation).T
        self.add(name, (points + at, faces), tone, group, finish)

    def sweep(self, name, stations, tone, group, finish="fabric", count=12, weights=None):
        centers = [np.array(station[0], dtype=float) for station in stations]
        rings = []
        for i, ((_, radius), center) in enumerate(zip(stations, centers)):
            tangent = unit(centers[min(i+1, len(centers)-1)] - centers[max(0, i-1)])
            guide = (1., 0, 0) if abs(tangent[0]) < .85 else (0, 0, 1.)
            axis = unit(np.cross(guide, tangent))
            second = np.cross(tangent, axis)
            depth, width = (radius, radius) if isinstance(radius, (float, int)) else radius
            rings.append([center + axis*depth*cos(2*pi*j/count) + second*width*sin(2*pi*j/count)
                          for j in range(count)])
        self.add(name, polygon_rings(rings), tone, group, finish)
        if weights is not None:
            self.parts[-1].weights = [weight for weight in weights for _ in range(count)]

    def pipe(self, name, points, radius, tone, group, finish="fabric", count=8):
        self.sweep(name, [(point, radius) for point in points], tone, group, finish, count)

    def bar(self, name, at, size, tone, group, finish="metal", bevel=.018):
        # A machined bevel around the upper and lower chamfered rectangle.
        x, y, z = at
        a, b, h = (size[0]/2, size[1]/2, size[2]/2)
        edge = min(bevel, a*.38, b*.38, h*.72)
        rings = []
        for height, inset in [(-h, edge), (-h+edge, 0), (h-edge, 0), (h, edge)]:
            u, v = a-inset, b-inset
            e = min(edge, u*.43, v*.43)
            rings.append([(x+u0, y+v0, z+height) for u0, v0 in [
                (-u+e,-v), (u-e,-v), (u,-v+e), (u,v-e),
                (u-e,v), (-u+e,v), (-u,v-e), (-u,-v+e),
            ]])
        self.add(name, polygon_rings(rings), tone, group, finish, smooth=False)

def atlas(frames, size, columns):
    rows = (len(frames) + columns - 1) // columns
    sheet = Image.new("RGBA", (columns*size[0], rows*size[1]))
    for index, frame in enumerate(frames):
        sheet.paste(frame, ((index % columns)*size[0], (index // columns)*size[1]))
    return sheet


def overhead_point(point):
    x, y, z = point
    return (x*42/BODY_VIEW, (-y*sin(ELEVATION) - (z-BODY_FOCUS)*cos(ELEVATION))*42/BODY_VIEW)


class Renderer:
    def __init__(self):
        self.scene = vtk.vtkRenderer()
        self.scene.SetBackground(0, 0, 0)
        self.scene.SetBackgroundAlpha(0)
        self.scene.AutomaticLightCreationOff()
        self.win = vtk.vtkRenderWindow()
        self.win.SetOffScreenRendering(True)
        self.win.SetAlphaBitPlanes(True)
        self.win.SetMultiSamples(0)
        self.win.AddRenderer(self.scene)
        self.camera = self.scene.GetActiveCamera()
        self.camera.ParallelProjectionOn()
        for position, strength, tint in [
            ((-3.4, -4.4, 6.2), .92, (1., .93, .86)),
            ((3.8, 1.5, 5.5), .42, (.77, .86, 1.)),
            ((-1.0, 4.5, 2.1), .31, (1., .75, .65)),
        ]:
            light = vtk.vtkLight()
            light.SetLightTypeToSceneLight()
            light.SetPosition(*position)
            light.SetFocalPoint(0, 0, .9)
            light.SetIntensity(strength)
            light.SetColor(*tint)
            self.scene.AddLight(light)

    def render(self, mesh, pixels=(CELL, CELL), view=BODY_VIEW, focus=(0, 0, BODY_FOCUS),
               elevation=ELEVATION, heading=0, supersample=1.5, selection=None):
        width, height = (round(dim*supersample) for dim in pixels)
        self.win.SetSize(width, height)
        self.camera.SetPosition(focus[0], focus[1]-16*cos(elevation), focus[2]+16*sin(elevation))
        self.camera.SetFocalPoint(*focus)
        self.camera.SetViewUp(0, sin(elevation), cos(elevation))
        self.camera.SetParallelScale(view*height/width*.5)
        buckets = {}
        for part in mesh.parts:
            if selection is None or selection(part):
                buckets.setdefault((part.tone, part.finish, part.smooth), []).append(part)
        for (tone, finish, smooth), parts in buckets.items():
            mesh_points = []
            indices = []
            offsets = [0]
            point_count = 0
            for part in parts:
                mesh_points.append(part.points)
                for face in part.faces:
                    indices.extend(point_count + index for index in face)
                    offsets.append(len(indices))
                point_count += len(part.points)
            poly = vtk.vtkPolyData()
            points = vtk.vtkPoints()
            points.SetData(numpy_to_vtk(np.concatenate(mesh_points), deep=True))
            poly.SetPoints(points)
            cells = vtk.vtkCellArray()
            cells.SetData(numpy_to_vtkIdTypeArray(np.array(offsets, dtype=np.int64), deep=True),
                          numpy_to_vtkIdTypeArray(np.array(indices, dtype=np.int64), deep=True))
            poly.SetPolys(cells)
            normals = vtk.vtkPolyDataNormals()
            normals.SetInputData(poly)
            normals.SetConsistency(True)
            normals.AutoOrientNormalsOn()
            normals.SetComputePointNormals(smooth)
            normals.SetComputeCellNormals(True)
            normals.SetSplitting(not smooth)
            mapper = vtk.vtkPolyDataMapper()
            mapper.SetInputConnection(normals.GetOutputPort())
            actor = vtk.vtkActor()
            actor.SetMapper(mapper)
            actor.SetOrientation(0, 0, float(np.rad2deg(heading)))
            material = actor.GetProperty()
            material.SetColor(*tone)
            material.SetAmbient(.32)
            material.SetDiffuse(.65)
            specular, power = MATERIALS[finish]
            material.SetSpecular(specular)
            material.SetSpecularPower(power)
            if not smooth:
                material.SetInterpolationToFlat()
            self.scene.AddActor(actor)
        self.scene.ResetCameraClippingRange()
        self.win.Render()
        pixels_filter = vtk.vtkWindowToImageFilter()
        pixels_filter.SetInput(self.win)
        pixels_filter.SetInputBufferTypeToRGBA()
        pixels_filter.ReadFrontBufferOff()
        pixels_filter.Update()
        data = vtk_to_numpy(pixels_filter.GetOutput().GetPointData().GetScalars())
        raw = data.reshape(height, width, 4)[::-1].copy()
        result = Image.fromarray(raw).resize(pixels, Image.Resampling.LANCZOS)
        self.scene.RemoveAllViewProps()
        return result
