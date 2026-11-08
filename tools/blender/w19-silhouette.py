"""Render seven W19 classes as flat grey at the 844x390 battle camera."""
import bpy
from pathlib import Path
from mathutils import Vector

ROOT = Path('/home/jess/projects/tw-w19/art')
OUT = Path('/home/jess/projects/tw-logs/w19/art')
ORDER = ('sniper', 'heavy', 'tech', 'officer', 'medic', 'droid', 'scout')
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.world.color = (.16, .16, .16)
grey = bpy.data.materials.new('flat silhouette grey')
grey.diffuse_color = (.54, .54, .54, 1)
grey.use_nodes = True
grey.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value = (.54, .54, .54, 1)
arms = []
for index, kind in enumerate(ORDER):
    before = set(bpy.data.objects)
    actions = set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=str(ROOT / f'godot/assets/units/w19/{kind}.glb'))
    new = [o for o in bpy.data.objects if o not in before]
    idle = next((a for a in bpy.data.actions if a not in actions and a.name.split('.')[0] == 'idle'), None)
    for obj in new:
        if obj.type == 'MESH':
            if obj.name.startswith('Icosphere'):
                obj.hide_render = True
            else:
                obj.data.materials.clear()
                obj.data.materials.append(grey)
        if obj.parent is None and obj.type not in ('CAMERA', 'LIGHT'):
            obj.location.x += (index - 3) * 2.45
        if obj.type == 'ARMATURE':
            if idle:
                obj.animation_data_create()
                obj.animation_data.action = idle
                if idle.slots:
                    obj.animation_data.action_slot = idle.slots[0]
            arms.append(obj)
scene.frame_set(10)
bpy.ops.object.light_add(type='AREA', location=(0, -5, 8))
bpy.context.object.data.energy = 900
bpy.context.object.data.size = 10
bpy.ops.object.camera_add(location=(0, -8, 8.6))
cam = bpy.context.object
cam.rotation_euler = (Vector((0, 0, .5)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
cam.data.type = 'ORTHO'
cam.data.ortho_scale = 22.4
scene.camera = cam
scene.render.resolution_x = 844
scene.render.resolution_y = 390
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'JPEG'
scene.render.filepath = str(OUT / 'w19-grey-battle.jpg')
bpy.ops.render.render(write_still=True)
