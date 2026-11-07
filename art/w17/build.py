import bpy, sys, math
from mathutils import Matrix

kind, source, output, lod = sys.argv[sys.argv.index('--')+1:]
lod = bool(int(lod))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=source)
arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
char = next(o for o in bpy.data.objects if o.type == 'MESH' and o.parent == arm and len(o.data.vertices) > 1000)
if arm.animation_data:
    arm.animation_data.action = None
for pose_bone in arm.pose.bones:
    pose_bone.matrix_basis.identity()
bpy.context.scene.frame_set(0)

colors = {
    'navy': (.035,.073,.13,1), 'tan': (.46,.32,.17,1),
    'cream': (.77,.70,.53,1), 'steel': (.16,.20,.24,1),
    'gold': (.65,.44,.13,1), 'dark': (.045,.05,.06,1)
}
mats = {}
for name, col in colors.items():
    m = bpy.data.materials.new(name)
    m.diffuse_color = col
    m.use_nodes = True
    m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value = col
    m.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value = .82
    mats[name] = m
gear = []
def attach(o, bone):
    # Gear stays in the model root. The target bone is kept in its name for
    # downstream attachment when the class is wired into battle.
    o.name = o.name + '__' + bone
    gear.append(o)
    return o

def box(name, loc, dims, mat, bone):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o=bpy.context.object; o.name=name
    o.dimensions=dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(mats[mat]); return attach(o,bone)

def cylinder(name, loc, radius, depth, mat, bone, vertices=8, axis='Y'):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    o=bpy.context.object; o.name=name
    if axis=='Y': o.rotation_euler[0]=math.pi/2
    elif axis=='X': o.rotation_euler[1]=math.pi/2
    o.data.materials.append(mats[mat]); return attach(o,bone)

if kind == 'sniper':
    b='hand_r'
    box('precision blaster receiver',(-.54,-.29,1.02),(.13,.53,.12),'navy',b)
    box('precision blaster stock',(-.54,.07,1.00),(.12,.28,.12),'tan',b)
    box('precision blaster foregrip',(-.54,-.57,.98),(.10,.24,.10),'cream',b)
    cylinder('long scoped barrel',(-.54,-.86,1.02),.027,.86,'steel',b)
    cylinder('muzzle brake',(-.54,-1.30,1.02),.043,.11,'dark',b)
    box('scope rail',(-.54,-.37,1.12),(.045,.40,.025),'steel',b)
    cylinder('scope optic',(-.54,-.38,1.17),.047,.34,'dark',b,12)
    cylinder('scope front lens',(-.54,-.56,1.17),.05,.018,'gold',b,12)
    box('trigger guard',(-.54,-.19,.90),(.025,.11,.09),'steel',b)
    box('pistol holster silhouette',(.23,-.04,.81),(.085,.13,.20),'navy','pelvis')
else:
    b='hand_r'
    box('repeater body',(-.62,-.28,.96),(.29,.46,.28),'navy',b)
    cylinder('rotary drum',(-.62,-.62,.96),.145,.28,'tan',b,12)
    for i in range(6):
        theta=i*math.tau/6
        x=-.62+.09*math.cos(theta); z=.96+.09*math.sin(theta)
        cylinder('rotary barrel %d'%i,(x,-.94,z),.023,.50,'steel',b,8)
        cylinder('muzzle ring %d'%i,(x,-1.19,z),.028,.025,'dark',b,8)
    cylinder('rotary muzzle',(-.62,-1.21,.96),.12,.035,'cream',b,12)
    box('repeater handle',(-.62,-.03,.80),(.075,.11,.24),'steel',b)
    box('rocket backpack',(.0,.25,1.38),(.45,.22,.48),'navy','spine_03')
    for x in [-.17,.17]:
        cylinder('rocket tube', (x,.29,1.55),.085,.48,'cream','spine_03',12)
        cylinder('rocket tube opening',(x,.045,1.55),.062,.025,'dark','spine_03',12)

if lod:
    # Character carries most of the triangles; retain the class-defining gun shapes.
    mod = char.modifiers.new('Phone low LOD', 'DECIMATE')
    mod.ratio = .14
    bpy.context.view_layer.objects.active = char
    bpy.ops.object.modifier_apply(modifier=mod.name)
    # Simplify the separate gear too, while keeping recognizable barrel circles.
    for o in gear:
        if len(o.data.polygons) > 12:
            mod=o.modifiers.new('Low LOD gear','DECIMATE'); mod.ratio=.65
            bpy.context.view_layer.objects.active=o
            bpy.ops.object.modifier_apply(modifier=mod.name)

bpy.ops.object.select_all(action='DESELECT')
arm.select_set(True); char.select_set(True)
for o in gear: o.select_set(True)
bpy.context.view_layer.objects.active=arm
bpy.ops.export_scene.gltf(filepath=output, export_format='GLB', use_selection=True,
    export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
    export_materials='EXPORT', export_apply=False)
print('BUILT',kind,output,'lod',lod,'character_tris',len(char.data.loop_triangles),
      'gear_tris',sum(len(o.data.loop_triangles) for o in gear),'actions',len(bpy.data.actions))
