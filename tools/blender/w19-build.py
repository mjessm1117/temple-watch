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

def mat(name,c):
    m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=0;p.inputs['Roughness'].default_value=.8
    return m

def bind(o,arm,bone):
    w=o.matrix_world.copy();o.parent=arm;o.parent_type='BONE';o.parent_bone=bone;o.matrix_world=w
    return o

def box(name,xyz,dim,m,arm,bone,bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=xyz);o=bpy.context.object;o.name=name;o.dimensions=dim
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('chamfer','BEVEL');mod.width=bevel;mod.segments=1;bpy.ops.object.modifier_apply(modifier=mod.name)
    o.data.materials.append(m);return bind(o,arm,bone)

def cyl(name,xyz,r,depth,m,arm,bone,vertices=8,axis='Z'):
    rot=(0,0,0) if axis=='Z' else ((math.pi/2,0,0) if axis=='Y' else (0,math.pi/2,0))
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=xyz,rotation=rot)
    o=bpy.context.object;o.name=name;o.data.materials.append(m);return bind(o,arm,bone)

def cape(name,arm,bone,m,wide=.30,long=.48,y=.17):
    verts=[(-wide/2,y,1.33),(wide/2,y,1.33),(-wide*.70,y+.12,1.11),(wide*.70,y+.12,1.11),(-wide*.55,y+.19,1.33-long),(wide*.55,y+.19,1.33-long)]
    faces=[(0,1,3,2),(2,3,5,4)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);mesh.materials.append(m)
    return bind(o,arm,bone)

def remove_old_head(body):
    bm=bmesh.new();bm.from_mesh(body.data)
    kill=[f for f in bm.faces if (body.matrix_world @ f.calc_center_median()).z>1.425]
    bmesh.ops.delete(bm,geom=kill,context='FACES');bm.to_mesh(body.data);bm.free();body.data.update()

def import_head(kind,arm,lod,M):
    previous=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(PREV/f'{kind}-preview.glb'))
    new=[o for o in bpy.data.objects if o not in previous and o.type=='MESH']
    if not new:raise RuntimeError('No Meshy mesh for '+kind)
    if kind=='droid':
        all_z=[(o.matrix_world@v.co).z for o in new for v in o.data.vertices]
        cutoff=min(all_z)+.48*(max(all_z)-min(all_z))
        for o in new:
            bm=bmesh.new();bm.from_mesh(o.data)
            kill=[f for f in bm.faces if (o.matrix_world@f.calc_center_median()).z<cutoff]
            bmesh.ops.delete(bm,geom=kill,context='FACES');bm.to_mesh(o.data);bm.free();o.data.update()
        new=[o for o in new if len(o.data.polygons)]
    points=[o.matrix_world@v.co for o in new for v in o.data.vertices]
    lo=Vector(min(p[i] for p in points) for i in range(3));hi=Vector(max(p[i] for p in points) for i in range(3))
    size=hi-lo;center=(lo+hi)/2
    target_w=.40 if kind!='heavy' else .47;target_d=.37;target_h=.35 if kind=='droid' else .34
    scale=min(target_w/max(size.x,.001),target_d/max(size.y,.001),target_h/max(size.z,.001))
    # Preserve the model's shape. Center the shell above the Trooper neck.
    for o in new:
        world=o.matrix_world.copy();o.parent=None;o.matrix_world=Matrix.Identity(4)
        for v in o.data.vertices:
            q=world@v.co
            v.co=Vector(((q.x-center.x)*scale,(q.y-center.y)*scale-.015,(q.z-center.z)*scale+1.565))
        o.name=f'{kind} Meshy helmet';o.data.materials.clear();o.data.materials.append(M['tan'])
        tris=sum(len(p.vertices)-2 for p in o.data.polygons)
        cap=180 if lod else 850
        if tris>cap:
            mod=o.modifiers.new('phone triangles','DECIMATE');mod.ratio=cap/tris
            bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
        bind(o,arm,'Head')
    # Large flat visor and painted class panels cover the grey preview texture.
    box('navy enclosed visor',(0,-.225,1.575),(.27,.035,.095),M['navy'],arm,'Head',.008 if not lod else 0)
    if kind=='sniper':
        cyl('olive side scope',(.20,-.18,1.624),.047,.18,M['accent'],arm,'Head',6 if lod else 10,axis='Y')
        cyl('scope dark lens',(.20,-.285,1.624),.034,.015,M['navy'],arm,'Head',6,axis='Y')
    elif kind=='heavy':
        for s in (-1,1):box('orange heavy cheek',(s*.19,-.11,1.535),(.085,.16,.15),M['accent'],arm,'Head',.012 if not lod else 0)
    elif kind=='tech':
        for s in (-1,1):cyl('teal goggle',(s*.09,-.26,1.61),.069,.04,M['accent'],arm,'Head',8,axis='Y')
        cyl('tech antenna',(.22,.005,1.76),.013,.28,M['navy'],arm,'Head',6)
        cyl('antenna tip',(.22,.005,1.91),.024,.035,M['accent'],arm,'Head',6)
    elif kind=='officer':
        box('crimson cap brim',(0,-.21,1.70),(.38,.24,.04),M['accent'],arm,'Head',.01 if not lod else 0)
        box('officer crest',(0,-.018,1.79),(.07,.15,.15),M['accent'],arm,'Head')
    elif kind=='medic':
        box('white medical forehead panel',(0,-.235,1.69),(.20,.035,.13),M['white'],arm,'Head')
        box('medical cross vertical',(0,-.261,1.69),(.040,.014,.094),M['accent'],arm,'Head')
        box('medical cross horizontal',(0,-.263,1.69),(.105,.014,.037),M['accent'],arm,'Head')
    elif kind=='droid':
        for s in (-1,1):cyl('yellow droid optic',(s*.085,-.26,1.59),.045,.018,M['accent'],arm,'Head',8,axis='Y')
        box('droid jaw grille',(0,-.22,1.46),(.21,.04,.08),M['navy'],arm,'Head')

def gear(kind,arm,lod,M):
    a=M['accent'];n=M['navy'];t=M['tan'];w=M['white']
    if kind=='heavy':
        for s,bone in [(-1,'clavicle_r'),(1,'clavicle_l')]:
            box('heavy broad pauldron',(s*.28,.02,1.34),(.30,.31,.13),a,arm,bone,.025 if not lod else 0)
            box('pauldron navy inset',(s*.29,-.15,1.35),(.20,.024,.055),n,arm,bone)
    elif kind=='sniper':
        cape('olive shoulder ghillie cloak',arm,'spine_03',a,.46,.52,.16)
        if not lod:
            for x in (-.18,-.08,.04,.15):box('cloak strip',(x,.31,1.01),(.038,.05,.23),a,arm,'spine_03')
    elif kind=='tech':
        for s in (-1,1):
            box('tool harness strap',(s*.18,-.12,1.15),(.065,.065,.34),n,arm,'spine_03')
            box('teal tool pod',(s*.25,.02,1.09),(.13,.14,.22),a,arm,'spine_03',.012 if not lod else 0)
        box('harness waist buckle',(0,-.20,1.02),(.23,.055,.09),t,arm,'spine_03')
    elif kind=='officer':
        cape('officer short crimson cape',arm,'spine_03',a,.35,.53,.16)
        box('rank plate',(0,-.18,1.23),(.19,.035,.09),a,arm,'spine_03')
        for x in (-.04,0,.04):box('rank bar',(x,-.204,1.23),(.020,.012,.05),w,arm,'spine_03')
    elif kind=='medic':
        box('medical satchel',(.30,.11,.99),(.23,.20,.28),w,arm,'pelvis',.012 if not lod else 0)
        box('satchel red cross vertical',(.43,.11,1.00),(.014,.04,.12),a,arm,'pelvis')
        box('satchel red cross horizontal',(.44,.11,1.00),(.014,.12,.04),a,arm,'pelvis')
        box('medical strap',(.17,-.11,1.18),(.055,.055,.38),n,arm,'spine_03')
    elif kind=='droid':
        box('droid chest armour',(0,-.19,1.19),(.32,.09,.25),t,arm,'spine_03',.018 if not lod else 0)
        box('yellow droid chest stripe',(0,-.245,1.22),(.25,.025,.055),a,arm,'spine_03')
        for s,bone in [(-1,'clavicle_r'),(1,'clavicle_l')]:
            box('droid segmented shoulder',(s*.27,-.02,1.33),(.20,.22,.10),a,arm,bone)

def build(kind,lod):
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    source=kind if kind in ('sniper','heavy','tech','officer','droid') else 'officer'
    suffix='_lod1' if lod else ''
    bpy.ops.import_scene.gltf(filepath=str(ROOT/f'godot/assets/units/w17/{source}{suffix}.glb'))
    arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
    body=next(o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('output_unwrapped'))
    remove_old_head(body)
    M={'tan':mat('painted tan',(.59,.46,.31)),'cream':mat('painted cream',(.83,.77,.65)),'navy':mat('deep navy',(.045,.105,.19)),'white':mat('medical off white',(.90,.88,.80)),'accent':mat(kind+' accent',ACC[kind])}
    import_head(kind,arm,lod,M);gear(kind,arm,lod,M)
    # The source materials and animation clips remain in the exported scene.
    dest=OUT/f'{kind}{suffix}.glb'
    bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',export_yup=True,export_animations=False,export_image_format='WEBP')
    print('W19 BUILT',dest)

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else list(CLASSES)
    for kind in args:
        for lod in (False,True):build(kind,lod)
