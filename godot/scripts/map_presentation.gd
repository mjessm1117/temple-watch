extends Node3D
## One read-only art renderer for the rescue fixture and all campaign biomes.
const Maps = preload("res://scripts/map_catalog.gd")
const Shot = preload("res://scripts/shot.gd")
const Batch = preload("res://scripts/graphics_batch.gd")
const Meshy = preload("res://scripts/meshy_theme_models.gd")
const Geometry = preload("res://scripts/map_art_geometry.gd")
const STONE = preload("res://assets/env/stone.gdshader")
const TERRAIN = preload("res://assets/env/terrain.gdshader")
var themes: Dictionary = Maps.read("res://data/maps/themes.json")
var props: Dictionary = Maps.read("res://data/maps/props.json")
var palette: Dictionary = {}
var batch = Batch.new()
var theme := "temple"
var interior_full_cover := false
var mission: RefCounted
var floor_bounds: Dictionary = {}
var access_tiles: Dictionary = {}
var marker_root: Node3D
var damage_root: Node3D
var damage_hash := 0
var marker_hash := 0
var tick := 0.0
var game: Node
var scar_texture: ImageTexture

func material(value: Color, glow: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new(); mat.albedo_color = value; mat.roughness = 0.85
	if glow > 0:
		mat.emission_enabled = true; mat.emission = value; mat.emission_energy_multiplier = glow
	return mat

func stone(value: Color, moss := 0.08) -> ShaderMaterial:
	var mat := ShaderMaterial.new(); mat.shader = STONE
	mat.set_shader_parameter("stone_color",value); mat.set_shader_parameter("moss_amount",moss)
	mat.set_shader_parameter("wear",0.22)
	return mat

func color(value: int) -> Color:
	return Color(float((value>>16)&255)/255.0,float((value>>8)&255)/255.0,float(value&255)/255.0)

func box(at: Vector3, size: Vector3, mat: Material, parent: Node3D = self) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size = size
	var node := MeshInstance3D.new(); node.mesh = mesh; node.material_override = mat; node.position = at; parent.add_child(node)
	return node

func apply_environment(world: WorldEnvironment, key: DirectionalLight3D, theme_name: String) -> void:
	var t: Dictionary = themes.get(theme_name,themes.temple)
	var env := Environment.new(); env.background_mode = Environment.BG_SKY
	var sky := Sky.new(); var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = color(int(t.sky[0])); sky_material.sky_horizon_color = color(int(t.sky[1]))
	sky_material.ground_bottom_color = color(int(t.ground)); sky_material.ground_horizon_color = color(int(t.fog[0]))
	sky.sky_material = sky_material; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = color(int(t.hemi[0])); env.ambient_light_energy = float(t.hemi[2])*0.43
	env.ssao_enabled = true; env.ssao_intensity = 1.0; env.ssao_radius = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES; env.tonemap_exposure = float(t.exp)
	env.glow_enabled = true; env.glow_intensity = 0.24
	env.fog_enabled = true; env.fog_light_color = color(int(t.fog[0])); env.fog_density = 0.0015
	env.fog_aerial_perspective = 0.25
	world.environment = env; key.light_color = color(int(t.key[0])); key.light_energy = float(t.key[1])*0.65; key.shadow_enabled = true
	key.directional_shadow_max_distance = 60; key.light_angular_distance = 0.5
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.rotation_degrees = Vector3(-48,-38,0)
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		# LDR Compatibility has no ACES highlight rolloff: avoid clipping pale cover.
		key.light_energy *= 0.55; env.ambient_light_energy *= 0.8

	var graphics := get_node_or_null("/root/Graphics")
	if graphics:
		graphics.apply_environment(env)
		graphics.apply_node.call_deferred(weakref(key))

func setup_palette(t: Dictionary) -> void:
	var surface: Dictionary = t.surface
	var floor_mat := ShaderMaterial.new(); floor_mat.shader = TERRAIN
	floor_mat.set_shader_parameter("base_color",Color(surface.base)); floor_mat.set_shader_parameter("secondary_color",Color(surface.secondary))
	floor_mat.set_shader_parameter("biome",int(surface.biome))
	palette = {"floor":floor_mat,"wall":stone(color(int(t.wall)).lightened(0.18)),"dark":stone(color(int(t.wall)).darkened(0.24)),
		"ledge":stone(color(int(t.wallTop)).lightened(0.15),0.02),"trim":material(color(int(t.trim))),
		"metal":material(color(int(t.metal))),"ground":stone(color(int(t.ground)).lightened(0.09)),
		"bags":stone(Color("8c8970") if theme != "snow" else Color("a6b6b9"),0.03),
		"bark":stone(Color("524435")),"leaves":stone(Color("354e35") if theme != "plains" else Color("58683e"),0.1),
		"snow":stone(Color("d3e1e4"),0),"water":material(Color("365e69")),
		"banner":material(Color("294558")),"window":material(Color("b6cbd1"),0.6),
		"glow":material(Color("73dce7"),1.6),"evac":material(Color("51cce0"),1.3),
		"fire":material(Color("ffad59"),2.6),"objective":material(Color("edbf64"),1.5),
		"crystal":material(Color("779fc6"),0.8),"scorch":material(Color("211e1b")),"danger":material(Color("e76858"),0.6)}
	palette.metal.metallic = 0.65; palette.metal.roughness = 0.4
	palette.water.metallic = 0.3; palette.water.roughness = 0.18
	palette.ground = floor_mat.duplicate()
	palette.ground.set_shader_parameter("base_color",Color(surface.base).darkened(0.18 if theme in ["dock","city","temple"] else 0.0))
	palette.ground.set_shader_parameter("secondary_color",Color(surface.secondary).darkened(0.12 if theme in ["dock","city","temple"] else 0.0))

func build(m: RefCounted, _models: Dictionary = {}) -> void:
	clear_children(self)
	mission = m; theme = str(m.spec.get("theme","temple"))
	batch.material_lift = props.get("meshy_material_lift",{})
	batch.records.clear(); batch.buckets.clear(); batch.reset_lods(); floor_bounds.clear(); access_tiles.clear()
	# Campaign cameras scale with map size; keep the near half detailed at their default zoom.
	batch.lod_distance = maxf(float(props.get("meshy_lod_distance",26.0)),maxf(m.spec.width,m.spec.height)*1.3 if m.modern else 0.0)
	var t: Dictionary = themes.get(theme,themes.temple); setup_palette(t)
	access_tiles = preload("res://scripts/map_art_access.gd").prepare(m)
	interior_full_cover = m.board.slice(1,m.board.size()-1).any(func(row): return "#" in str(row).substr(1,int(m.spec.width)-2))
	var geo := Geometry.new(self)
	for y in int(m.spec.height):
		for x in int(m.spec.width):
			geo.floor_tile(m,Vector2i(x,y)); geo.cover(m,Vector2i(x,y))
	geo.backdrop(int(m.spec.width),int(m.spec.height))
	batch.flush(self)
	var rim := DirectionalLight3D.new(); rim.light_color = color(int(t.rim[0])); rim.light_energy = float(t.rim[1])*0.4
	rim.rotation_degrees = Vector3(-30,135,0)
	if RenderingServer.get_current_rendering_method() == "gl_compatibility": rim.light_energy *= 0.55
	add_child(rim)
	weather(t.part,int(m.spec.width),int(m.spec.height))
	marker_root = Node3D.new(); marker_root.name = "Objectives"; add_child(marker_root)
	damage_root = Node3D.new(); damage_root.name = "CoverDamage"; add_child(damage_root)
	damage_hash = -1; marker_hash = -1
	refresh_markers(m); refresh_damage()
	if is_instance_valid(game):
		var detection := preload("res://scripts/meshy_theme_markers.gd").new()
		detection.game = game; add_child(detection)

func clear_children(parent: Node) -> void:
	for child in parent.get_children(): parent.remove_child(child); child.queue_free()

func prop(kind: String, at: Vector3, width: float, height: float, angle := 0.0) -> bool:
	return batch.model("res://assets/maps/%s.glb" % kind,at,width,height,angle).size.length() > 0.001

func bounds_of(node: Node3D, transform: Transform3D) -> AABB:
	var parts: Array = []; batch.collect(node,transform,parts)
	var out := AABB(); var first := true
	for part in parts:
		var bounds: AABB = part.transform*part.mesh.get_aabb()
		out = bounds if first else out.merge(bounds); first = false
	return out

func light(at: Vector3, tint: Color, energy: float, radius: float, parent: Node = self) -> void:
	if find_children("*","OmniLight3D",true,false).size() >= 4: return
	var lamp := OmniLight3D.new(); lamp.position = at; lamp.light_color = tint
	lamp.light_energy = energy; lamp.omni_range = radius; lamp.shadow_enabled = false; parent.add_child(lamp)

func _process(delta: float) -> void:
	if not mission: return
	if is_instance_valid(game):
		var hovered: Vector2i = game.hovered
		palette.floor.set_shader_parameter("hover_tile",Vector2(hovered))
		palette.floor.set_shader_parameter("grid_strength",0.8 if mission.in_bounds(hovered) and not game.cinematic else 0.0)
	tick += delta
	if tick < 0.18: return
	tick = 0.0; refresh_damage(); refresh_markers(mission)

func refresh_damage() -> void:
	var signature := hash(mission.cover_hp)
	if damage_hash == signature: return
	damage_hash = signature; clear_children(damage_root)
	if scar_texture == null:
		var picture := Image.create(64,64,false,Image.FORMAT_RGBA8)
		for y in 64:
			for x in 64:
				var u := Vector2(x-32,y-32)/32.0
				var crack := absf(u.x-sin(u.y*14.0)*0.13) < 0.035 or absf(u.y+u.x*0.5-sin(u.x*20.0)*0.08) < 0.025
				var alpha := (0.8 if crack else 0.28)*maxf(0,1.0-u.length())
				picture.set_pixel(x,y,Color(0.04,0.035,0.03,alpha))
		scar_texture = ImageTexture.create_from_image(picture)
	var fallback: Array[Transform3D] = []
	for tile in mission.cover_hp:
		var c: String = mission.tile(tile)
		var maximum := 8 if c == "#" else 4
		if int(mission.cover_hp[tile]) >= maximum: continue
		var h := 1.92 if c == "#" else 0.82
		if RenderingServer.get_current_rendering_method() == "gl_compatibility":
			fallback.append(Transform3D(Basis.from_scale(Vector3(0.98,h+0.02,0.98)),Vector3(tile.x,Shot.elevation(mission,tile)*0.7+h*0.5,tile.y)))
			continue
		# Project onto the actual mesh surface; no floating damage-card geometry.
		var scar := Decal.new(); scar.texture_albedo = scar_texture
		scar.size = Vector3(0.92,h+0.08,0.92)
		scar.position = Vector3(tile.x,Shot.elevation(mission,tile)*0.7+h*0.5,tile.y)
		scar.normal_fade = 0.0; scar.upper_fade = 0.03; scar.lower_fade = 0.03
		damage_root.add_child(scar)

	preload("res://scripts/graphics_damage.gd").build(damage_root,scar_texture,fallback)

func ring(b, at: Vector3, mat: Material, radius := 0.43) -> void:
	for i in 24:
		var angle := TAU*float(i)/24.0
		b.put("box",mat,at+Vector3(sin(angle)*radius,0.012,cos(angle)*radius),Vector3(0.10,0.024,0.025),angle)

func person(b, at: Vector3, freed: bool) -> void:
	var cloth: Material = palette.banner if freed else palette.bags
	for side in [-1,1]:
		b.put("box",palette.dark,at+Vector3(side*0.12,0.21,0),Vector3(0.13,0.42,0.19))
		b.put("cylinder",cloth,at+Vector3(side*0.26,0.75,0),Vector3(0.13,0.5,0.13))
	b.put("cylinder",cloth,at+Vector3.UP*0.72,Vector3(0.42,0.62,0.34))
	b.put("rock",palette.bags,at+Vector3.UP*1.16,Vector3(0.28,0.32,0.27))
	if not freed: b.put("box",palette.glow,at+Vector3(0,0.58,0.22),Vector3(0.36,0.035,0.04))

func refresh_markers(m: RefCounted) -> void:
	if not is_instance_valid(marker_root): return
	var signature := hash([m.objective_state,m.pressure_state,m.prisoner,m.turn,m.units.map(func(u): return [u.hp,u.overwatch,u.spotted,u.x,u.y])])
	if signature == marker_hash: return
	marker_hash = signature; clear_children(marker_root)
	var markers = Batch.new(); markers.models = batch.models; markers.lod_distance = batch.lod_distance
	# Records are replaced when escort/civilian positions change.
	batch.records = batch.records.filter(func(record): return record.role != "objective")
	for point in m.spec.evac:
		var tile := Maps.point(point); var at := Vector3(tile.x,Shot.elevation(m,tile)*0.7,tile.y)
		markers.begin_record({"tile":tile,"floor":at.y,"kind":"evac","role":"objective"})
		# One small beacon at a zone corner leaves the walkable tile and unit centre clear.
		if point == m.spec.evac[0]:
			markers.pair(Meshy.objective_path(props,Meshy.action(props,"evac")),at+Vector3(0.33,0,0.33),0.25,0.44)
		ring(markers,at,palette.evac); markers.end_record()
	if bool(m.prisoner.get("active",true)) and m.in_bounds(Shot.pos(m.prisoner)) and m.result != "win":
		var tile := Shot.pos(m.prisoner); var at := Vector3(tile.x,Shot.elevation(m,tile)*0.7,tile.y)
		markers.begin_record({"tile":tile,"floor":at.y,"kind":"prisoner","role":"objective"})
		var restrained := false
		if not bool(m.prisoner.freed):
			restrained = markers.pair(Meshy.objective_path(props,Meshy.action(props,"rescue")),at,0.72,1.35)
		if not restrained: person(markers,at,bool(m.prisoner.freed))
		ring(markers,at,palette.objective); markers.end_record()
	if m.modern:
		for civilian in m.objective_state.get("civilians",[]):
			if civilian.state != "waiting": continue
			var tile := Maps.point(civilian.at); var at := Vector3(tile.x,Shot.elevation(m,tile)*0.7,tile.y)
			markers.begin_record({"tile":tile,"floor":at.y,"kind":"civilian","role":"objective"})
			person(markers,at,true); ring(markers,at,palette.evac); markers.end_record()
		if m.spec.family not in ["rescue","vip_extract","retaliation","ambush","operation"]:
			for point in m.spec.objective.points: objective(markers,m,Maps.point(point),str(m.spec.family))
		if m.spec.family == "operation":
			var step: Dictionary = preload("res://scripts/mission_objectives.gd").current_step(m)
			if step.has("at"): objective(markers,m,Maps.point(step.at),"operation")
	for zone in overwatch_zones(m):
		var tile: Vector2i = zone.at
		ring(markers,Vector3(tile.x,Shot.elevation(m,tile)*0.7+0.01,tile.y),palette.objective if zone.side == "player" else palette.danger,0.34)
	if m.modern:
		for wave in m.pressure_state.pending:
			var tile := Maps.point(wave.at)
			ring(markers,Vector3(tile.x,Shot.elevation(m,tile)*0.7+0.02,tile.y),palette.danger)
		if m.spec.family == "operation" and m.objective_state.phase == "primary":
			var step: Dictionary = preload("res://scripts/mission_objectives.gd").current_step(m)
			if step.has("at"):
				var tile := Maps.point(step.at); var radius := int(step.get("radius",1))
				for y in range(tile.y-radius,tile.y+radius+1):
					for x in range(tile.x-radius,tile.x+radius+1):
						if m.passable(Vector2i(x,y)): ring(markers,Vector3(x,Shot.elevation(m,Vector2i(x,y))*0.7+0.02,y),palette.objective,0.36)
	batch.records.append_array(markers.records); markers.flush(marker_root)

func objective(b, m: RefCounted, tile: Vector2i, family: String) -> void:
	if not m.in_bounds(tile): return
	var at := Vector3(tile.x,Shot.elevation(m,tile)*0.7,tile.y)
	var done: bool = m.objective_state.get("done",{}).has(tile)
	b.begin_record({"tile":tile,"floor":at.y,"kind":family,"role":"objective"})
	if b.pair(Meshy.objective_path(props,Meshy.action(props,family)),at,0.72,1.18):
		pass
	elif family == "hack_terminal" and props.get("meshy1_enabled",false) and not str(props.get("meshy1_models",{}).get("objective","")).is_empty():
		# Batch 1 terminal has no explicit LOD1 in the shipped assets; preserve existing art.
		b.model(str(props.meshy1_models.objective),at,0.72,1.18)
	elif family == "sabotage":
		b.model("res://assets/maps/barrel.glb",at,0.65,0.75)
		b.put("box",palette.metal,at+Vector3(0,0.22,0.31),Vector3(0.38,0.28,0.16))
		b.put("box",palette.fire if done else palette.glow,at+Vector3(0,0.25,0.397),Vector3(0.22,0.07,0.012))
	else:
		b.model("res://assets/maps/%s.glb" % ("relay" if family in ["destroy_relay","defend"] else "terminal"),at,0.72,1.18)
		b.put("box",palette.glow,at+Vector3(0,0.92,0.30),Vector3(0.30,0.17,0.025))
	ring(b,at,palette.evac if done else palette.objective)
	b.end_record(); light(at+Vector3.UP*1.3,Color("74d4e4"),0.6,2.0,marker_root)

func overwatch_zones(m: RefCounted) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u in m.units:
		if int(u.hp) <= 0 or float(u.range) < 2.0 or not bool(u.overwatch) or (u.side == "enemy" and not bool(u.spotted)): continue
		for y in int(m.spec.height):
			for x in int(m.spec.width):
				var p := Vector2i(x,y)
				if p != Shot.pos(u) and m.passable(p) and Shot.distance(Shot.pos(u),p) <= float(u.range) and Shot.los(m,Shot.pos(u),p): out.append({"at":p,"side":u.side,"unit":u.id})
	return out


func weather(settings: Dictionary, width: int, height: int) -> void:
	var compatibility := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	# CPU weather keeps the phone path independent of GPU particle processing.
	var node = CPUParticles3D.new() if compatibility else GPUParticles3D.new()
	node.amount = int(settings.n); node.lifetime = 12.0
	if not compatibility: node.visibility_aabb = AABB(Vector3(-4,-2,-4),Vector3(width+8,12,height+8))
	node.position = Vector3(float(width)/2,3,float(height)/2)
	var process = node if compatibility else ParticleProcessMaterial.new()
	process.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX if compatibility else ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(float(width)/2+2,3,float(height)/2+2)
	var kind := str(settings.kind)
	var fall := 9.0 if kind == "rain" else 0.6 if kind == "snow" else -0.4 if kind == "ember" else 0.05
	process.direction = Vector3.DOWN if fall >= 0 else Vector3.UP; process.spread = 8.0 if kind == "rain" else 60.0
	process.initial_velocity_min = absf(fall)*0.5; process.initial_velocity_max = absf(fall); process.gravity = Vector3.ZERO
	if compatibility:
		process.scale_amount_min = 0.5; process.scale_amount_max = 1.0
	else:
		process.scale_min = 0.5; process.scale_max = 1.0
		node.process_material = process
	var mesh := QuadMesh.new(); mesh.size = Vector2(0.035,0.4) if kind == "rain" else Vector2(0.075,0.075)
	var mat := material(color(int(settings.color)),0.6 if kind in ["firefly","ember"] else 0.0)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	if compatibility: node.mesh = mesh
	else: node.draw_pass_1 = mesh
	add_child(node)
