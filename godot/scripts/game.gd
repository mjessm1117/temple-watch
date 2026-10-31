extends Node3D

const Mission = preload("res://scripts/mission.gd")
const Shot = preload("res://scripts/shot.gd")
const UnitView = preload("res://scripts/unit_view.gd")
const Effects = preload("res://scripts/fx.gd")
const Audio = preload("res://scripts/audio.gd")
const HudControls = preload("res://scripts/hud_controls.gd")
const InputControls = preload("res://scripts/input_controls.gd")
const EnemyPresentation = preload("res://scripts/enemy_presentation.gd")
const AttackPresentation = preload("res://scripts/attack_presentation.gd")
const Ability = preload("res://scripts/abilities_engine.gd")
var mission: RefCounted
var camera: Camera3D
var pivot: Vector3 = Vector3(9, 0, 17)
var yaw: float = 0.3
var pitch: float = 0.8
var zoom: float = 23.0
var drag_button: int = 0
var selected_id: int = -1
var action: String = "move"
var hovered: Vector2i = Vector2i(-1, -1)
var terrain: Node3D
var figures: Node3D
var highlights: Node3D
var range_highlights: Node3D
var hover_highlights: Node3D
var hud: CanvasLayer
var title_label: Label
var objective_label: Label
var selected_label: Label
var shot_label: Label
var hit_big_label: Label
var log_label: Label
var result_panel: PanelContainer
var result_label: Label
var action_buttons: Dictionary = {}
var model_cache: Dictionary = {}
var views: Dictionary = {}
var fx: Node3D
var sound: Node
var overlay: Control
var camera_tween: Tween
var action_tween: Tween
var action_camera := true
var cinematic := false
var phase_banner: Label
var path_label: Label
var audio_slider: HSlider
var portrait_viewport: SubViewport
var portrait_model: Node3D
var portrait_kind := ""
var demo_mode := false
var hud_controls: RefCounted
var input_controls: RefCounted
var preview_tile := Vector2i(-1, -1)
var target_id := -1
var end_turn_armed := false
var warning_label: Label
var enemy_frame_sequence := 0
var playing_enemy_events := false
var player_attack_pending := false
var terrain_seen_revision := 0
var terrain_seen_board: Array[String] = []
var reinforcement_view: Node3D

func _ready() -> void:
	mission = get_node("/root/CampaignFlow").create_battle(7)
	hud_controls = HudControls.new()
	hud_controls.g = self
	input_controls = InputControls.new()
	input_controls.g = self
	_setup_scene()
	_load_models()
	_build_terrain()
	terrain_seen_revision = mission.terrain_revision
	terrain_seen_board = mission.board.duplicate()
	_build_ui()
	selected_id = int(mission.living("player")[0].id)
	_update_camera()
	_refresh()
	var demo := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--demo="): demo = arg.trim_prefix("--demo=")
	if demo != "": _demo.call_deferred(demo)
	else:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--capture="): _capture.call_deferred(arg.trim_prefix("--capture="))

func _capture(path: String, frames: int = 2) -> void:
	for i in range(frames): await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("SCREENSHOT: %s (%s)" % [path, "ok" if error == OK else "error %d" % error])
	get_tree().quit(0 if error == OK else 1)

func _setup_scene() -> void:
	terrain = Node3D.new(); terrain.name = "Terrain"; add_child(terrain)
	figures = Node3D.new(); figures.name = "Units"; add_child(figures)
	highlights = Node3D.new(); highlights.name = "RangePreview"; add_child(highlights)
	range_highlights = Node3D.new(); highlights.add_child(range_highlights)
	hover_highlights = Node3D.new(); highlights.add_child(hover_highlights)
	fx = Effects.new(); fx.name = "CombatEffects"; add_child(fx)
	reinforcement_view = preload("res://scripts/reinforcement_marker.gd").new(); add_child(reinforcement_view)
	sound = Audio.new(); add_child(sound)
	camera = Camera3D.new(); camera.current = true; camera.fov = 45; add_child(camera)
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
	world.environment = env; add_child(world)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55, -35, 0); sun.light_energy = 1.65; sun.light_color = Color("ffe1ae"); sun.shadow_enabled = true; sun.light_angular_distance = 2.5; add_child(sun)
	var fill := DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-30, 140, 0); fill.light_energy = 0.55; fill.light_color = Color("78bde5"); add_child(fill)
	var dust := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 85
	var speck := SphereMesh.new(); speck.radius = 0.018; speck.height = 0.036
	multimesh.mesh = speck
	var random := RandomNumberGenerator.new(); random.seed = 4719
	for i in range(multimesh.instance_count):
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(random.randf_range(0, 26), random.randf_range(0.3, 4.2), random.randf_range(0, 26))))
	dust.multimesh = multimesh; dust.material_override = _mat(Color("e3d1ad")); add_child(dust)

func _load_models() -> void:
	for name in ["jedi", "trooper", "scout", "sithHeavy", "agent"]:
		var path := "res://assets/models/units/%s.glb" % name
		if ResourceLoader.exists(path): model_cache[name] = load(path)
	for name in ["crate", "terminal"]:
		var path := "res://assets/models/props/%s.glb" % name
		if ResourceLoader.exists(path): model_cache[name] = load(path)

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
	node.material_override = _mat(color)
	node.position = at
	parent.add_child(node)
	return node

func _instance_model(parent: Node3D, key: String, at: Vector3, scale_value: float) -> bool:
	if not model_cache.has(key): return false
	var packed: Variant = model_cache[key]
	if not packed is PackedScene: return false
	var model: Node3D = packed.instantiate()
	model.position = at
	model.scale = Vector3.ONE * scale_value
	parent.add_child(model)
	return true

func _build_terrain() -> void:
	if terrain.get_child_count() == 0:
		var art := preload("res://scripts/env_art.gd").new()
		terrain.add_child(art)
	terrain.get_child(0).build(mission, model_cache)

func _sync_terrain() -> void:
	if mission.terrain_revision == terrain_seen_revision: return
	_build_terrain()
	for y in range(mini(terrain_seen_board.size(), mission.board.size())):
		for x in range(mini(terrain_seen_board[y].length(), mission.board[y].length())):
			if terrain_seen_board[y][x] != mission.board[y][x]:
				var tile := Vector2i(x, y)
				fx.cover_chunks(Vector3(x, Shot.elevation(mission, tile) * 0.7 + 0.5, y))
	terrain_seen_board = mission.board.duplicate()
	terrain_seen_revision = mission.terrain_revision

func _clear(node: Node) -> void:
	for child in node.get_children(): child.queue_free()

func _refresh_figures() -> void:
	var seen: Dictionary = {}
	for u in mission.units:
		var id := int(u.id)
		if (int(u.hp) <= 0 and str(u.side) == "enemy") or (str(u.side) == "enemy" and not bool(u.awake)):
			if playing_enemy_events and views.has(id): continue
			if views.has(id):
				var fallen: Node3D = views[id]
				views.erase(id)
				fallen.fall()
			continue
		seen[id] = true
		var p := Shot.pos(u)
		var at := Vector3(p.x, Shot.elevation(mission, p) * 0.7, p.y)
		var model_name: String = str(u.model)
		if not views.has(id) and model_cache.has(model_name):
			var view: Node3D = UnitView.new()
			figures.add_child(view)
			view.setup(u, model_cache[model_name], at)
			views[id] = view
			if str(u.side) == "enemy" and not demo_mode:
				fx.float_text(at + Vector3.UP * 1.9, "ALERT!", Color("ff786d"), true)
				sound.play("turn")
		elif views.has(id) and not playing_enemy_events and views[id].position.distance_to(at) > 0.05 and (views[id].motion == null or not views[id].motion.is_running()):
			views[id].travel([at])
		if views.has(id):
			views[id].set_downed(str(u.get("status", "ok")) == "down")
			views[id].set_selected(id == selected_id, str(u.side) == "enemy")
			var cover_level := 0
			var threat := -1
			for other in mission.living("player" if str(u.side) == "enemy" else "enemy"):
				if str(other.side) == "enemy" and not bool(other.awake): continue
				var shot_info: Dictionary = Shot.calculate(mission, other, u)
				if bool(shot_info.los) and bool(shot_info.range_ok) and int(shot_info.hit) > threat:
					threat = int(shot_info.hit)
					cover_level = 2 if int(shot_info.cover) == 40 else 1 if int(shot_info.cover) == 20 else 0
			if threat < 0 and Shot.in_cover(mission, p): cover_level = 1
			views[id].set_cover(cover_level)
	if not bool(mission.prisoner.freed) or mission.result != "win":
		var p := Vector2i(int(mission.prisoner.x), int(mission.prisoner.y))
		var at := Vector3(p.x, Shot.elevation(mission, p) * 0.7 + 0.5, p.y)
		if not is_instance_valid(figures.get_node_or_null("Prisoner")):
			var marker := _box(figures, at, Vector3(0.35, 1.0, 0.35), Color("f3d498"))
			marker.name = "Prisoner"
		else: figures.get_node("Prisoner").position = at

func _refresh_highlights(force: bool = false) -> void:
	hud_controls._refresh_highlights(force)

func _build_ui() -> void:
	hud_controls._build_ui()

func _choose_action(mode: String) -> void:
	if player_attack_pending or playing_enemy_events or mission.phase != "player" or mission.result != "": return
	if mode != "move" and mission.ability_reason(selected_id, mode) != "":
		warning_label.text = mission.ability_reason(selected_id, mode)
		_refresh()
		return
	if cinematic: _skip_cinematic()
	preview_tile = Vector2i(-1, -1)
	target_id = -1
	end_turn_armed = false
	warning_label.text = ""
	action = mode
	if mission.abilities.has(mode) and mode not in ["move", "shoot", "strike", "push", "free", "overwatch", "hunker"]:
		if mission.ability_reason(selected_id, mode) != "": warning_label.text = mission.ability_reason(selected_id, mode)
		elif str(mission.abilities[mode].target) == "self": _use_ability(-1)
		elif str(mission.abilities[mode].target).begins_with("ally") or str(mission.abilities[mode].target).begins_with("enemy"): _cycle_target(1)
		else: warning_label.text = "Choose a tile, then click or press Enter to confirm."
		_refresh(); return
	if mode == "overwatch":
		if mission.overwatch(selected_id): _after_action()
	elif mode == "hunker":
		if mission.hunker(selected_id): _after_action()
	elif mode in ["shoot", "strike", "push"]:
		_cycle_target(1)
	sound.play("click")
	_refresh()

func _use_ability(id: int = -1, tile: Vector2i = Vector2i(-1, -1)) -> void:
	var target: Dictionary = mission.unit_by_id(id)
	var old_hp := int(target.get("hp", 0))
	var was_down := str(target.get("status", "ok")) == "down"
	if not mission.use_ability(selected_id, action, id, tile): return
	if not target.is_empty() and (int(target.hp) > old_hp or was_down):
		var p: Vector2i = Shot.pos(target)
		var at := Vector3(p.x, Shot.elevation(mission, p) * 0.7 + 1.1, p.y)
		fx.heal(at, int(target.hp) - old_hp)
		if views.has(id): views[id].set_downed(false)
	elif not target.is_empty() and str(target.side) == "enemy":
		var p: Vector2i = Shot.pos(target)
		var at := Vector3(p.x, Shot.elevation(mission, p) * 0.7 + 1.1, p.y)
		if int(target.hp) < old_hp:
			var actor: Dictionary = mission.unit_by_id(selected_id)
			var from := Vector3(int(actor.x), Shot.elevation(mission, Shot.pos(actor)) * 0.7 + 1.1, int(actor.y))
			if str(actor.class_name) in ["Guardian", "Consular"]: fx.saber(from, at)
			else: fx.bolt(from, at, false, false)
			fx.float_text(at + Vector3.UP * 0.7, "-%d" % (old_hp - int(target.hp)), Color("ff736c"), true)
		else: fx.float_text(at + Vector3.UP * 0.7, str(mission.abilities[action].name).to_upper(), Color("f4ce79"), true)
	elif action in ["smoke", "barrier", "shieldDrone", "battleMed", "rally"]:
		var p: Vector2i = tile if tile.x >= 0 else Shot.pos(target) if not target.is_empty() else Shot.pos(mission.unit_by_id(selected_id))
		fx.heal(Vector3(p.x, Shot.elevation(mission, p) * 0.7 + 1.1, p.y), 0)
	_after_action()
	_refresh()

func _select(id: int) -> void:
	if player_attack_pending or playing_enemy_events: return
	if selected_id == id and target_id < 0: return
	if cinematic: _skip_cinematic()
	selected_id = id
	action = "move"
	target_id = -1
	preview_tile = Vector2i(-1, -1)
	end_turn_armed = false
	warning_label.text = ""
	sound.play("click")
	var u: Dictionary = mission.unit_by_id(id)
	if not u.is_empty(): _glide_to(Vector3(int(u.x), 0, int(u.y)), 0.35)
	_refresh()

func _after_action() -> void:
	preview_tile = Vector2i(-1, -1)
	target_id = -1
	action = "move"
	end_turn_armed = false
	warning_label.text = ""
	var current: Dictionary = mission.unit_by_id(selected_id)
	if not current.is_empty() and int(current.ap) <= 0:
		var next_id: int = InputControls.next_squad(mission, selected_id, 1, true)
		if next_id >= 0 and next_id != selected_id: _select(next_id)

func _cycle_target(direction: int) -> void:
	var options: Array[Dictionary] = InputControls.valid_targets(mission, mission.unit_by_id(selected_id), action)
	if options.is_empty():
		target_id = -1
		warning_label.text = "No valid targets for %s." % str(mission.abilities.get(action, {}).get("name", action))
		return
	var current := -1
	for i in range(options.size()):
		if int(options[i].id) == target_id: current = i
	target_id = int(options[posmod(current + direction, options.size())].id) if current >= 0 else int(options[0 if direction > 0 else options.size() - 1].id)
	warning_label.text = "TAB / SHIFT+TAB target  •  ENTER / CLICK confirm  •  ESC cancel"
	_frame_target()
	_refresh_highlights()
	_show_shot()

func _frame_target() -> void:
	var actor: Dictionary = mission.unit_by_id(selected_id)
	var target: Dictionary = mission.unit_by_id(target_id)
	if actor.is_empty() or target.is_empty(): return
	var midpoint := Vector3((float(actor.x) + float(target.x)) * 0.5, 0, (float(actor.y) + float(target.y)) * 0.5)
	_glide_to(midpoint, 0.35)

func _cancel_order() -> void:
	target_id = -1
	preview_tile = Vector2i(-1, -1)
	action = "move"
	end_turn_armed = false
	warning_label.text = ""
	_refresh()

func _glide_to(point: Vector3, seconds: float) -> void:
	if camera_tween != null and camera_tween.is_running(): camera_tween.kill()
	camera_tween = create_tween()
	camera_tween.tween_property(self, "pivot", point, seconds).set_trans(Tween.TRANS_SINE)
	camera_tween.tween_callback(_update_camera)
	set_process(true)

func _process(_delta: float) -> void:
	if camera_tween != null and camera_tween.is_running(): _update_camera()
	if cinematic or mission == null: return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_D): direction.x += 1
	if Input.is_key_pressed(KEY_W): direction.y += 1
	if Input.is_key_pressed(KEY_S): direction.y -= 1
	var mouse := get_viewport().get_mouse_position()
	var size := get_viewport().get_visible_rect().size
	if mouse.x >= 0 and mouse.y >= 0 and mouse.x <= size.x and mouse.y <= size.y:
		if mouse.x < 14: direction.x -= 1
		elif mouse.x > size.x - 14: direction.x += 1
		if mouse.y < 14: direction.y += 1
		elif mouse.y > size.y - 14: direction.y -= 1
	if direction != Vector2.ZERO:
		if camera_tween != null and camera_tween.is_running(): camera_tween.kill()
		var right := Vector3(camera.global_basis.x.x, 0, camera.global_basis.x.z).normalized()
		var forward := Vector3(-camera.global_basis.z.x, 0, -camera.global_basis.z.z).normalized()
		pivot += (right * direction.x + forward * direction.y).normalized() * zoom * 0.6 * _delta
		_update_camera()

func _action_cam(actor: Node3D, target: Node3D) -> void:
	if not action_camera or actor == null or target == null: return
	_skip_cinematic()
	if camera_tween != null and camera_tween.is_running(): camera_tween.kill()
	cinematic = true
	var direction := (target.position - actor.position).normalized()
	var shoulder := actor.position - direction * 3.0 + Vector3(-direction.z, 0, direction.x) * 1.25 + Vector3.UP * 2.3
	var look := (actor.position + target.position) * 0.5 + Vector3.UP
	action_tween = create_tween().set_parallel(true)
	action_tween.tween_property(camera, "position", shoulder, 0.6).set_trans(Tween.TRANS_SINE)
	action_tween.tween_method(func(value: Vector3) -> void: camera.look_at(value, Vector3.UP), pivot, look, 0.6)
	get_tree().create_timer(0.95).timeout.connect(_skip_cinematic)

func _skip_cinematic() -> void:
	if not cinematic: return
	cinematic = false
	if action_tween != null and action_tween.is_running(): action_tween.kill()
	var active: Dictionary = mission.unit_by_id(selected_id)
	if not active.is_empty(): pivot = Vector3(int(active.x), 0, int(active.y))
	_update_camera()

func _shake(power: float) -> void:
	var original := camera.position
	var tween := create_tween()
	for i in range(4):
		tween.tween_property(camera, "position", original + Vector3(randf_range(-power, power), randf_range(-power, power), 0), 0.035)
	tween.tween_property(camera, "position", original, 0.08)

func _move_selected(dest: Vector2i) -> void:
	var u: Dictionary = mission.unit_by_id(selected_id)
	if u.is_empty(): return
	var route_data: Dictionary = mission.paths(u, int(u.mob) * 2)
	var points: Array[Vector3] = []
	if route_data.costs.has(dest):
		var cursor := dest
		while route_data.prev.has(cursor):
			points.push_front(Vector3(cursor.x, Shot.elevation(mission, cursor) * 0.7, cursor.y))
			cursor = route_data.prev[cursor]
	if mission.move(selected_id, dest):
		if views.has(selected_id): views[selected_id].travel(points)
		_glide_to(Vector3(dest.x, 0, dest.y), 0.35)
		_after_action()
		_refresh()

func _attack(target_id: int, mode: String) -> void:
	if player_attack_pending or playing_enemy_events: return
	var actor: Dictionary = mission.unit_by_id(selected_id)
	var target: Dictionary = mission.unit_by_id(target_id)
	if actor.is_empty() or target.is_empty(): return
	var before_hp := int(target.hp)
	var before_armor := int(target.get("armor", 0))
	var old_target := Shot.pos(target)
	var old_log: int = mission.log_lines.size()
	var success: bool = mission.push(selected_id, target_id) if mode == "push" else mission.shot(selected_id, target_id, mode)
	if not success: return
	var from := Vector3(int(actor.x), Shot.elevation(mission, Shot.pos(actor)) * 0.7 + 1.15, int(actor.y))
	var to := Vector3(old_target.x, Shot.elevation(mission, old_target) * 0.7 + 1.1, old_target.y)
	_action_cam(views.get(selected_id), views.get(target_id))
	var outcome := str(mission.log_lines[old_log]) if mission.log_lines.size() > old_log else ""
	var damage := before_hp - int(target.hp)
	player_attack_pending = true
	var event := {"actor": selected_id, "target": target_id, "mode": mode, "from": from, "to": to, "destination": Vector3(int(target.x), Shot.elevation(mission, Shot.pos(target)) * 0.7, int(target.y)), "moved": Shot.pos(target) != old_target, "damage": damage, "outcome": outcome, "armor_lost": int(target.get("armor", 0)) < before_armor, "killed": int(target.hp) <= 0}
	if action_camera and not demo_mode:
		get_tree().create_timer(0.42).timeout.connect(func() -> void:
			if is_instance_valid(self): AttackPresentation.play(self, event))
	else: AttackPresentation.play(self, event)

func _request_end_turn() -> void:
	if player_attack_pending or playing_enemy_events or mission.result != "" or mission.phase != "player": return
	var ready := 0
	for u in mission.living("player"):
		if int(u.ap) > 0: ready += 1
	if ready > 0 and not end_turn_armed:
		end_turn_armed = true
		warning_label.text = "%d squad member%s still ha%s actions. Press Enter again to end turn." % [ready, "s" if ready != 1 else "", "ve" if ready != 1 else "s"]
		return
	end_turn_armed = false
	warning_label.text = ""
	_end_turn()

func _end_turn() -> void:
	enemy_frame_sequence += 1
	phase_banner.visible = true
	sound.play("turn")
	mission.end_turn()
	var events: Array[Dictionary] = mission.action_events.duplicate(true)
	playing_enemy_events = not events.is_empty()
	_refresh()
	if events.is_empty():
		phase_banner.visible = false
		get_node("/root/CampaignFlow").battle_beat(self)
	else:
		EnemyPresentation.play(self, events, enemy_frame_sequence)

func _demo(kind: String) -> void:
	demo_mode = true
	var path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): path = arg.trim_prefix("--capture=")
	if kind == "skills-bar":
		selected_id = int(mission.living("player")[1].id)
		_refresh()
		if path != "": _capture(path, 2)
		return
	if kind in ["skills-heal", "skills-revive"]:
		var consular: Dictionary = mission.living("player")[1]
		var patient: Dictionary = mission.living("player")[2]
		selected_id = int(consular.id)
		if kind == "skills-revive":
			mission.apply_damage(patient, 99)
			_refresh()
			await get_tree().create_timer(0.5).timeout
		else: patient.hp = maxi(1, int(patient.hp) - 4)
		action = "forceHeal"
		_use_ability(int(patient.id))
		if kind == "skills-revive": selected_id = int(patient.id); _refresh()
		if path != "": _capture(path, 2)
		return
	var enemy: Dictionary = mission.living("enemy")[0]
	enemy.awake = true
	if kind == "push":
		enemy.x = 4; enemy.y = 19
		mission.set_tile(Vector2i(4, 18), "c")
		_build_terrain()
	else:
		enemy.x = 8; enemy.y = 19
	selected_id = int(mission.living("player")[0].id) if kind == "push" else int(mission.living("player")[2].id)
	if kind in ["shot", "aim"]: hovered = Shot.pos(enemy)
	_refresh()
	if kind == "aim":
		_choose_action("shoot")
		if path != "": _capture(path, 5)
		return
	if kind == "push": _attack(int(enemy.id), "push")
	else: _attack(int(enemy.id), "shoot")
	if path != "":
		await get_tree().create_timer(0.18).timeout
		_capture(path, 1)

func _refresh() -> void:
	get_node("/root/CampaignFlow").battle_refresh(self)
	_sync_terrain()
	reinforcement_view.show_tile(mission.reinforcement_marker, mission)
	hud_controls._refresh()

func _show_shot() -> void:
	hud_controls._show_shot()

func _update_camera() -> void:
	pitch = clampf(pitch, 0.25, 1.4)
	zoom = clampf(zoom, 10.0, 65.0)
	var direction := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	camera.position = pivot + direction * zoom
	camera.look_at(pivot, Vector3.UP)

func _screen_tile(screen: Vector2) -> Vector2i:
	var origin := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	if abs(dir.y) < 0.01: return Vector2i(-1, -1)
	for height in [1.5, 0.8, 0.1]:
		var travel: float = (float(height) - origin.y) / dir.y
		if travel < 0: continue
		var point: Vector3 = origin + dir * travel
		var p := Vector2i(roundi(point.x), roundi(point.z))
		if mission.in_bounds(p) and abs(Shot.elevation(mission, p) * 0.7 + 0.1 - height) < 0.15: return p
	return Vector2i(-1, -1)

func _rotate_camera(amount: float) -> void:
	if camera_tween != null and camera_tween.is_running(): camera_tween.kill()
	camera_tween = create_tween()
	camera_tween.tween_property(self, "yaw", yaw + amount, 0.28).set_trans(Tween.TRANS_SINE)

func _skip_activity() -> void:
	enemy_frame_sequence += 1
	playing_enemy_events = false
	if camera_tween != null and camera_tween.is_running(): camera_tween.kill()
	_skip_cinematic()
	phase_banner.visible = false
	_refresh()
	var unit: Dictionary = mission.unit_by_id(selected_id)
	if not unit.is_empty(): pivot = Vector3(int(unit.x), 0, int(unit.y))
	_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	if player_attack_pending:
		if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE: _skip_cinematic()
		return
	input_controls.handle_event(event)
