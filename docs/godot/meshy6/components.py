"""List loose mesh components and bounds; usage after --: model.glb"""
import bpy
import bmesh
import json
import sys
from mathutils import Vector

src = sys.argv[sys.argv.index("--") + 1]
bpy.ops.import_scene.gltf(filepath=src)
for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    unseen = set(bm.verts)
    result = []
    while unseen:
        start = unseen.pop()
        seen = {start}
        stack = [start]
        while stack:
            vertex = stack.pop()
            for edge in vertex.link_edges:
                other = edge.other_vert(vertex)
                if other in unseen:
                    unseen.remove(other)
                    seen.add(other)
                    stack.append(other)
        coords = [obj.matrix_world @ v.co for v in seen]
        lo = [min(c[i] for c in coords) for i in range(3)]
        hi = [max(c[i] for c in coords) for i in range(3)]
        result.append({"vertices": len(seen), "min": lo, "size": [hi[i]-lo[i] for i in range(3)]})
    result.sort(key=lambda c: c["vertices"], reverse=True)
    print("COMPONENTS", json.dumps({"object": obj.name, "count": len(result), "largest": result[:20]}))
    bm.free()
