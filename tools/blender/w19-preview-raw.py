"""Inspect both paid previews in a lit Blender render."""
import bpy
from pathlib import Path
from mathutils import Vector

out=Path('/home/jess/projects/tw-logs/w19/art')
for kind in ('sniper','medic'):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(out/f'pass4-{kind}-preview.glb'))
    sc=bpy.context.scene;sc.render.engine='BLENDER_EEVEE';sc.world.color=(.14,.16,.19)
    bpy.ops.object.light_add(type='AREA',location=(2,-3,4));bpy.context.object.data.energy=500;bpy.context.object.data.size=5
    bpy.ops.object.camera_add(location=(2.8,-4,2));cam=bpy.context.object
    cam.rotation_euler=(Vector((0,0,0))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=3
    sc.camera=cam;sc.render.resolution_x=800;sc.render.resolution_y=800;sc.render.resolution_percentage=100
    sc.render.image_settings.file_format='JPEG';sc.render.filepath=str(out/f'pass4-{kind}-raw.jpg')
    bpy.ops.render.render(write_still=True)
