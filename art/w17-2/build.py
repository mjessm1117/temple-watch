import bpy, sys, math
kind, source, output, lod_flag = sys.argv[sys.argv.index('--')+1:]
lod = bool(int(lod_flag))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=source)
arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
char = max((o for o in bpy.data.objects if o.type == 'MESH' and o.parent == arm), key=lambda o: len(o.data.vertices))
if arm.animation_data: arm.animation_data.action = None
for bone in arm.pose.bones: bone.matrix_basis.identity()
bpy.context.scene.frame_set(0)
colors={'navy':(.035,.073,.13,1),'tan':(.50,.38,.22,1),'cream':(.78,.70,.53,1),'steel':(.16,.20,.24,1),'gold':(.65,.44,.13,1),'dark':(.04,.05,.06,1),'blue':(.08,.16,.28,1)}
mats={}
for name,col in colors.items():
 m=bpy.data.materials.new(name);m.diffuse_color=col;m.use_nodes=True
 m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=col
 m.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.82;mats[name]=m
gear=[]
if kind in ['tech','droid']:
 # Meshy's densely packed atlas mottles at phone distance. Assign broad,
 # geometry-based panels so each triangle has one matte Temple Security color.
 for name in ['navy','tan','cream']:
  char.data.materials.append(mats[name])
 first=len(char.data.materials)-3
 for face in char.data.polygons:
  x,y,z=face.center
  a=abs(x)
  if kind=='tech':
   key='cream' if z>157 else ('cream' if a>24 else 'tan') if z>124 else ('tan' if a>26 else 'navy') if z>108 else ('cream' if a>25 else 'navy') if z>86 else ('navy' if a>15 else 'tan') if z>58 else 'navy' if z>40 else 'cream'
  else:
   key='cream' if z>157 else ('cream' if a>24 else 'tan') if z>125 else ('navy' if a>26 else 'cream') if z>108 else ('tan' if a>26 else 'navy') if z>87 else 'tan' if z>60 else 'navy' if z>40 else 'cream'
  face.material_index=first+['navy','tan','cream'].index(key)
def attach(o,bone):
 o.name=o.name+'__'+bone;gear.append(o);return o
def box(name,loc,dims,mat,bone):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=dims
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mats[mat]);return attach(o,bone)
def cylinder(name,loc,radius,depth,mat,bone,vertices=8,axis='Y'):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc);o=bpy.context.object;o.name=name
 if axis=='Y':o.rotation_euler[0]=math.pi/2
 elif axis=='X':o.rotation_euler[1]=math.pi/2
 o.data.materials.append(mats[mat]);return attach(o,bone)
if kind=='tech':
 b='hand_r';box('carbine receiver',(-.43,-.26,1.0),(.13,.32,.13),'navy',b)
 box('carbine stock',(-.43,.02,1.0),(.11,.20,.10),'tan',b)
 cylinder('carbine barrel',(-.43,-.56,1.0),.026,.40,'steel',b)
 box('carbine battery',(-.43,-.33,.88),(.10,.12,.15),'cream',b)
 box('carbine sight',(-.43,-.28,1.09),(.04,.13,.035),'gold',b)
 box('tool battery backpack',(0,.24,1.37),(.34,.21,.38),'navy','spine_03')
 for x in [-.10,.10]:box('pack battery',(x,.365,1.38),(.11,.07,.26),'cream','spine_03')
 box('wrist computer',(.38,-.05,1.10),(.13,.14,.065),'blue','lowerarm_l')
 box('wrist screen',(.38,-.082,1.145),(.08,.08,.008),'gold','lowerarm_l')
elif kind=='droid':
 b='hand_r';box('droid blaster receiver',(-.42,-.25,1.04),(.13,.33,.12),'navy',b)
 cylinder('droid blaster barrel',(-.42,-.54,1.04),.028,.40,'steel',b)
 box('droid blaster stock',(-.42,.03,1.04),(.10,.18,.10),'cream',b)
 box('shoulder module mount',(.29,.01,1.52),(.22,.18,.12),'navy','clavicle_l')
 cylinder('module socket',(.29,-.095,1.54),.075,.028,'gold','clavicle_l',12)
 cylinder('module core',(.29,-.12,1.54),.042,.03,'blue','clavicle_l',12)
 box('droid visor', (0,-.135,1.69),(.22,.035,.055),'blue','Head')
else:
 b='hand_r';box('officer pistol receiver',(-.40,-.24,1.03),(.11,.22,.11),'navy',b)
 cylinder('officer pistol barrel',(-.40,-.43,1.03),.024,.20,'steel',b)
 box('officer pistol grip',(-.40,-.15,.91),(.075,.08,.19),'tan',b)
 box('short command cape',(.31,.13,1.24),(.30,.045,.48),'blue','spine_03')
 box('sash diagonal',(-.07,-.135,1.28),(.11,.035,.44),'blue','spine_03').rotation_euler[1]=-.48
 box('comlink',(.36,-.04,1.10),(.11,.10,.05),'navy','lowerarm_l')
 box('comlink indicator',(.36,-.07,1.13),(.05,.05,.012),'gold','lowerarm_l')
if lod:
 mod=char.modifiers.new('Phone low LOD','DECIMATE');mod.ratio=.14
 bpy.context.view_layer.objects.active=char;bpy.ops.object.modifier_apply(modifier=mod.name)
 for o in gear:
  if len(o.data.polygons)>12:
   mod=o.modifiers.new('Low LOD gear','DECIMATE');mod.ratio=.65
   bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.ops.object.select_all(action='DESELECT')
arm.select_set(True);char.select_set(True)
for o in gear:o.select_set(True)
bpy.context.view_layer.objects.active=arm
bpy.ops.export_scene.gltf(filepath=output,export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_materials='EXPORT',export_apply=False)
print('BUILT',kind,output,'lod',lod,'char_tris',len(char.data.loop_triangles),'gear_tris',sum(len(o.data.loop_triangles) for o in gear))
