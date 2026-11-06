"""Render old and new isolated gear cells for the Fix 8 comparison sheet."""
import bpy
from mathutils import Vector
from pathlib import Path

OUT=Path('/tmp')
KINDS=['sniper','heavy','tech','droid','officer']

def render(path,which,part,kind):
    for old in list(bpy.data.objects): bpy.data.objects.remove(old,do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    objs=[]
    for o in bpy.data.objects:
        if o.type!='MESH':continue
        n=o.name.lower()
        if which=='old':
            pick=('__hand_r' in n) if part=='weapon' else ('__spine_03' in n)
        else: pick=True
        if pick:objs.append(o)
        else:o.hide_render=True
    if not objs:raise RuntimeError(f'No {which} {kind} {part} meshes')
    points=[]
    for o in objs:
        for v in o.bound_box:points.append(o.matrix_world@Vector(v))
    lo=Vector([min(p[i] for p in points) for i in range(3)])
    hi=Vector([max(p[i] for p in points) for i in range(3)])
    center=(lo+hi)/2; diameter=(hi-lo).length
    bpy.ops.object.camera_add(location=center+Vector((1.7,-2.8,1.5)).normalized()*max(2,diameter*2.8))
    cam=bpy.context.object;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO';cam.data.ortho_scale=max(.70 if part=='pack' else .45,max((hi-lo).x,(hi-lo).y,(hi-lo).z)*(1.7 if part=='pack' else 1.25))
    bpy.context.scene.camera=cam
    sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH'
    sc.display.shading.light='STUDIO';sc.display.shading.color_type='MATERIAL'
    sc.display.shading.show_shadows=True;sc.display.shading.show_cavity=True
    sc.display.shading.cavity_type='BOTH'
    sc.render.film_transparent=False
    sc.render.resolution_x=320;sc.render.resolution_y=230;sc.render.resolution_percentage=100
    sc.render.image_settings.file_format='PNG'
    sc.render.filepath=str(OUT/f'w17-fix8-{which}-{kind}-{part}.png')
    bpy.ops.render.render(write_still=True)
    print('CELL',which,kind,part,len(objs),lo[:],hi[:])

for kind in KINDS:
    for part in ['weapon',*(['pack'] if kind in ('heavy','tech') else [])]:
        render(OUT/f'w17-fix8-old-{kind}.glb','old',part,kind)
        render(OUT/f'w17-fix8-gear/{kind}-{part}-lod0.glb','new',part,kind)
