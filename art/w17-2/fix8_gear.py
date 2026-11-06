"""Original low-poly W17 armory gear. Run: blender -b --factory-startup --python art/w17-2/fix8_gear.py

Exports temporary, unrigged GLBs. fix6.mjs binds their named parts to the Trooper bones.
Gun coordinates: +Z muzzle, -X top, +Y right side. Blender conversion is baked
into mesh vertices so the glTF node positions use the same coordinate frame.
"""
import bpy
from mathutils import Vector
from pathlib import Path

OUT = Path('/tmp/w17-fix8-gear')
OUT.mkdir(exist_ok=True)
ACCENTS = {
    'sniper': (.30,.38,.20), 'heavy': (.70,.33,.10),
    'tech': (.10,.45,.48), 'droid': (.80,.66,.15),
    'officer': (.55,.10,.12),
}

def mat(name, rgb, metal=0.0, glow=0.0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*rgb,1)
    m.use_nodes=True; p=m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value=(*rgb,1)
    p.inputs['Metallic'].default_value=metal
    p.inputs['Roughness'].default_value=.76
    if glow:
        p.inputs['Emission Color'].default_value=(*rgb,1)
        p.inputs['Emission Strength'].default_value=glow
    return m

def C(p): return (p[0],-p[2],p[1])

def finish(obj,name,loc,material):
    obj.name=name; obj.location=C(loc); obj.data.materials.append(material)
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    return obj

def box(name,loc,size,material,bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1)
    o=bpy.context.object; o.dimensions=(size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        m=o.modifiers.new('cut edges','BEVEL');m.width=bevel;m.segments=1
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=m.name)
        w=o.modifiers.new('weighted corners','WEIGHTED_NORMAL')
        bpy.ops.object.modifier_apply(modifier=w.name)
    return finish(o,name,loc,material)

def tube(name,loc,radius,length,material,vertices=8):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=length,location=C(loc),rotation=(1.57079632679,0,0))
    return finish(bpy.context.object,name,loc,material)

def link(name,a,b,radius,material,vertices=6):
    aa,bb=Vector(C(a)),Vector(C(b)); mid=(aa+bb)/2
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=(bb-aa).length)
    o=bpy.context.object;o.rotation_euler=(bb-aa).to_track_quat('Z','Y').to_euler()
    o.location=mid;o.name=name;o.data.materials.append(material)
    return o

def materials(kind):
    return [mat('matte gunmetal',(.105,.125,.145),.35),
            mat('brushed edge metal',(.36,.39,.40),.45),
            mat('dark inset',(.025,.035,.045),.1),
            mat(kind+' accent',ACCENTS[kind],.1),
            mat('low power emitter',(.15,.68,.82),.1,1.5)]

def gun(kind,lod,M):
    g,e,d,a,lit=M; low=lod==1
    B=lambda n,p,s,m=g,v=0:box(n,p,s,m,v if not low else 0)
    T=lambda n,p,r,l,m=g,verts=8:tube(n,p,r,l,m,6 if low else verts)
    # All grips center around the right palm. Receiver and muzzle names are
    # deliberate: the existing w17_art4_test reads their node origins.
    if kind=='sniper':
        B('precision blaster receiver',(0,0,0),(.17,.18,.32),g,.018)
        B('upper receiver rail',(-.115,0,.04),(.035,.15,.38),e)
        T('long scoped barrel',(0,0,.47),.041,.66,e,10)
        T('barrel bore',(0,0,.80),.019,.09,d)
        T('muzzle brake',(0,0,.85),.059,.12,g,10)
        B('muzzle side port',(-.01,.061,.85),(.035,.012,.055),d)
        B('precision blaster stock',(.015,0,-.36),(.16,.17,.36),g,.018)
        B('stock butt',(.005,0,-.55),(.23,.20,.045),e)
        B('palm grip',(.14,0,-.085),(.23,.095,.105),d,.012)
        B('angled magazine',(.19,.015,.13),(.23,.10,.10),e,.01)
        B('scope rail',(-.15,0,-.005),(.035,.10,.33),d)
        T('scope optic',(-.225,0,.015),.073,.33,g,10)
        T('scope front lens',(-.225,0,.19),.052,.025,lit)
        T('scope rear ring',(-.225,0,-.16),.081,.035,e)
        if not low:
            for side in (-1,1):
                B('scope clamp',(-.17,side*.055,.045),(.07,.018,.055),e)
                link('folded bipod leg',(.045,side*.075,.48),(.10,side*.12,.19),.012,e)
                B('bipod foot',(.10,side*.12,.19),(.018,.055,.035),d)
            for z in (.31,.42,.53):B('barrel cooling rib',(.016,.044,z),(.025,.015,.025),d)
        B('single olive stripe',(-.102,0,-.30),(.018,.15,.09),a)
    elif kind=='heavy':
        B('repeater body',(0,0,0),(.25,.28,.43),g,.025)
        B('repeater upper armor',(-.15,0,.07),(.065,.25,.48),e,.012)
        T('barrel core',(0,0,.44),.07,.56,d,10)
        T('thick barrel shroud',(0,0,.45),.115,.42,g,10)
        T('rotary muzzle',(0,0,.73),.085,.13,e,10)
        T('muzzle bore',(0,0,.80),.042,.028,d)
        B('repeater handle',(.17,0,-.16),(.27,.12,.13),d,.012)
        B('side box mag',(.035,.20,.08),(.23,.14,.30),e,.012)
        B('magazine face',(.03,.275,.08),(.17,.012,.24),d)
        link('carry handle front',(-.16,-.12,.34),(-.29,-.12,.26),.022,e)
        link('carry handle back',(-.16,-.12,-.15),(-.29,-.12,-.09),.022,e)
        B('carry handle rail',(-.29,-.12,.085),(.035,.04,.40),e)
        if not low:
            for z in (.28,.37,.46,.55,.64):
                for side in (-1,1):B('shroud cooling vent',(-.06,side*.098,z),(.065,.013,.034),d)
            for side in (-1,1):B('muzzle fin',(-.015,side*.095,.72),(.07,.025,.10),g)
        B('single orange stripe',(-.19,0,-.085),(.014,.22,.08),a)
    elif kind=='tech':
        B('carbine receiver',(0,0,0),(.19,.18,.33),g,.018)
        B('carbine top rail',(-.12,0,.04),(.035,.14,.38),e)
        T('carbine barrel',(0,0,.37),.047,.45,e)
        T('carbine muzzle',(0,0,.62),.06,.09,g)
        B('carbine stock',(.015,0,-.30),(.12,.14,.30),g,.01)
        B('palm grip',(.15,0,-.09),(.24,.095,.09),d,.01)
        B('angled cell magazine',(.16,.02,.09),(.22,.10,.12),e,.01)
        B('tool emitter housing',(.13,0,.36),(.105,.15,.28),d,.01)
        T('tool emitter lens',(.13,0,.52),.046,.035,lit)
        if not low:
            for side in (-1,1):
                B('tool heat sink',(.12,side*.086,.29),(.08,.012,.10),e)
                B('receiver vent',(-.04,side*.094,.10),(.025,.012,.08),d)
        B('single teal stripe',(-.115,0,-.17),(.015,.14,.065),a)
    elif kind=='droid':
        B('droid blaster receiver',(0,0,0),(.23,.23,.37),g,.022)
        B('reinforced top casing',(-.15,0,.04),(.07,.23,.39),e,.01)
        T('droid blaster barrel',(0,0,.38),.075,.45,e,10)
        T('muzzle port',(0,0,.62),.085,.10,g,10)
        T('bore',(0,0,.68),.042,.025,d)
        B('droid blaster stock',(.02,0,-.28),(.16,.17,.25),g,.01)
        B('palm grip',(.15,0,-.07),(.22,.10,.09),d,.01)
        B('side power cell',(.04,.145,-.05),(.17,.08,.19),e,.01)
        if not low:
            for z in (.17,.23,.29,.35):T('exposed induction coil',(0,0,z),.10,.025,e,10)
            for side in (-1,1):B('coil guard',(-.03,side*.13,.26),(.04,.025,.29),g)
        else:
            for z in (.21,.32):T('exposed induction coil',(0,0,z),.10,.035,e,6)
        B('single yellow stripe',(-.19,0,-.13),(.014,.20,.07),a)
    else:
        B('officer pistol receiver',(0,0,0),(.16,.14,.25),g,.016)
        B('pistol slide',(-.095,0,.065),(.07,.15,.35),e,.01)
        T('officer pistol barrel',(0,0,.25),.045,.39,g,10)
        T('pistol muzzle',(0,0,.46),.057,.075,e)
        T('bore',(0,0,.50),.025,.02,d)
        B('officer pistol grip',(.16,0,-.095),(.27,.105,.11),d,.012)
        B('grip heel',(.30,0,-.12),(.04,.125,.14),e)
        B('trigger guard',(.10,0,.065),(.10,.025,.10),e)
        B('rear sight',(-.15,0,-.07),(.045,.12,.03),d)
        if not low:
            for side in (-1,1):B('slide vent',(-.11,side*.076,.16),(.03,.01,.045),d)
        B('single crimson stripe',(-.135,0,-.06),(.012,.12,.045),a)

def pack(kind,lod,M):
    g,e,d,a,lit=M;low=lod==1
    B=lambda n,p,s,m=g,v=0:box(n,p,s,m,v if not low else 0)
    T=lambda n,p,r,l,m=g,verts=8:tube(n,p,r,l,m,6 if low else verts)
    # Pack uses bone-local coordinates directly; near the old spine_03 gear.
    if kind=='heavy':
        B('rocket backpack frame',(0,-.13,-.20),(.37,.37,.13),g,.02)
        for side in (-1,1):
            y=side*.16
            T('rocket tube',(0,y,-.18),.10,.43,g,10)
            T('rocket tube opening',(0,y,.052),.071,.025,d)
            T('tube collar',(0,y,-.37),.113,.055,e)
            B('rocket strap',(.015,y*.55,-.11),(.28,.034,.065),e)
            if not low:
                for z in (-.28,-.05):B('tube retaining band',(-.08,y,z),(.025,.20,.045),e)
        B('single orange pack stripe',(-.195,0,-.20),(.014,.27,.07),a)
    else:
        B('tool battery backpack',(0,0,-.20),(.36,.32,.18),g,.02)
        B('backpack rear panel',(-.19,0,-.20),(.025,.27,.31),e)
        for side in (-1,1):
            T('pack battery',(-.03,side*.105,-.17),.055,.35,e)
            B('cell clamp',(-.105,side*.105,-.25),(.035,.13,.055),d)
            B('shoulder strap',(.035,side*.19,-.13),(.34,.028,.06),d)
        B('pack indicator',(-.21,.105,-.04),(.016,.035,.05),lit)
        B('single teal pack stripe',(-.215,-.055,-.30),(.014,.10,.04),a)
        # Cabled jack exits the pack toward the weapon side. The cable is a
        # short molded loop; the animated hand remains free to move.
        link('battery cable',(-.04,.19,-.10),(.08,.28,-.20),.014,d)
        link('battery cable',(.08,.28,-.20),(.04,.26,-.34),.014,d)

for kind in ACCENTS:
    for lod in (0,1):
        bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
        M=materials(kind);gun(kind,lod,M)
        bpy.ops.export_scene.gltf(filepath=str(OUT/f'{kind}-weapon-lod{lod}.glb'),export_format='GLB',use_selection=False,export_apply=True,export_yup=True)
        if kind in ('heavy','tech'):
            bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
            pack(kind,lod,M)
            bpy.ops.export_scene.gltf(filepath=str(OUT/f'{kind}-pack-lod{lod}.glb'),export_format='GLB',use_selection=False,export_apply=True,export_yup=True)
        print('FIX8',kind,lod)
