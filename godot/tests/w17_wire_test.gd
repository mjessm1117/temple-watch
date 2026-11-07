extends SceneTree
const View = preload("res://scripts/unit_view.gd")
const Actor = preload("res://scripts/campaign/loadout_actor.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Roster = preload("res://scripts/campaign/strat_roster.gd")
const KINDS := ["sniper", "heavy", "tech", "droid", "officer"]
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("W17 WIRE: " + label)

func triangles(node: Node) -> int:
	var total := 0
	if node is MeshInstance3D and node.mesh != null:
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			total += (indices.size() if indices.size() > 0 else vertices.size()) / 3
	for child in node.get_children(): total += triangles(child)
	return total

func geometry(node: Node) -> GeometryInstance3D:
	if node is GeometryInstance3D: return node
	for child in node.get_children():
		var found := geometry(child)
		if found != null: return found
	return null

func roster_row(cls: String) -> Dictionary:
	return {"id":"wire-" + cls, "n":cls, "cls":cls, "status":"active", "wound":0, "assign":"", "col":"#c9dce8", "gear":{"armor":"light", "w":1, "saber":0, "mk":{"w":1,"a":1,"s":1}, "mods":[], "amods":[], "smods":[], "util":"none", "trait":"", "form":"shiiCho"}}

func run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var campaign := Campaign.new()
	check(View.battle_model_path({"class_name":"Trooper", "model":"trooper"}) == "res://assets/models/units/trooper.glb", "Trooper keeps original GLB")
	for kind in KINDS:
		var cls: String = kind.capitalize()
		var path: String = "res://assets/units/w17/" + kind + ".glb"
		var low_path: String = "res://assets/units/w17/" + kind + "_lod1.glb"
		var unit: Dictionary = catalog.get(kind, {}) if kind != "heavy" else catalog.get("heavy", {})
		check(not unit.is_empty(), kind + " unit kind exists")
		var battle_unit: Dictionary = unit.duplicate(true)
		battle_unit.class_name = cls
		check(View.battle_model_path(battle_unit) == path, kind + " battle model path")
		check(Actor.model_path(roster_row(cls)) == path, kind + " armory model path")
		var packed := load(path) as PackedScene
		var low_packed := load(low_path) as PackedScene
		check(packed != null and low_packed != null, kind + " LOD scenes import")
		if packed == null or low_packed == null: continue
		var model := packed.instantiate()
		root.add_child(model)
		var count := triangles(model)
		print("W17 LOD0 ", kind, ": ", count, " triangles")
		check(count > 0 and count <= 15000, kind + " LOD0 triangle budget: " + str(count))
		var anim := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		check(anim != null, kind + " animation player")
		if anim != null:
			for clip in ["idle", "run", "shoot", "hit"]:
				check(anim.has_animation(clip), kind + " " + clip + " clip")
				if anim.has_animation(clip):
					anim.play(clip); anim.advance(0.15)
					check(anim.current_animation == clip, kind + " " + clip + " plays")
		model.queue_free()
		var view := View.new(); root.add_child(view)
		battle_unit.id = 900 + KINDS.find(kind); battle_unit.side = "player"
		view.setup(battle_unit, load("res://assets/models/units/trooper.glb"), Vector3.ZERO)
		check(view.model.scene_file_path == path, kind + " battle instance is W17")
		check(view.lod_animation != null, kind + " LOD1 installed")
		var low := view.model.get_child(view.model.get_child_count() - 1)
		check(low.scene_file_path == low_path, kind + " LOD1 swaps in")
		var high_mesh := geometry(view.model)
		var low_mesh := geometry(low)
		check(high_mesh != null and low_mesh != null, kind + " LOD geometry exists")
		if high_mesh != null and low_mesh != null:
			check(high_mesh.visibility_range_end == 26.0 and low_mesh.visibility_range_begin == 26.0, kind + " LOD visibility switch")
		for clip in ["run", "shoot", "hit", "gunIdle"]:
			view.play(clip)
			check(view.animation.current_animation == clip and view.lod_animation.current_animation == clip, kind + " both LODs play " + clip)
		view.queue_free()
		var actor := Actor.new(); root.add_child(actor); actor.setup(roster_row(cls), true)
		check(actor.model.scene_file_path == path, kind + " armory instance is W17")
		actor.queue_free()
		var found := false
		var candidate_id := ""
		for month in range(1, 9):
			campaign.state.month = month
			Roster.refresh_recruits(campaign.state)
			for candidate in campaign.state.cands:
				if str(candidate.cls) == cls:
					found = true
					candidate_id = str(candidate.id)
					break
			if found: break
		check(found, kind + " appears in barracks candidates")
		if found:
			var recruit_campaign := Campaign.new()
			recruit_campaign.state.cands = campaign.state.cands.duplicate(true)
			recruit_campaign.state.res.credits = 10000
			recruit_campaign.state.res.recruits = 10
			check(Roster.hire(recruit_campaign, candidate_id), kind + " can be hired")
			check(recruit_campaign.state.roster.back().cls == cls, kind + " hired roster class persists")
	check(Roster.squad_capacity(campaign.state) == 5, "starting squad capacity stays five")
	campaign.state.strategy.squad_upgrades = 1
	check(Roster.squad_capacity(campaign.state) == 6, "first squad upgrade stays six")
	campaign.state.strategy.squad_upgrades = 2
	check(Roster.squad_capacity(campaign.state) == 7, "second squad upgrade stays seven")
	if "--capture" in OS.get_cmdline_user_args(): await capture()
	print("W17 WIRE TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func capture() -> void:
	print("WIRE_CAPTURE game start")
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.size = Vector2i(844, 390); root.content_scale_size = root.size
	root.add_child(game); await process_frame
	print("WIRE_CAPTURE game ready")
	game.demo_mode = true; game.set_process(false)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	var players: Array = game.mission.living("player")
	while players.size() < KINDS.size():
		var anchor: Dictionary = players[0]
		var spot := Vector2i(int(anchor.x) - 1, int(anchor.y) - 1)
		var best := INF
		for dy in range(-5, 6):
			for dx in range(-5, 6):
				var tile := Vector2i(int(anchor.x) + dx, int(anchor.y) + dy)
				if not game.mission.passable(tile) or game.mission.occupied(tile): continue
				var projected: Vector2 = game.camera.unproject_position(Vector3(tile.x, 1.0, tile.y))
				if projected.x < 540 or projected.x > 675 or projected.y < 165 or projected.y > 245: continue
				var score := projected.distance_to(Vector2(610, 205))
				if score < best: best = score; spot = tile
		game.mission._spawn("soldier", spot.x, spot.y, -1)
		players = game.mission.living("player")
	for i in KINDS.size():
		var original: Dictionary = players[i]
		var unit: Dictionary = original.duplicate(true)
		var template: Dictionary = catalog[KINDS[i]] if KINDS[i] != "heavy" else catalog["heavy"]
		for key in ["name", "hp", "aim", "mob", "damage", "range", "armor", "crit", "kit", "medpacs", "clip"]:
			if template.has(key): unit[key] = template[key]
		for key in ["id", "x", "y", "ap", "group", "awake", "spotted", "status", "facing"]:
			if original.has(key): unit[key] = original[key]
		unit.side = "player"; unit.class_name = KINDS[i].capitalize(); unit.model = "trooper"; unit.kind = KINDS[i]
		if KINDS[i] == "heavy": unit.name = "Republic Heavy"
		unit.max_hp = unit.hp
		var index: int = game.mission.units.find(original)
		game.mission.units[index] = unit
	for view in game.views.values(): view.queue_free()
	game.views.clear()
	game._refresh_figures(); game._refresh()
	game.highlights.visible = false
	if game.phase_banner != null: game.phase_banner.visible = false
	print("WIRE_CAPTURE figures ready")
	for i in 12: await process_frame
	if game.phase_banner != null: game.phase_banner.visible = false
	await process_frame
	var dir := "res://../docs/godot/shots/"
	root.get_texture().get_image().save_png(dir + "w17-wire-battle.png")
	print("WIRE_CAPTURE phone saved")
	root.size = Vector2i(1366, 768); root.content_scale_size = root.size
	for i in 8: await process_frame
	await process_frame
	root.get_texture().get_image().save_png(dir + "w17-wire-desktop.png")
	game.queue_free(); await process_frame
	await capture_armory(dir)

func capture_armory(dir: String) -> void:
	root.size = Vector2i(1366, 480); root.content_scale_size = root.size
	var stage := Node3D.new(); root.add_child(stage)
	var world := WorldEnvironment.new(); stage.add_child(world)
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("263342"); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color.WHITE; env.ambient_light_energy = 0.8; world.environment = env
	var light := DirectionalLight3D.new(); stage.add_child(light); light.rotation_degrees = Vector3(-55, -30, 0); light.light_energy = 1.6
	for i in KINDS.size():
		var actor := Actor.new(); stage.add_child(actor); actor.setup(roster_row(KINDS[i].capitalize()), true)
		actor.position.x = (i - 2) * 2.1
	var labels := CanvasLayer.new(); stage.add_child(labels)
	for i in KINDS.size():
		var label := Label.new(); labels.add_child(label)
		label.text = KINDS[i].to_upper(); label.position = Vector2(110 + i * 270, 42)
		label.add_theme_font_size_override("font_size", 24)
	var camera := Camera3D.new(); stage.add_child(camera); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 3.8; camera.position = Vector3(0, 2.4, 12); camera.look_at(Vector3(0, 1.0, 0)); camera.current = true
	for i in 12: await process_frame
	await process_frame
	root.get_texture().get_image().save_png(dir + "w17-wire-armory.png")
	stage.queue_free()
