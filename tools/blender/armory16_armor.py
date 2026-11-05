"""Generate compact, authored armor shells for Godot. Run with Blender -b --factory-startup --python this_file."""
import bpy
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "godot/assets/armor16"
ROOT.mkdir(parents=True, exist_ok=True)


def material(tier):
    m = bpy.data.materials.new("Padded bronze" if tier == 1 else "Forged teal" if tier == 2 else "Ceremonial gold")
    m.diffuse_color = ((0.42, 0.31, 0.20, 1), (0.27, 0.43, 0.47, 1), (0.61, 0.48, 0.27, 1))[tier - 1]
    return m


def cube(name, location, scale, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new("Soft forged edge", 'BEVEL')
        mod.width = bevel
        mod.segments = 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def shell(name, tier, low):
    # Curved torso shell: tapered waist, broad collar, folded lower edge.
    columns = 5 if low else 9
    rows = 3 if low else 5
    verts = []
    faces = []
    for j in range(rows):
        y = -0.5 + j / (rows - 1)
        width = (0.43 + 0.06 * (y + 0.5)) * (1.0 if tier > 1 else 0.91)
        for i in range(columns):
            t = -1 + 2 * i / (columns - 1)
            verts.append((t * width, y, 0.18 - 0.13 * t * t + (0.02 if tier == 3 else 0)))
    for j in range(rows - 1):
        for i in range(columns - 1):
            a = j * columns + i
            faces.append((a, a + 1, a + 1 + columns, a + columns))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    solid = obj.modifiers.new("Padded shell" if tier == 1 else "Forged shell", 'SOLIDIFY')
    solid.thickness = 0.055 if tier == 1 else 0.035
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=solid.name)
    return obj


def tapered(name, top, bottom, radius, low):
    n = 8 if low else 12
    verts = []
    faces = []
    for y, r in ((-0.5, bottom), (0.5, top)):
        for i in range(n):
            angle = 2 * math.pi * i / n
            verts.append((math.cos(angle) * r, y, math.sin(angle) * r * 0.76))
    for i in range(n):
        k = (i + 1) % n
        faces.append((i, k, k + n, i + n))
    faces.extend((tuple(reversed(range(n))), tuple(range(n, 2*n))))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def join(name, parts, mat):
    bpy.ops.object.select_all(action='DESELECT')
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = False
    return obj


def build(tier, low):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)  # Delete Blender's default cube too.
    mat = material(tier)
    detail = not low
    chest = [shell("Chest", tier, low)]
    chest += [cube("Collar", (0, 0.47, 0.12), (0.96, 0.075, 0.10), 0.018)]
    chest += [cube("Lower binding", (0, -0.47, 0.10), (0.85, 0.06, 0.09), 0.012)]
    if tier >= 2:
        chest += [cube("Center keel", (0, 0.01, 0.205), (0.075, 0.88, 0.05), 0.015)]
    if tier == 3:
        for side in (-1, 1):
            crest = cube("Ceremonial chevron", (side * 0.20, 0.22, 0.20), (0.34, 0.055, 0.055), 0.01)
            crest.rotation_euler[2] = side * 0.5
            chest.append(crest)
    join("Chest", chest, mat)

    pauldron = [tapered("Pauldron", 0.51, 0.36, 0.48, low)]
    pauldron[0].scale = (1, 0.49, 0.72)
    if tier >= 2:
        pauldron.append(cube("Shoulder lip", (0, -0.23, 0.12), (0.83, 0.065, 0.39), 0.018))
    if tier == 3 and detail:
        pauldron.append(cube("Shoulder ridge", (0, 0.0, 0.39), (0.09, 0.48, 0.09), 0.012))
    join("Pauldron", pauldron, mat)

    for name, top, bottom, radius in (("Bracer", 0.29, 0.20, 0.31), ("Greave", 0.35, 0.24, 0.34)):
        parts = [tapered(name, top, bottom, radius, low)]
        parts.append(cube("Raised cuff", (0, 0.46, 0), (top * 2.06, 0.08, radius * 1.62), 0.012))
        if tier >= 2:
            parts.append(cube("Front rib", (0, 0, radius * 0.76), (0.09, 0.78, 0.045), 0.012))
        if tier == 3 and detail:
            parts.append(cube("Lower filigree", (0, -0.27, radius * 0.77), (0.40, 0.055, 0.05), 0.01))
        join(name, parts, mat)

    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(ROOT / f"armor_mk{tier}_{'low' if low else 'high'}.glb"), export_format='GLB', use_selection=True, export_apply=True)
    for obj in bpy.context.selected_objects:
        print(f"ARMOR16 {tier} {'low' if low else 'high'} {obj.name}: {sum(len(p.vertices)-2 for p in obj.data.polygons)} tris")


for level in (1, 2, 3):
    for low_detail in (True, False):
        build(level, low_detail)
