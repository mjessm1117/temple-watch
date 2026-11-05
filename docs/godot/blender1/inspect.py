import bpy,sys
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=sys.argv[-1])
for o in bpy.context.scene.objects:
 if o.type == 'MESH': print('MESH',o.name,'polys',len(o.data.polygons),'mats',len(o.data.materials),'parent',o.parent.name if o.parent else '', 'hide',o.hide_render,'collections',[c.name for c in o.users_collection])
