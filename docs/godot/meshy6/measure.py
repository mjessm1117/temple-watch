"""Measure source GLBs in Blender coordinates; usage after --: file.glb ..."""
import bpy
import json
import sys
from mathutils import Vector

for src in sys.argv[sys.argv.index("--") + 1:]:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    bpy.ops.import_scene.gltf(filepath=src)
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    points = [obj.matrix_world @ vertex.co for obj in meshes for vertex in obj.data.vertices]
    lo = Vector([min(point[i] for point in points) for i in range(3)])
    hi = Vector([max(point[i] for point in points) for i in range(3)])
    triangles = sum(len(obj.data.polygons) for obj in meshes)
    print("MEASURE", json.dumps({"path": src, "dimensions": list(hi - lo),
        "min": list(lo), "triangles": triangles}))
