"""Build staged W19 soldier GLBs with W17 helmets and bone-bound class gear."""
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
    if bevel and not LOD:
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
    bpy.ops.mesh.primitive_uv_sphere_add(segments=6 if lod else 20,ring_count=3 if lod else 12,location=xyz)
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

def sniper_cloak(arm,m):
    # Curved cross sections wrap the back; the narrow hem follows the torso.
    rows=[(1.34,.22,.115),(1.23,.27,.155),(1.08,.28,.215),(.88,.24,.275),(.69,.21,.29)]
    verts=[]
    for z,half,y in rows:
        for u in (-1,-.5,0,.5,1):
            verts.append((u*half,y+.095*(1-u*u)-.065*abs(u),z+.018*(1-u*u)))
    faces=[]
    for row in range(len(rows)-1):
        for col in range(4):
            a=row*5+col;faces.append((a,a+1,a+6,a+5))
    mesh=bpy.data.meshes.new('curved sniper cloak');mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new('W19 dark olive shoulder cloak',mesh)
    bpy.context.collection.objects.link(o);mesh.materials.append(m)
    solid=o.modifiers.new('cloth thickness','SOLIDIFY');solid.thickness=.014
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=solid.name)
    return bind(o,arm,'spine_03')

def remove_old_head(body):
    bm=bmesh.new();bm.from_mesh(body.data)
    kill=[f for f in bm.faces if (body.matrix_world @ f.calc_center_median()).z>1.425]
    bmesh.ops.delete(bm,geom=kill,context='FACES');bm.to_mesh(body.data);bm.free();body.data.update()

def import_head(kind,arm,lod,M):
    # W17's white helmet and visor remain on every human class.
    existing=set(bpy.data.objects)
    if kind=='sniper':
        ellipsoid('W19 low olive hood crown',(0,.025,1.625),(.36,.27,.045),M['olive'],arm,'Head',lod)
        for s in (-1,1):
            ellipsoid('W19 hood side drape',(s*.162,.050,1.524),(.025,.19,.15),M['olive'],arm,'Head',lod)
        ellipsoid('W19 hood back drape',(0,.135,1.510),(.31,.025,.17),M['olive'],arm,'Head',lod)
        cyl('W19 attached scope',(.154,-.155,1.565),.026,.085,M['navy'],arm,'Head',8,axis='Y')
        cyl('W19 scope lens',(.154,-.205,1.565),.019,.012,M['dark'],arm,'Head',8,axis='Y')
    elif kind=='heavy':
        for s in (-1,1):ellipsoid('W19 orange cheek',(s*.16,-.092,1.503),(.045,.11,.13),M['accent'],arm,'Head',lod)
    elif kind=='tech':
        for s in (-1,1):cyl('W19 teal goggle',(s*.078,-.177,1.593),.041,.021,M['accent'],arm,'Head',8,axis='Y')
        cyl('W19 tech antenna',(.163,.057,1.691),.007,.105,M['navy'],arm,'Head',6)
        cyl('W19 antenna tip',(.163,.057,1.747),.012,.018,M['accent'],arm,'Head',6)
    elif kind=='officer':
        ellipsoid('W19 officer cap crown',(0,.015,1.656),(.39,.31,.09),M['navy'],arm,'Head',lod)
        box('W19 crimson cap band',(0,-.134,1.629),(.35,.032,.029),M['accent'],arm,'Head')
        ellipsoid('W19 peaked cap brim',(0,-.159,1.619),(.39,.13,.025),M['navy'],arm,'Head',lod)
    elif kind=='medic':
        ellipsoid('W19 medical forehead panel',(0,-.148,1.612),(.15,.036,.065),M['white'],arm,'Head',lod)
        box('W19 medical cross vertical',(0,-.17,1.612),(.019,.012,.047),M['accent'],arm,'Head')
        box('W19 medical cross horizontal',(0,-.171,1.612),(.053,.012,.018),M['accent'],arm,'Head')
    elif kind=='droid':
        ellipsoid('W19 yellow elongated droid head',(0,-.015,1.562),(.355,.29,.29),M['accent'],arm,'Head',lod)
        ellipsoid('W19 droid faceplate',(0,-.155,1.56),(.29,.035,.16),M['navy'],arm,'Head',lod)
        for s in (-1,1):cyl('W19 droid photoreceptor',(s*.075,-.18,1.594),.026,.015,M['glow'],arm,'Head',10,axis='Y')
        box('W19 droid jaw grille',(0,-.163,1.48),(.17,.022,.035),M['navy'],arm,'Head')
    if kind not in ('droid','medic'):
        for part in set(bpy.data.objects)-existing:
            world=part.matrix_world.copy();world.translation.z-=.07;part.matrix_world=world

def gear(kind,arm,lod,M):
    a=M['accent'];n=M['navy'];t=M['tan'];w=M['white']
    if kind=='heavy':
        for s,bone in [(-1,'clavicle_r'),(1,'clavicle_l')]:
            ellipsoid('W19 curved orange pauldron',(s*.255,.005,1.318),(.23,.24,.105),a,arm,bone,lod)
            ellipsoid('W19 pauldron navy inset',(s*.255,-.105,1.312),(.15,.035,.042),n,arm,bone,lod)
    elif kind=='sniper':
        sniper_cloak(arm,M['olive'])
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
        box('W19 medical satchel',(.235,.015,.97),(.15,.22,.22),w,arm,'pelvis',.035)
        box('satchel red cross vertical',(.235,-.103,.97),(.018,.012,.095),a,arm,'pelvis')
        box('satchel red cross horizontal',(.235,-.104,.97),(.075,.012,.026),a,arm,'pelvis')
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
    if kind=='droid':remove_old_head(body)
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
