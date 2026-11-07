"""Build staged W19 soldier GLBs from W17 rigs, Meshy preview heads, and bone-bound kitbash gear."""
import bpy
import bmesh
import math
import sys
from pathlib import Path
from mathutils import Matrix, Vector

ROOT=Path('/home/jess/projects/tw-w19/art')
PREV=Path('/home/jess/projects/tw-logs/w19/art')
OUT=ROOT/'godot/assets/units/w19';OUT.mkdir(parents=True,exist_ok=True)
CLASSES=('sniper','heavy','tech','officer','medic','droid')
ACC={'sniper':(.30,.38,.20),'heavy':(.70,.33,.10),'tech':(.10,.45,.48),'officer':(.55,.10,.12),'medic':(.75,.07,.09),'droid':(.80,.66,.15)}
LOD=False

def mat(name,c):
    m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=0;p.inputs['Roughness'].default_value=.8
    return m

def bind(o,arm,bone):
    w=o.matrix_world.copy();o.parent=arm;o.parent_type='BONE';o.parent_bone=bone;o.matrix_world=w
    return o

def box(name,xyz,dim,m,arm,bone,bevel=.012):
    bpy.ops.mesh.primitive_cube_add(size=1,location=xyz);o=bpy.context.object;o.name=name;o.dimensions=dim
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('rounded edges','BEVEL');mod.width=min(bevel,min(dim)*.28);mod.segments=1 if LOD else (3 if bevel>.006 else 2);bpy.ops.object.modifier_apply(modifier=mod.name)
    o.data.materials.append(m);return bind(o,arm,bone)

def cyl(name,xyz,r,depth,m,arm,bone,vertices=8,axis='Z'):
    rot=(0,0,0) if axis=='Z' else ((math.pi/2,0,0) if axis=='Y' else (0,math.pi/2,0))
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=xyz,rotation=rot)
    o=bpy.context.object;o.name=name;o.data.materials.append(m)
    bevel=o.modifiers.new('rounded rim','BEVEL');bevel.width=min(.012,depth*.2);bevel.segments=2
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=bevel.name)
    return bind(o,arm,bone)

def ellipsoid(name,xyz,dim,m,arm,bone,lod):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8 if lod else 20,ring_count=4 if lod else 12,location=xyz)
    o=bpy.context.object;o.name=name;o.scale=tuple(d/2 for d in dim)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(m);return bind(o,arm,bone)

def cape(name,arm,bone,m,wide=.30,long=.48,y=.17):
    verts=[(-wide/2,y,1.34),(wide/2,y,1.34),(-wide*.67,y+.10,1.13),(wide*.67,y+.10,1.13),(-wide*.56,y+.23,1.34-long),(wide*.56,y+.23,1.34-long)]
    faces=[(0,1,3,2),(2,3,5,4)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);mesh.materials.append(m)
    solid=o.modifiers.new('cloth thickness','SOLIDIFY');solid.thickness=.018
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=solid.name)
    return bind(o,arm,bone)

def remove_old_head(body):
    bm=bmesh.new();bm.from_mesh(body.data)
    kill=[f for f in bm.faces if (body.matrix_world @ f.calc_center_median()).z>1.425]
    bmesh.ops.delete(bm,geom=kill,context='FACES');bm.to_mesh(body.data);bm.free();body.data.update()

def import_head(kind,arm,lod,M):
    # An enclosed Trooper-derived helmet replaces the exposed W17 face geometry.
    shell=M['accent'] if kind=='droid' else M['tan']
    ellipsoid('W19 enclosed helmet',(0,-.012,1.565),(.43,.40,.37),shell,arm,'Head',lod)
    ellipsoid('W19 navy faceplate',(0,-.174,1.553),(.33,.105,.205),M['navy'],arm,'Head',lod)
    ellipsoid('W19 dark visor',(0,-.225,1.602),(.29,.048,.075),M['dark'],arm,'Head',lod)
    box('W19 jaw guard',(0,-.205,1.478),(.24,.067,.055),M['navy'],arm,'Head')
    if kind=='sniper':
        ellipsoid('W19 olive hood crown',(0,.016,1.665),(.45,.42,.21),M['accent'],arm,'Head',lod)
        cyl('W19 attached scope',(.145,-.207,1.614),.038,.13,M['navy'],arm,'Head',8,axis='Y')
        cyl('W19 scope lens',(.145,-.275,1.614),.026,.012,M['dark'],arm,'Head',8,axis='Y')
    elif kind=='heavy':
        for s in (-1,1):ellipsoid('W19 orange cheek',(s*.177,-.098,1.535),(.09,.16,.15),M['accent'],arm,'Head',lod)
    elif kind=='tech':
        for s in (-1,1):cyl('W19 teal goggle',(s*.09,-.252,1.605),.058,.026,M['accent'],arm,'Head',8,axis='Y')
        cyl('W19 tech antenna',(.178,.006,1.771),.010,.17,M['navy'],arm,'Head',6)
        cyl('W19 antenna tip',(.178,.006,1.857),.019,.027,M['accent'],arm,'Head',6)
    elif kind=='officer':
        ellipsoid('W19 officer cap crown',(0,-.005,1.744),(.42,.38,.15),M['navy'],arm,'Head',lod)
        box('W19 crimson cap band',(0,-.153,1.704),(.37,.045,.046),M['accent'],arm,'Head')
        ellipsoid('W19 peaked cap brim',(0,-.178,1.688),(.44,.23,.035),M['navy'],arm,'Head',lod)
    elif kind=='medic':
        ellipsoid('W19 medical forehead badge',(0,-.157,1.704),(.17,.045,.09),M['white'],arm,'Head',lod)
        box('W19 medical cross vertical',(0,-.184,1.704),(.028,.014,.065),M['accent'],arm,'Head')
        box('W19 medical cross horizontal',(0,-.186,1.704),(.076,.014,.026),M['accent'],arm,'Head')
    elif kind=='droid':
        ellipsoid('W19 elongated droid dome',(0,.025,1.675),(.48,.41,.22),M['accent'],arm,'Head',lod)
        for s in (-1,1):cyl('W19 droid photoreceptor',(s*.09,-.257,1.596),.037,.025,M['glow'],arm,'Head',10,axis='Y')
        box('W19 droid jaw grille',(0,-.247,1.48),(.20,.025,.065),M['navy'],arm,'Head')

def gear(kind,arm,lod,M):
    a=M['accent'];n=M['navy'];t=M['tan'];w=M['white']
    if kind=='heavy':
        for s,bone in [(-1,'clavicle_r'),(1,'clavicle_l')]:
            ellipsoid('W19 curved orange pauldron',(s*.255,.005,1.318),(.23,.24,.105),a,arm,bone,lod)
            ellipsoid('W19 pauldron navy inset',(s*.255,-.105,1.312),(.15,.035,.042),n,arm,bone,lod)
    elif kind=='sniper':
        cape('W19 dark olive shoulder cloak',arm,'spine_03',M['olive'],.68,.68,.13)
        if not lod:
            for x in (-.22,-.07,.08,.22):ellipsoid('W19 cloak fold',(x,.30,.94),(.055,.06,.24),M['olive'],arm,'spine_03',lod)
    elif kind=='tech':
        for s in (-1,1):
            box('W19 tool harness strap',(s*.18,-.12,1.15),(.065,.065,.34),n,arm,'spine_03')
            ellipsoid('W19 teal tool pod',(s*.25,.02,1.09),(.14,.15,.23),a,arm,'spine_03',lod)
        box('W19 harness waist buckle',(0,-.20,1.02),(.23,.055,.09),t,arm,'spine_03')
    elif kind=='officer':
        cape('officer short crimson cape',arm,'spine_03',a,.35,.53,.16)
        box('rank plate',(0,-.18,1.23),(.19,.035,.09),a,arm,'spine_03')
        for x in (-.04,0,.04):box('rank bar',(x,-.204,1.23),(.020,.012,.05),w,arm,'spine_03')
    elif kind=='medic':
        ellipsoid('W19 medical satchel',(.30,.11,.99),(.23,.20,.28),w,arm,'pelvis',lod)
        box('satchel red cross vertical',(.43,.11,1.00),(.014,.04,.12),a,arm,'pelvis')
        box('satchel red cross horizontal',(.44,.11,1.00),(.014,.12,.04),a,arm,'pelvis')
        box('medical strap',(.17,-.11,1.18),(.055,.055,.38),n,arm,'spine_03')
    elif kind=='droid':
        ellipsoid('W19 droid chest armour',(0,-.165,1.19),(.32,.085,.25),n,arm,'spine_03',lod)
        box('W19 yellow droid chest stripe',(0,-.212,1.22),(.25,.018,.055),a,arm,'spine_03')
        for s,bone in [(-1,'clavicle_r'),(1,'clavicle_l')]:
            ellipsoid('W19 droid segmented shoulder',(s*.26,-.01,1.315),(.19,.20,.09),a,arm,bone,lod)

def build(kind,lod):
    global LOD
    LOD=lod
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    source=kind if kind in ('sniper','heavy','tech','officer','droid') else 'officer'
    suffix='_lod1' if lod else ''
    bpy.ops.import_scene.gltf(filepath=str(ROOT/f'godot/assets/units/w17/{source}{suffix}.glb'))
    arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
    body=next(o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('output_unwrapped'))
    for o in list(bpy.data.objects):
        if o.type=='MESH' and o!=body:bpy.data.objects.remove(o,do_unlink=True)
    remove_old_head(body)
    M={'tan':mat('painted tan',(.49,.39,.27)),'navy':mat('deep navy',(.045,.105,.19)),'dark':mat('visor black',(.012,.022,.035)),'white':mat('medical off white',(.82,.80,.71)),'accent':mat(kind+' accent',ACC[kind]),'olive':mat('dark olive',(.18,.24,.12)),'glow':mat('photoreceptor yellow',(.92,.78,.25))}
    import_head(kind,arm,lod,M);gear(kind,arm,lod,M)
    # The source materials and animation clips remain in the exported scene.
    dest=OUT/f'{kind}{suffix}.glb'
    bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',export_yup=True,export_animations=False,export_image_format='WEBP')
    print('W19 BUILT',dest)

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else list(CLASSES)
    for kind in args:
        for lod in (False,True):build(kind,lod)
