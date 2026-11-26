"""Create an editable .blend with modular wardrobe collections and pose actions.

Usage: blender --background --python tools/sprite_kit/export_blender.py -- source.json kit.blend
"""
from collections import defaultdict
import json
from pathlib import Path
import sys

import bpy
from mathutils import Vector


def collection(name, parent):
    group = bpy.data.collections.new(name)
    parent.children.link(group)
    return group


def material(tone, surface):
    key = f"{surface.title()} " + " ".join(f"{value:.2f}" for value in tone)
    if key in bpy.data.materials:
        return bpy.data.materials[key]
    item = bpy.data.materials.new(key)
    # The VTK palette is stored in display RGB. Convert it for Blender's shaders.
    linear = tuple(value/12.92 if value < .04045 else ((value+.055)/1.055)**2.4 for value in tone)
    item.diffuse_color = (*tone, 1)
    item.use_nodes = True
    shader = item.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*linear,1)
    shader.inputs["Roughness"].default_value = {
        "metal":.29, "leather":.40, "hair":.43, "glass":.22, "skin":.53,
    }.get(surface,.79)
    shader.inputs["Metallic"].default_value = .55 if surface == "metal" else 0
    return item


def mesh_object(name, inputs, group, parent, armature=None):
    points, faces, materials, smooth_flags = [], [], [], []
    weights = defaultdict(lambda: defaultdict(list))
    palette = []
    for part in inputs:
        offset = len(points)
        points.extend(part["points"])
        faces.extend(tuple(index+offset for index in face) for face in part["faces"])
        bone = part["group"].split("/")[-1]
        if part.get("weights"):
            for vertex, influences in enumerate(part["weights"],start=offset):
                for joint, influence in influences.items():
                    weights[joint][influence].append(vertex)
        else:
            weights[bone][1.0].extend(range(offset,len(points)))
        surface_material = material(part["tone"],part["finish"])
        if surface_material not in palette:
            palette.append(surface_material)
        materials.extend([palette.index(surface_material)]*len(part["faces"]))
        smooth_flags.extend([part["smooth"]]*len(part["faces"]))
    data = bpy.data.meshes.new(name)
    data.from_pydata(points,[],faces)
    data.update()
    for item in palette:
        data.materials.append(item)
    for polygon, index, smooth in zip(data.polygons,materials,smooth_flags):
        polygon.material_index = index
        polygon.use_smooth = smooth
    obj = bpy.data.objects.new(name,data)
    group.objects.link(obj)
    obj.parent = parent
    if armature is not None:
        for bone, influences in weights.items():
            vertex_group = obj.vertex_groups.new(name=bone)
            for weight, vertices in influences.items():
                vertex_group.add(vertices, weight, "REPLACE")
        deformation = obj.modifiers.new("Wardrobe Rig","ARMATURE")
        deformation.object = armature
    return obj


def make_rig(record, group, location):
    data = bpy.data.armatures.new(record["name"]+" joints")
    rig = bpy.data.objects.new(record["name"]+" rig",data)
    group.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    for name, info in record["bones"].items():
        bone = data.edit_bones.new(name)
        bone.head = info["head"]
        bone.tail = info["tail"]
        if info["parent"]:
            bone.parent = data.edit_bones[info["parent"]]
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.location = location
    rig.select_set(False)
    rig.show_in_front = False
    rig.hide_render = True
    return rig


def make_actions(rig, poses, neutral):
    rig.animation_data_create()
    for preset in poses:
        action = bpy.data.actions.new("Saafiya • "+preset["name"])
        action.use_fake_user = True
        for name, frame in [("Ready",1),("Recoil",6),("Service",16),("Return",28)]:
            marker = action.pose_markers.new(name)
            marker.frame = frame
        rig.animation_data.action = action
        for frame, targets in zip([1,6,16,28],preset["frames"]):
            for bone_name in neutral:
                pose_bone = rig.pose.bones[bone_name]
                rest = pose_bone.bone.matrix_local
                target = targets[bone_name]
                direction = Vector(target["tail"])-Vector(target["head"])
                rest_direction = pose_bone.bone.tail_local-pose_bone.bone.head_local
                adjustment = rest_direction.rotation_difference(direction)
                transform = (adjustment.to_matrix() @ rest.to_3x3()).to_4x4()
                transform.translation = Vector(target["head"])
                pose_bone.rotation_mode = "QUATERNION"
                pose_bone.matrix = transform
                bpy.context.view_layer.update()
                pose_bone.keyframe_insert(data_path="rotation_quaternion",frame=frame,group=bone_name)
                pose_bone.keyframe_insert(data_path="location",frame=frame,group=bone_name)
        action.asset_mark()
    rig.animation_data.action = None
    for pose_bone in rig.pose.bones:
        pose_bone.matrix_basis.identity()
    bpy.context.view_layer.update()


def add_person(record, category, location):
    group = collection(record["name"],category)
    rig = make_rig(record, group, location)
    rig["body_template"] = record["body"]
    buckets = defaultdict(list)
    for part in record["parts"]:
        buckets[part["group"].split("/")[0]].append(part)
    for title, parts in buckets.items():
        layer = collection(record["name"]+" / "+title,group)
        mesh_object(layer.name,parts,layer,rig,rig)
    if record.get("poses"):
        make_actions(rig,record["poses"],record["bones"])
    return rig


def add_prop(record, category, location):
    group = collection(record["name"],category)
    root = bpy.data.objects.new(record["name"]+" display",None)
    group.objects.link(root)
    root.location = location
    root.scale = (.58,)*3
    buckets = defaultdict(list)
    for part in record["parts"]:
        buckets[part["group"].split("/")[0]].append(part)
    for title, parts in buckets.items():
        mesh_object(record["name"]+" / "+title,parts,group,root)


def build(dump, destination):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = "Saafiya’s Revenge — Editable Sprite Kit"
    source = json.loads(dump.read_text())
    templates = collection("01 Body templates",scene.collection)
    protagonist = collection("02 Saafiya | alternate",scene.collection)
    citizens = collection("03 Citizens",scene.collection)
    props = collection("04 Overhead props",scene.collection)
    for index, record in enumerate(source["people"]):
        if index < 3:
            add_person(record,templates,((index-1)*2.05,6.0,0))
        elif index == 3:
            add_person(record,protagonist,(4.60,6.0,0))
        else:
            cast = index-4
            add_person(record,citizens,((cast%5-2)*2.05,3.8-(cast//5)*2.2,0))
    for index, record in enumerate(source["gear"]):
        add_prop(record,props,((index%5-2)*2.05,-.55-(index//5)*1.09,.13))
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type == "VIEW_3D":
                space = area.spaces.active
                space.region_3d.view_distance = 13.2
                space.region_3d.view_location = (.22,2.45,.84)
                space.region_3d.view_rotation = Vector((1,-5.5,5.2)).to_track_quat("Z","Y")
                space.region_3d.view_perspective = "ORTHO"
                space.shading.color_type = "MATERIAL"
                space.overlay.show_extras = False
                space.overlay.show_floor = False
                space.overlay.show_axis_x = False
                space.overlay.show_axis_y = False
    notes = bpy.data.texts.new("Read me")
    notes.write(
        "Saafiya’s Revenge / original sprite kit\n\n"
        "Three adult body templates and ten NPC wardrobe presets share the same named rig.\n"
        "Saafiya has separate corset, lace, jacket, skirt, belt, stocking, boot, hair and jewelry collections.\n"
        "Toggle wardrobe collections to reveal the underlying neutral body, or copy compatible garments.\n"
        "Nine Saafiya action assets contain ready, recoil, service and return poses.\n"
        "Weapon geometry is display art. The display, action and magazine objects are separate.\n"
    )
    scene.frame_end = 32
    scene.frame_set(1)
    destination.parent.mkdir(parents=True,exist_ok=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(destination),compress=True)


if __name__ == "__main__":
    inputs = sys.argv[sys.argv.index("--")+1:]
    build(Path(inputs[0]),Path(inputs[1]))
