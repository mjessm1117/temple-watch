"""Inspect Trooper rig and geometry in Blender.

Run with: blender -b --factory-startup --python art/w17-2/fix6-inspect.py
"""
import bpy
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
TROOPER = os.path.join(ROOT, 'godot/assets/models/units/trooper.glb')

def inspect(path):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=path)
    print('SOURCE', path)
    print('TRIANGLES', sum(len(ob.data.polygons) for ob in bpy.context.scene.objects if ob.type == 'MESH' and ob.name != 'Icosphere'))
    print('MATERIALS', [m.name for m in bpy.data.materials])
    print('TEXTURES', [(im.name, tuple(im.size)) for im in bpy.data.images])
    for ob in bpy.context.scene.objects:
        if ob.type == 'ARMATURE':
            print('ARM', ob.name, 'scale', tuple(ob.scale), 'dims', tuple(ob.dimensions), 'loc', tuple(ob.location))
            print('BONES', [b.name for b in ob.data.bones])
            for b in ob.data.bones:
                if b.name in ('hand_r', 'spine_03', 'HeadTop_End', 'head_end'):
                    print('BONE', b.name, 'head', tuple(b.head_local), 'tail', tuple(b.tail_local))
        elif ob.type == 'MESH':
            print('MESH', ob.name, 'parent', ob.parent.name if ob.parent else None, 'parent_type',ob.parent_type,'parent_bone',ob.parent_bone, 'loc',tuple(ob.location),'scale',tuple(ob.scale),'dims',tuple(ob.dimensions),'world',tuple(ob.matrix_world.translation))

inspect(TROOPER)
