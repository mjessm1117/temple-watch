"""Run with Blender --background --python .../decimate.py from repository root."""
import bpy
import json
from pathlib import Path

ROOT = Path.cwd()
SOURCES = [
    "models/units/agent.glb", "models/units/jedi.glb",
    "models/units/scout.glb", "models/units/sithHeavy.glb",
    "models/units/trooper.glb", "maps/relay.glb",
    "maps/gantry.glb", "maps/statue.glb", "maps/shuttle.glb",
]
OUT = ROOT / "godot/assets/models_v2"
OUT.mkdir(parents=True, exist_ok=True)
results = []
for source in SOURCES:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(ROOT / "godot/assets" / source))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"
              and not any(c.name.startswith("glTF_not_exported") for c in o.users_collection)]
    before = sum(len(o.data.loop_triangles) for o in meshes)
    target = 5000 if source.startswith("models/") else 1500
    ratio = min(1.0, target / before * 0.985)
    for ob in meshes:
        if ob.data.shape_keys:
            raise RuntimeError(f"shape keys require separate handling: {source}")
        mod = ob.modifiers.new("Phone triangle reduction", "DECIMATE")
        mod.ratio = ratio
        mod.use_collapse_triangulate = True
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.modifier_apply(modifier=mod.name)
    after = sum(len(o.data.loop_triangles) for o in meshes)
    dst = OUT / (Path(source).stem + "_v2.glb")
    bpy.ops.export_scene.gltf(filepath=str(dst), export_format="GLB",
                              export_animations=True, export_skins=True,
                              export_texcoords=True, export_normals=True,
                              export_materials="EXPORT")
    results.append({"source": source, "v2": str(dst.relative_to(ROOT)),
                    "before": before, "after": after, "ratio": ratio,
                    "mesh_count": len(meshes)})
    print("DECIMATED", json.dumps(results[-1]), flush=True)
(ROOT / "docs/godot/blender2/decimate-results.json").write_text(
    json.dumps(results, indent=2) + "\n")
