extends RefCounted
## Scene, terrain and figure synchronization extracted from game.gd.
var g

func _setup_scene() -> void:
	g.terrain = Node3D.new(); g.terrain.name = "Terrain"; g.add_child(g.terrain)
	g.figures = Node3D.new(); g.figures.name = "Units"; g.add_child(g.figures)
	g.highlights = Node3D.new(); g.highlights.name = "RangePreview"; g.add_child(g.highlights)
	g.range_highlights = Node3D.new(); g.highlights.add_child(g.range_highlights)
	g.hover_highlights = Node3D.new(); g.highlights.add_child(g.hover_highlights)
	g.fx = g.Effects.new(); g.fx.name = "CombatEffects"; g.add_child(g.fx)
	g.reinforcement_view = preload("res://scripts/reinforcement_marker.gd").new(); g.add_child(g.reinforcement_view)
	g.sound = g.Audio.new(); g.add_child(g.sound)
	g.camera = Camera3D.new(); g.camera.current = true; g.camera.fov = 45; g.add_child(g.camera)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("101826")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a8bdd4")
	env.ambient_light_energy = 0.68
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.ssao_enabled = true
	env.ssao_intensity = 0.65
	env.fog_enabled = true
	env.fog_light_color = Color("253c50")
	env.fog_density = 0.008
	world.environment = env; g.add_child(world)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55, -35, 0); sun.light_energy = 1.65; sun.light_color = Color("ffe1ae"); sun.shadow_enabled = true; sun.light_angular_distance = 2.5; g.add_child(sun)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-30, 140, 0); fill.light_energy = 0.55; fill.light_color = Color("78bde5"); g.add_child(fill)
	var dust := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 85
	var speck := SphereMesh.new(); speck.radius = 0.018; speck.height = 0.036
	multimesh.mesh = speck
	var random := RandomNumberGenerator.new(); random.seed = 4719
	for i in range(multimesh.instance_count):
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(random.randf_range(0, 26), random.randf_range(0.3, 4.2), random.randf_range(0, 26))))
	dust.multimesh = multimesh; dust.material_override = g._mat(Color("e3d1ad")); g.add_child(dust)

func _load_models() -> void:
	for name in ["jedi", "trooper", "scout", "sithHeavy", "agent"]:
		var path := "res://assets/models/units/%s.glb" % name
		if ResourceLoader.exists(path): g.model_cache[name] = load(path)
	for name in ["crate", "terminal"]:
		var path := "res://assets/models/props/%s.glb" % name
		if ResourceLoader.exists(path): g.model_cache[name] = load(path)

func _mat(color: Color, transparent: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	m.metallic = 0.1
	if transparent: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new(); mesh.size = size; node.mesh = mesh
	node.material_override = g._mat(color)
	node.position = at
	parent.add_child(node)
	return node

func _instance_model(parent: Node3D, key: String, at: Vector3, scale_value: float) -> bool:
	if not g.model_cache.has(key): return false
	var packed: Variant = g.model_cache[key]
	if not packed is PackedScene: return false
	var model: Node3D = packed.instantiate()
	model.position = at
	model.scale = Vector3.ONE * scale_value
	parent.add_child(model)
	return true

func _build_terrain() -> void:
	if g.terrain.get_child_count() == 0:
		var art := preload("res://scripts/env_art.gd").new()
		g.terrain.add_child(art)
	g.terrain.get_child(0).build(g.mission, g.model_cache)

func _sync_terrain() -> void:
	if g.mission.terrain_revision == g.terrain_seen_revision: return
	g._build_terrain()
	for y in range(mini(g.terrain_seen_board.size(), g.mission.board.size())):
		for x in range(mini(g.terrain_seen_board[y].length(), g.mission.board[y].length())):
			if g.terrain_seen_board[y][x] != g.mission.board[y][x]:
				var tile := Vector2i(x, y)
				g.fx.cover_chunks(Vector3(x, g.Shot.elevation(g.mission, tile) * 0.7 + 0.5, y))
	g.terrain_seen_board = g.mission.board.duplicate()
	g.terrain_seen_revision = g.mission.terrain_revision

func _clear(node: Node) -> void:
	for child in node.get_children(): child.queue_free()

func _refresh_figures() -> void:
	var seen: Dictionary = {}
	for u in g.mission.units:
		var id := int(u.id)
		if (int(u.hp) <= 0 and str(u.side) == "enemy") or (str(u.side) == "enemy" and not bool(u.awake) and not bool(u.get("spotted", false))):
			if g.playing_enemy_events and g.views.has(id): continue
			if g.views.has(id):
				var fallen: Node3D = g.views[id]
				g.views.erase(id)
				fallen.fall()
			continue
		seen[id] = true
		var p: Vector2i = g.Shot.pos(u)
		var at := Vector3(p.x, g.Shot.elevation(g.mission, p) * 0.7, p.y)
		var model_name: String = str(u.model)
		if not g.views.has(id) and g.model_cache.has(model_name):
			var view: Node3D = g.UnitView.new()
			g.figures.add_child(view)
			view.setup(u, g.model_cache[model_name], at)
			g.views[id] = view
			if str(u.side) == "enemy" and not g.demo_mode:
				g.fx.float_text(at + Vector3.UP * 1.9, "ALERT!", Color("ff786d"), true)
				g.sound.play("turn")
		elif g.views.has(id) and not g.playing_enemy_events and not g.player_attack_pending and g.views[id].position.distance_to(at) > 0.05 and (g.views[id].motion == null or not g.views[id].motion.is_running()):
			g.views[id].travel([at])
		if g.views.has(id):
			g.views[id].set_status(u)
			g.views[id].set_downed(str(u.get("status", "ok")) == "down")
			g.views[id].set_selected(id == g.selected_id, str(u.side) == "enemy")
			var cover_level := 0
			var threat := -1
			for other in g.mission.living("player" if str(u.side) == "enemy" else "enemy"):
				if str(other.side) == "enemy" and not bool(other.awake): continue
				var shot_info: Dictionary = g.Shot.calculate(g.mission, other, u)
				if bool(shot_info.los) and bool(shot_info.range_ok) and int(shot_info.hit) > threat:
					threat = int(shot_info.hit)
					cover_level = 2 if int(shot_info.cover) == 40 else 1 if int(shot_info.cover) == 20 else 0
			if threat < 0 and g.Shot.in_cover(g.mission, p): cover_level = 1
			g.views[id].set_cover(cover_level)
	if not bool(g.mission.prisoner.freed) or g.mission.result != "win":
		var p := Vector2i(int(g.mission.prisoner.x), int(g.mission.prisoner.y))
		var at := Vector3(p.x, g.Shot.elevation(g.mission, p) * 0.7 + 0.5, p.y)
		if not is_instance_valid(g.figures.get_node_or_null("Prisoner")):
			var marker: MeshInstance3D = g._box(g.figures, at, Vector3(0.35, 1.0, 0.35), Color("f3d498"))
			marker.name = "Prisoner"
		else: g.figures.get_node("Prisoner").position = at
