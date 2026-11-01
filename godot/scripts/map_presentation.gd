extends Node3D
## Drop-in map renderer: build(mission, model_cache). Geometry remains mission-owned.
const Maps = preload("res://scripts/map_catalog.gd")
const Shot = preload("res://scripts/shot.gd")
var themes: Dictionary = Maps.read("res://data/maps/themes.json")
var props: Dictionary = Maps.read("res://data/maps/props.json")
var cache: Dictionary = {}
var palette: Dictionary = {}
var marker_root: Node3D

func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = color; m.roughness = 0.85
	if glow > 0.0: m.emission_enabled = true; m.emission = color; m.emission_energy_multiplier = glow
	return m

func box(at: Vector3, size: Vector3, mat: Material, parent: Node3D = self) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size = size
	var node := MeshInstance3D.new(); node.mesh = mesh; node.material_override = mat; node.position = at; parent.add_child(node)
	return node

func color(value: int) -> Color:
	return Color(float((value>>16)&255)/255.0,float((value>>8)&255)/255.0,float(value&255)/255.0)

func apply_environment(world: WorldEnvironment, key: DirectionalLight3D, theme_name: String) -> void:
	var t: Dictionary = themes.get(theme_name,themes.dock)
	var env := Environment.new(); env.background_mode = Environment.BG_SKY
	var sky := Sky.new(); var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = color(int(t.sky[0])); sky_material.sky_horizon_color = color(int(t.sky[1]))
	sky_material.ground_bottom_color = color(int(t.ground)); sky_material.ground_horizon_color = color(int(t.fog[0]))
	sky.sky_material = sky_material; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = color(int(t.hemi[0])); env.ambient_light_energy = float(t.hemi[2])*0.4
	env.ssao_enabled = true; env.ssao_intensity = 0.75; env.ssao_radius = 1.3
	env.tonemap_mode = Environment.TONE_MAPPER_ACES; env.tonemap_exposure = float(t.exp)
	env.fog_enabled = true; env.fog_light_color = color(int(t.fog[0])); env.fog_density = 0.002
	world.environment = env; key.light_color = color(int(t.key[0])); key.light_energy = float(t.key[1])*0.55; key.shadow_enabled = true
	key.rotation_degrees = Vector3(-55,-32,0)

func build(m: RefCounted, _models: Dictionary = {}) -> void:
	for child in get_children(): remove_child(child); child.queue_free()
	var t: Dictionary = themes.get(str(m.spec.get("theme","dock")),themes.dock)
	palette = {"floor":material(Color(t.floor[0])),"alt":material(Color(t.floor[1])),"wall":material(color(int(t.wall))),"cover":material(color(int(t.crate))),"high":material(color(int(t.wallTop))),"evac":material(Color("51cce0"),1.3),"objective":material(Color("e3bd73"),0.4),"ground":material(color(int(t.ground))),"water":material(Color("234e69"))}
	box(Vector3(float(m.spec.width)/2,-0.6,float(m.spec.height)/2),Vector3(m.spec.width+16,0.3,m.spec.height+16),palette.ground)
	var tile_props: Dictionary = props.tile_props
	var wall_name := "wall_" + str(props.wall_of.get(m.spec.get("theme","dock"),m.spec.get("theme","dock")))
	var buckets: Dictionary = {}
	for y in int(m.spec.height):
		for x in int(m.spec.width):
			var p := Vector2i(x,y); var c: String = m.tile(p); var level := Shot.elevation(m,p)*0.7
			var key := "water" if c == "w" else "evac" if c == "E" else "high" if level > 0 else "floor" if (x+y)%2 == 0 else "alt"
			if not buckets.has(key): buckets[key] = []
			buckets[key].append(Transform3D(Basis.from_scale(Vector3(0.98,0.2+level,0.98)),Vector3(x,level/2.0-0.12,y)))
			if c == "#":
				# Lower boundary blocks keep an overview readable.
				var height := 0.55 if x in [0,int(m.spec.width)-1] or y in [0,int(m.spec.height)-1] else 2.1
				if not prop(wall_name,Vector3(x,level,y),0.95,height): box(Vector3(x,level+height/2,y),Vector3(0.95,height,0.95),palette.wall)
			elif tile_props.has(c):
				var height := 0.8 if c in ["c","h","r"] else 1.0
				var kind := str(m.spec.get("prop_overrides",{}).get(p,tile_props[c]))
				if not prop(kind,Vector3(x,level,y),0.85,height): box(Vector3(x,level+height/2,y),Vector3(0.8,height,0.8),palette.cover)
	for key in buckets:
		var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = BoxMesh.new(); mm.instance_count = buckets[key].size()
		for i in mm.instance_count: mm.set_instance_transform(i,buckets[key][i])
		var node := MultiMeshInstance3D.new(); node.multimesh = mm; node.material_override = palette[key]; add_child(node)
	# Objective props are markers, never invisible collision.
	if m.modern:
		for at in m.spec.objective.points:
			var p := Maps.point(at)
			var kind := "relay" if m.spec.family in ["destroy_relay","defend"] else "terminal"
			if m.spec.family not in ["rescue","vip_extract","retaliation","operation"]: prop(kind,Vector3(p.x,0,p.y),0.7,1.15)
	var random := RandomNumberGenerator.new(); random.seed = str(m.spec.get("id","rescue")).hash()
	for kind in t.props:
		for i in mini(6,int(t.props[kind])):
			var at := Vector3(random.randf_range(-5,float(m.spec.width)+4),0,-3-random.randf_range(0,4))
			if i%2: at = Vector3(-3-random.randf_range(0,3),0,random.randf_range(0,m.spec.height))
			if not prop(str(kind),at,1.4,3.0): scenery(str(kind),at,t,random)
	var rim := DirectionalLight3D.new(); rim.light_color = color(int(t.rim[0])); rim.light_energy = float(t.rim[1])*0.4
	rim.rotation_degrees = Vector3(-30,135,0); add_child(rim)
	weather(t.part,int(m.spec.width),int(m.spec.height))
	marker_root = Node3D.new(); add_child(marker_root); refresh_markers(m)

func prop(kind: String, at: Vector3, width: float, height: float) -> bool:
	var path := "res://assets/maps/%s.glb" % kind
	if not ResourceLoader.exists(path): return false
	if not cache.has(kind): cache[kind] = load(path)
	var instance: Node3D = cache[kind].instantiate()
	var bounds := bounds_of(instance,Transform3D.IDENTITY)
	if bounds.size.length() <= 0.001: instance.free(); return false
	var factor := width/maxf(bounds.size.x,bounds.size.z)
	var scale_y := height/bounds.size.y
	instance.scale = Vector3(factor,scale_y,factor)
	instance.position = at-Vector3(bounds.get_center().x*factor,bounds.position.y*scale_y,bounds.get_center().z*factor)
	add_child(instance)
	return true

func bounds_of(node: Node3D, transform: Transform3D) -> AABB:
	transform = transform*node.transform
	var out := AABB(); var first := true
	if node is MeshInstance3D and node.mesh != null: out = transform*node.mesh.get_aabb(); first = false
	for child in node.get_children():
		if not child is Node3D: continue
		var bounds := bounds_of(child,transform)
		if bounds.size.length() == 0: continue
		out = bounds if first else out.merge(bounds); first = false
	return out

func scenery(kind: String, at: Vector3, t: Dictionary, random: RandomNumberGenerator) -> void:
	var mesh := CylinderMesh.new(); mesh.top_radius = 0; mesh.bottom_radius = 0.6
	mesh.height = random.randf_range(0.6,3.0) if kind in ["tree","pine","stalag","tower"] else 0.6
	var node := MeshInstance3D.new(); node.mesh = mesh; node.position = at+Vector3.UP*mesh.height/2
	node.material_override = material(color(int(t.wallTop)) if kind not in ["tree","fern","grass"] else Color("3f6a2e")); add_child(node)

func overwatch_zones(m: RefCounted) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u in m.units:
		if int(u.hp) <= 0 or float(u.range) < 2.0 or not bool(u.overwatch) or (u.side == "enemy" and not bool(u.spotted)): continue
		for y in int(m.spec.height):
			for x in int(m.spec.width):
				var p := Vector2i(x,y)
				if p != Shot.pos(u) and m.passable(p) and Shot.distance(Shot.pos(u),p) <= float(u.range) and Shot.los(m,Shot.pos(u),p): out.append({"at":p,"side":u.side,"unit":u.id})
	return out

func refresh_markers(m: RefCounted) -> void:
	if marker_root == null: return
	for child in marker_root.get_children(): marker_root.remove_child(child); child.queue_free()
	var amber := material(Color("dfae53"),0.5); var red := material(Color("e76858"),0.5)
	for zone in overwatch_zones(m):
		var p: Vector2i = zone.at
		box(Vector3(p.x,Shot.elevation(m,p)*0.7+0.02,p.y),Vector3(0.72,0.03,0.72),amber if zone.side == "player" else red,marker_root)
	for p in m.interactables(): box(Vector3(p.x,0.07,p.y),Vector3(0.9,0.05,0.9),palette.objective,marker_root)
	if m.modern:
		if m.spec.family == "operation" and m.objective_state.phase == "primary":
			var step: Dictionary = preload("res://scripts/mission_objectives.gd").current_step(m)
			if step.has("at"):
				var at := Maps.point(step.at); var radius := int(step.get("radius",1))
				for y in range(at.y-radius,at.y+radius+1):
					for x in range(at.x-radius,at.x+radius+1):
						var p := Vector2i(x,y)
						if m.passable(p): box(Vector3(x,Shot.elevation(m,p)*0.7+0.05,y),Vector3(0.8,0.04,0.8),palette.objective,marker_root)
		for wave in m.pressure_state.pending:
			var p := Maps.point(wave.at)
			box(Vector3(p.x,0.12,p.y),Vector3(2.6,0.06,2.6),red,marker_root)

func weather(settings: Dictionary, width: int, height: int) -> void:
	var node := GPUParticles3D.new(); node.amount = int(settings.n); node.lifetime = 12.0
	node.visibility_aabb = AABB(Vector3(-4,-2,-4),Vector3(width+8,12,height+8))
	node.position = Vector3(float(width)/2,3,float(height)/2)
	var process := ParticleProcessMaterial.new(); process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(float(width)/2+2,3,float(height)/2+2)
	var kind := str(settings.kind)
	var fall := 9.0 if kind == "rain" else 0.6 if kind == "snow" else -0.4 if kind == "ember" else 0.05
	process.direction = Vector3.DOWN if fall >= 0 else Vector3.UP; process.spread = 8.0 if kind == "rain" else 60.0
	process.initial_velocity_min = absf(fall)*0.5; process.initial_velocity_max = absf(fall); process.gravity = Vector3.ZERO
	process.scale_min = 0.5; process.scale_max = 1.0
	node.process_material = process
	var mesh := QuadMesh.new(); mesh.size = Vector2(0.035,0.4) if kind == "rain" else Vector2(0.075,0.075)
	var mat := material(color(int(settings.color)),0.6 if kind in ["firefly","ember"] else 0.0)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat; node.draw_pass_1 = mesh; add_child(node)
