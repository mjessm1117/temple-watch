import bpy,sys
from mathutils import Vector
for path in sys.argv[sys.argv.index('--')+1:]:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=path)
 for o in [x for x in bpy.context.scene.objects if x.type=='MESH']:
  if o.name=='Icosphere': continue
  dg=bpy.context.evaluated_depsgraph_get();e=o.evaluated_get(dg);m=e.to_mesh();verts=[e.matrix_world@v.co for v in m.vertices]
  lo=[min(v[i] for v in verts) for i in range(3)];hi=[max(v[i] for v in verts) for i in range(3)]
  mean=[sum(v[i] for v in verts)/len(verts) for i in range(3)]
  print('MEASURE',path,'lo',*[round(x,3) for x in lo],'hi',*[round(x,3) for x in hi],'mean',*[round(x,3) for x in mean])
