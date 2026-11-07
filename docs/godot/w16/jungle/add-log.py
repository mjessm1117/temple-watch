import bpy,sys,math
from mathutils import Vector
src,dst=sys.argv[sys.argv.index('--')+1:]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete()
bpy.ops.import_scene.gltf(filepath=src)
bark=bpy.data.materials.new('Deep brown bark')
bark.diffuse_color=(0.09,0.04,0.018,1)
bark.use_nodes=True
p=bark.node_tree.nodes.get('Principled BSDF')
p.inputs['Base Color'].default_value=(0.09,0.04,0.018,1)
p.inputs['Roughness'].default_value=0.94
bpy.ops.mesh.primitive_cone_add(vertices=10,radius1=0.13,radius2=0.11,depth=0.82,location=(-0.01,-0.08,0.64),rotation=Vector((1.0,0.42,0.03)).to_track_quat('Z','Y').to_euler())
obj=bpy.context.object;obj.name='Fallen trunk across ruin';obj.data.materials.append(bark)
# Make the cylinder read as bark rather than smooth machinery: a few low-poly dark ridges.
crevice=bpy.data.materials.new('Bark crevice')
crevice.diffuse_color=(0.025,0.012,0.008,1)
crevice.use_nodes=True
q=crevice.node_tree.nodes.get('Principled BSDF')
q.inputs['Base Color'].default_value=(0.025,0.012,0.008,1)
q.inputs['Roughness'].default_value=0.95
obj.data.materials.append(crevice)
for face in obj.data.polygons:
    if face.index%4==0:face.material_index=1
bpy.ops.export_scene.gltf(filepath=dst,export_format='GLB',export_apply=True)
