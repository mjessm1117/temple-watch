import bpy
from pathlib import Path

root = Path.cwd()
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root / "godot/assets/maps/gantry.glb"))
for ob in bpy.context.scene.objects:
    if ob.type != "MESH" or any(c.name.startswith("glTF_not_exported") for c in ob.users_collection):
        continue
    mod = ob.modifiers.new("Keep gantry bracing", "DECIMATE")
    mod.ratio = 0.5
    mod.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier=mod.name)
    ob.data.calc_loop_triangles()
    print("GANTRY TRIANGLES", len(ob.data.loop_triangles))
bpy.ops.export_scene.gltf(filepath=str(root / "godot/assets/models_v2/gantry_v2.glb"),
                          export_format="GLB", export_animations=True,
                          export_skins=True, export_texcoords=True,
                          export_normals=True, export_materials="EXPORT")
