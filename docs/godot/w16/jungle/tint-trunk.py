import bpy,sys
src,dst=sys.argv[sys.argv.index('--')+1:]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete()
bpy.ops.import_scene.gltf(filepath=src)
for obj in [o for o in bpy.context.scene.objects if o.type=='MESH' and len(o.data.polygons)>100]:
    mat=obj.data.materials[0].copy()
    mat.name='Deep brown bark tint'
    mat.diffuse_color=(0.68,0.35,0.19,1.0)
    if mat.use_nodes:
        for node in mat.node_tree.nodes:
            if node.type=='BSDF_PRINCIPLED':
                node.inputs['Base Color'].default_value=(0.68,0.35,0.19,1.0)
    obj.data.materials.append(mat)
    count=0
    for poly in obj.data.polygons:
        c=poly.center
        if c.x>0.15 and c.z<0.60 and c.y<0.19:
            poly.material_index=1;count+=1
    print('TINTED_FACES',count,'/',len(obj.data.polygons))
bpy.ops.export_scene.gltf(filepath=dst,export_format='GLB',use_selection=False,export_apply=True)
