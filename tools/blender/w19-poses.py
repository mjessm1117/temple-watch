"""Render six staged classes in idle, run, and shoot for attachment review."""
import bpy
from pathlib import Path
from mathutils import Vector

ROOT=Path('/home/jess/projects/tw-w19/art')
OUT=Path('/home/jess/projects/tw-logs/w19/art')
ORDER=('sniper','heavy','tech','officer','medic','droid')
sc=bpy.context.scene;sc.render.engine='BLENDER_EEVEE';sc.world.color=(.1,.13,.18)
sc.render.resolution_x=1800;sc.render.resolution_y=390;sc.render.resolution_percentage=100
sc.render.image_settings.file_format='JPEG';sc.render.image_settings.quality=90

for clip in ('idle','run','shoot'):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for i,kind in enumerate(ORDER):
        old_objects=set(bpy.data.objects);old_actions=set(bpy.data.actions)
        bpy.ops.import_scene.gltf(filepath=str(ROOT/f'godot/assets/units/w19/{kind}.glb'))
        new=[o for o in bpy.data.objects if o not in old_objects]
        act=next(a for a in bpy.data.actions if a not in old_actions and a.name.split('.')[0]==clip)
        for o in new:
            if o.type=='MESH' and o.name.startswith('Icosphere'):o.hide_render=True
            if o.parent is None:o.location.x+=(i-2.5)*1.6
            if o.type=='ARMATURE':
                o.data.pose_position='POSE';o.animation_data_create();o.animation_data.action=act;o.animation_data.action_slot=act.slots[0]
    sc.frame_set(8 if clip=='shoot' else 10)
    bpy.ops.object.light_add(type='AREA',location=(0,-5,8));bpy.context.object.data.energy=750;bpy.context.object.data.size=10
    bpy.ops.object.camera_add(location=(0,-13,4));cam=bpy.context.object;cam.rotation_euler=(Vector((0,0,.9))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=10.5;sc.camera=cam
    sc.render.filepath=str(OUT/f'w19-pose-{clip}.jpg');bpy.ops.render.render(write_still=True)
