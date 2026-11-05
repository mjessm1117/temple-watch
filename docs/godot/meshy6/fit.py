"""Fit a Meshy GLB to one tile and exact 0.8 m half-cover height.

Usage: blender -b --factory-startup --python fit.py -- input.glb output.glb
"""
import bpy
import json
import sys
from mathutils import Vector

src, dst = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete()
bpy.ops.import_scene.gltf(filepath=src)
meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
if not meshes:
    raise RuntimeError("No meshes")
points = [obj.matrix_world @ vertex.co for obj in meshes for vertex in obj.data.vertices]
lo = Vector([min(point[i] for point in points) for i in range(3)])
hi = Vector([max(point[i] for point in points) for i in range(3)])
size = hi - lo
horizontal = max(size.x, size.y)
if horizontal < 0.01 or size.z < 0.01:
    raise RuntimeError("Degenerate model bounds")
scale_xz = 0.96 / horizontal
scale_z = 0.8 / size.z
for obj in meshes:
    world = obj.matrix_world.copy()
    obj.parent = None
    obj.matrix_world = world
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.select_set(False)
    for vertex in obj.data.vertices:
        vertex.co.x = (vertex.co.x - (lo.x + hi.x) / 2) * scale_xz
        vertex.co.y = (vertex.co.y - (lo.y + hi.y) / 2) * scale_xz
        vertex.co.z = (vertex.co.z - lo.z) * scale_z
for obj in bpy.context.scene.objects:
    obj.select_set(obj in meshes)
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", use_selection=True, export_apply=True)
print("FIT", json.dumps({"input": src, "output": dst, "original_size": list(size),
    "fit_size": [size.x * scale_xz, size.y * scale_xz, 0.8],
    "horizontal_scale": scale_xz, "vertical_scale": scale_z}))
