"""Render the W17/W19 comparison and phone-distance lineup without changing game wiring."""
import bpy
from pathlib import Path
from mathutils import Vector

ROOT=Path('/home/jess/projects/tw-w19/art')
OUT=Path('/home/jess/projects/tw-logs/w19/art')
ORDER=('sniper','heavy','tech','officer','medic','droid','scout')
SC=bpy.context.scene
SC.render.engine='BLENDER_EEVEE';SC.world.color=(.10,.13,.18)
SC.render.image_settings.file_format='JPEG';SC.render.image_settings.quality=92
SC.view_settings.view_transform='AgX'
ARMS=[]

def clear():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)

def import_lineup(version):
    for index,kind in enumerate(ORDER):
        if version=='w19':file=ROOT/f'godot/assets/units/w19/{kind}.glb'
        elif kind=='scout':file=ROOT/'godot/assets/models/units/scout.glb'
        elif kind=='medic':file=ROOT/'godot/assets/models/units/trooper.glb'
        else:file=ROOT/f'godot/assets/units/w17/{kind}.glb'
        old=set(bpy.data.objects)
        old_actions=set(bpy.data.actions)
        bpy.ops.import_scene.gltf(filepath=str(file))
        new=[o for o in bpy.data.objects if o not in old]
        idle=next((a for a in bpy.data.actions if a not in old_actions and a.name.split('.')[0]=='idle'),None)
        x=(index-3)*1.55
        for o in new:
            if o.type=='MESH' and o.name.startswith('Icosphere'):o.hide_render=True
            if o.parent is None and o.type!='CAMERA' and o.type!='LIGHT':o.location.x+=x
            if o.type=='ARMATURE':
                o.data.pose_position='POSE'
                if idle:
                    o.animation_data_create();o.animation_data.action=idle
                    if idle.slots:o.animation_data.action_slot=idle.slots[0]
                ARMS.append(o)
    SC.frame_set(10)

def lights():
    bpy.ops.object.light_add(type='AREA',location=(0,-5,8));bpy.context.object.data.energy=900;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=10
    bpy.ops.object.light_add(type='AREA',location=(-4,3,6));bpy.context.object.data.energy=500;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=8

def render(version,distance):
    bpy.ops.object.camera_add()
    cam=bpy.context.object
    if distance=='battle':
        cam.location=(0,-8,8.6);target=Vector((0,0,.5));cam.data.ortho_scale=22.4;size=(844,390)
        for i,arm in enumerate(ARMS):arm.location.x+=(i-3)*.9
    else:
        cam.location=(0,-13,3.8);target=Vector((0,0,.92));cam.data.ortho_scale=11.8;size=(2100,390)
    cam.rotation_euler=(target-Vector(cam.location)).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';SC.camera=cam
    SC.render.resolution_x,SC.render.resolution_y=size;SC.render.resolution_percentage=100
    SC.render.filepath=str(OUT/f'{version}-{distance}.jpg')
    bpy.ops.render.render(write_still=True)
    if distance=='battle':
        for i,arm in enumerate(ARMS):arm.location.x-=(i-3)*.9
    bpy.data.objects.remove(cam,do_unlink=True)

for version in ('w17','w19'):
    clear();ARMS.clear();import_lineup(version);lights()
    for distance in ('battle','armory'):render(version,distance)
    print('W19 CAPTURE',version)
