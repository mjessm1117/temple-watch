"""Brighten the staged jungle half cover and LOD1 without changing geometry or texture dimensions.

Run: blender -b --factory-startup --python tools/blender/brighten-jungle-v7.py -- <asset-dir> <output-dir>
"""
import bpy
import json
import os
import sys
import numpy as np

asset_dir, output_dir = sys.argv[sys.argv.index("--") + 1:]
os.makedirs(output_dir, exist_ok=True)

def lift(img):
    px = np.empty(img.size[0] * img.size[1] * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    rgba = px.reshape((-1, 4))
    rgb = rgba[:, :3]
    # Lift shadows enough to read at 844x390; retain texture contrast and natural color.
    gray = rgb @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    rgb[:] = np.clip((gray[:, None] + (rgb - gray[:, None]) * 1.08) * 1.18 + 0.018, 0, 1)
    img.pixels.foreach_set(px)
    img.update()

for suffix in ("", "_lod1"):
    name = "cover_half_jungle_v7" + suffix
    source = os.path.join(asset_dir, name + ".glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=source)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    triangles = sum(len(o.data.loop_triangles) for o in meshes)
    print("BEFORE", name, "triangles", triangles, "materials", [m.name for m in bpy.data.materials])
    texture_info = []
    for img in bpy.data.images:
        if img.size[0] == 0 or img.size[1] == 0:
            continue
        lift(img)
        texture_info.append([img.name, list(img.size)])
    for mat in bpy.data.materials:
        if not mat.use_nodes:
            continue
        for node in mat.node_tree.nodes:
            if node.type != "BSDF_PRINCIPLED":
                continue
            color = node.inputs["Base Color"].default_value
            if not node.inputs["Base Color"].is_linked:
                node.inputs["Base Color"].default_value = (*[min(1, c * 1.18 + 0.018) for c in color[:3]], color[3])
    target = os.path.join(output_dir, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=target, export_format="GLB", export_image_format="AUTO")
    print("AFTER", json.dumps({"model": name, "triangles": triangles, "textures": texture_info,
                                "old_bytes": os.path.getsize(source), "new_bytes": os.path.getsize(target)}))
