extends Node3D

const Mission = preload("res://scripts/combat_mission.gd")
const Shot = preload("res://scripts/shot.gd")
const UnitView = preload("res://scripts/unit_view.gd")
const Effects = preload("res://scripts/fx.gd")
const Audio = preload("res://scripts/audio.gd")
const HudControls = preload("res://scripts/hud_controls.gd")
const InputControls = preload("res://scripts/input_controls.gd")
const EnemyPresentation = preload("res://scripts/enemy_presentation.gd")
const AttackPresentation = preload("res://scripts/attack_presentation.gd")
const Prefs = preload("res://scripts/campaign/strat_preferences.gd")
const Ability = preload("res://scripts/abilities_engine.gd")
const BattleCamera = preload("res://scripts/battle11_camera.gd")
var animate_headless := false
var cam = preload("res://scripts/cam_combat.gd").new()
var scene_view = preload("res://scripts/combat_scene.gd").new()
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
var presentation_routes: Dictionary = {}
var playing_enemy_events := false
var player_attack_pending := false
var terrain_seen_revision := 0
var terrain_seen_board: Array[String] = []
var reinforcement_view: Node3D

func _ready() -> void:
	scene_view.g = self
	cam.g = self
	add_child(cam)
	var flow := get_node("/root/CampaignFlow")
	mission = Mission.adopt(flow.create_battle(7), flow.campaign.state if flow.active and flow.campaign != null else {})
	if mission.modern:
		pivot = Vector3(float(mission.spec.width)*0.5,0,float(mission.spec.height)*0.5)
	zoom = BattleCamera.selected_zoom(mission)
	action_camera = bool(Prefs.get_value("cine"))
	hud_controls = HudControls.new()
	hud_controls.g = self
	input_controls = InputControls.new()
	input_controls.g = self
	_setup_scene()
	if preload("res://scripts/phone_layout.gd").narrow(get_tree().root.size):
		camera.fov = 47.0
	_load_models()
	_build_terrain()
	terrain_seen_revision = mission.terrain_revision
	terrain_seen_board = mission.board.duplicate()
	_build_ui()
	selected_id = int(mission.living("player")[0].id)
	pivot = BattleCamera.clamp_pivot(mission, Vector3(mission.living("player")[0].x, 0, mission.living("player")[0].y))
	if mission.modern and int(mission.spec.objective.get("hold_turns",0)) > 0:
		var gate := Vector3(float(mission.spec.objective.points[0][0]),0,float(mission.spec.objective.points[0][1]))
		pivot = BattleCamera.clamp_pivot(mission,gate + Vector3(0,0,-2.5))
		zoom = maxf(zoom,25.0)
	pivot = BattleCamera.phone_focus(pivot,yaw,1.55)
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
	scene_view._setup_scene()

func _load_models() -> void:
	scene_view._load_models()

func _mat(color: Color, transparent: bool = false) -> StandardMaterial3D:
	return scene_view._mat(color, transparent)

func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	return scene_view._box(parent, at, size, color)

func _instance_model(parent: Node3D, key: String, at: Vector3, scale_value: float) -> bool:
	return scene_view._instance_model(parent, key, at, scale_value)

func _build_terrain() -> void:
	scene_view._build_terrain()

func _sync_terrain() -> void:
	scene_view._sync_terrain()

func _clear(node: Node) -> void:
	scene_view._clear(node)

func _refresh_figures() -> void:
	scene_view._refresh_figures()

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
		else: warning_label.text = "Choose a tile, then tap again to confirm." if preload("res://scripts/phone_layout.gd").touch_device() else "Choose a tile, then click or press Enter to confirm."
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
	if player_attack_pending or playing_enemy_events: return
	var actor: Dictionary = mission.unit_by_id(selected_id)
	if mission.ability_reason(selected_id, action) != "": return
	var ability_id := action
	var target: Dictionary = mission.unit_by_id(id)
	var from := Vector3(actor.x, Shot.elevation(mission, Shot.pos(actor)) * 0.7, actor.y)
	var p: Vector2i = Shot.pos(target) if not target.is_empty() else tile if tile.x >= 0 else Shot.pos(actor)
	var to := Vector3(p.x, Shot.elevation(mission, p) * 0.7, p.y)
	player_attack_pending = true
	mission.presentation_active = true
	cam.skip_requested = false
	var def: Dictionary = mission.abilities[ability_id]
	if str(def.effect) in ["attack", "displace", "blast", "wave", "breach", "collapse", "status"]: await cam.frame(from, to, "force")
	mission.action_events.clear()
	var before: Dictionary = {}
	for u in mission.units: before[int(u.id)] = int(u.hp)
	if mission.use_ability(selected_id, ability_id, id, tile):
		if views.has(selected_id): views[selected_id].act("reload" if ability_id == "reload" else "cast")
		fx.ability(ability_id, from + Vector3.UP, to + Vector3.UP)
		await cam.wait(0.3)
		for u in mission.units:
			var change := int(u.hp) - int(before.get(int(u.id), u.hp))
			if change != 0:
				var at := Vector3(u.x, Shot.elevation(mission, Shot.pos(u)) * 0.7 + 1.7, u.y)
				fx.float_text(at, "%+d HP" % change, Color("6aeda5") if change > 0 else Color("ffad8d"))
		await EnemyPresentation.drain(self)
	cam.finish()
	player_attack_pending = false
	mission.presentation_active = false
	phase_banner.visible = false
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
	if mission.identity != null: mission.identity.voice(mission,u,"select")
	if not u.is_empty(): _glide_to(BattleCamera.phone_focus(Vector3(int(u.x), 0, int(u.y)),yaw,1.55), 0.35, BattleCamera.selected_zoom(mission))
	_refresh()

func _after_action() -> void:
	preview_tile = Vector2i(-1, -1)
	target_id = -1
	action = "move"
	end_turn_armed = false
	warning_label.text = ""
	var current: Dictionary = mission.unit_by_id(selected_id)
	if RescueSettings.battle_value("auto_select") and not current.is_empty():
		var next_id: int = InputControls.next_squad(mission, selected_id, 1, true)
		if next_id >= 0 and next_id != selected_id: _select.call_deferred(next_id)

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
	midpoint = preload("res://scripts/battle12_aim.gd").phone_frame_point(self, midpoint)
	var framing_zoom: float = BattleCamera.target_zoom(mission, Vector2(float(actor.x), float(actor.y)).distance_to(Vector2(float(target.x), float(target.y))))
	_glide_to(midpoint, 0.38, preload("res://scripts/battle12_aim.gd").frame_zoom(self, framing_zoom))

func _cancel_order() -> void:
	target_id = -1
	preview_tile = Vector2i(-1, -1)
	action = "move"
	end_turn_armed = false
	warning_label.text = ""
	_refresh()

func _recenter() -> void:
	var unit: Dictionary = mission.unit_by_id(selected_id)
	if unit.is_empty(): return
	_glide_to(BattleCamera.phone_focus(Vector3(unit.x, 0, unit.y),yaw,1.55), 0.35, BattleCamera.selected_zoom(mission))

func _glide_to(point: Vector3, seconds: float, target_zoom: float = -1.0) -> void:
	if Prefs.get_value("motion"):
		pivot = point
		if target_zoom > 0.0: zoom = target_zoom
		_update_camera(); return
	seconds /= float(Prefs.get_value("speed"))
	if camera_tween != null and camera_tween.is_running(): camera_tween.kill()
	camera_tween = create_tween()
	camera_tween.set_parallel(true)
	camera_tween.tween_property(self, "pivot", point, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if target_zoom > 0.0: camera_tween.tween_property(self, "zoom", target_zoom, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_callback(_update_camera)
	set_process(true)

func _process(_delta: float) -> void:
	if mission != null: scene_view.arrange_labels()
	if player_attack_pending and not playing_enemy_events and not cinematic and selected_id >= 0 and views.has(selected_id):
		var moving_view: Node3D = views[selected_id]
		if moving_view.motion != null and moving_view.motion.is_running():
			pivot = pivot.lerp(Vector3(moving_view.position.x, 0, moving_view.position.z), minf(1.0, _delta * 7.0)); _update_camera()
	if camera_tween != null and camera_tween.is_running(): _update_camera()
	if cinematic or player_attack_pending or playing_enemy_events or mission == null: return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_D): direction.x += 1
	if Input.is_key_pressed(KEY_W): direction.y += 1
	if Input.is_key_pressed(KEY_S): direction.y -= 1
	var mouse := get_viewport().get_mouse_position()
	var size := get_viewport().get_visible_rect().size
	if hud_controls.phone == null and get_viewport().gui_get_hovered_control() == null and mouse.x >= 0 and mouse.y >= 0 and mouse.x <= size.x and mouse.y <= size.y:
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
	if actor != null and target != null: await cam.frame(actor.position, target.position)


func _skip_cinematic() -> void:
	cam.skip()


func _shake(power: float) -> void:
	if Prefs.get_value("motion"): return
	var original := camera.position
	var tween := create_tween()
	for i in range(4):
		tween.tween_property(camera, "position", original + Vector3(randf_range(-power, power), randf_range(-power, power), 0), 0.035)
	tween.tween_property(camera, "position", original, 0.08)

func _move_selected(dest: Vector2i) -> void:
	if player_attack_pending or playing_enemy_events: return
	var u: Dictionary = mission.unit_by_id(selected_id)
	if u.is_empty(): return
	var reach: Dictionary = mission.paths(u, int(u.mob) * 2)
	if not reach.costs.has(dest): return
	var points: Array[Vector3] = []
	var cursor := dest
	while reach.prev.has(cursor):
		points.push_front(Vector3(cursor.x, Shot.elevation(mission, cursor) * 0.7, cursor.y))
		cursor = reach.prev[cursor]
	if DisplayServer.get_name() == "headless" and not animate_headless:
		if mission.move(selected_id, dest):
			if views.has(selected_id): views[selected_id].travel(points)
			_glide_to(BattleCamera.phone_focus(Vector3(dest.x, 0, dest.y), yaw, 1.55), 0.35, BattleCamera.selected_zoom(mission))
			mission.action_events.clear(); _after_action(); _refresh()
		return
	player_attack_pending = true
	mission.presentation_active = true
	cam.skip_requested = false
	mission.action_events.clear()
	mission.defer_resolution = true
	if mission.move(selected_id, dest):
		mission.defer_resolution = false
		var stop := dest
		for event in mission.action_events:
			if event.kind == "intent" and bool(event.get("reaction",false)) and int(event.target) == selected_id: stop = event.to; break
		var visible_route: Array[Vector3] = []
		for point in points:
			visible_route.append(point)
			if Vector2i(roundi(point.x), roundi(point.z)) == stop: break
		if views.has(selected_id):
			var view: Node3D = views[selected_id]
			view.travel(visible_route)
			while view.motion != null and view.motion.is_running() and not cam.skip_requested: await get_tree().process_frame
		await EnemyPresentation.drain(self)
		if int(u.hp) > 0 and views.has(selected_id) and stop != dest:
			var view: Node3D = views[selected_id]
			var rest: Array[Vector3] = []
			var past := false
			for point in points:
				if past: rest.append(point)
				if Vector2i(roundi(point.x), roundi(point.z)) == stop: past = true
			if not cam.skip_requested:
				view.travel(rest)
				while view.motion != null and view.motion.is_running() and not cam.skip_requested: await get_tree().process_frame
			view.position = Vector3(u.x, Shot.elevation(mission, Shot.pos(u))*0.7, u.y)
	mission.defer_resolution = false
	cam.finish()
	player_attack_pending = false
	mission.presentation_active = false
	phase_banner.visible = false
	if int(u.get("hp", 0)) > 0: _glide_to(BattleCamera.phone_focus(Vector3(u.x, 0, u.y), yaw, 1.55), 0.35, BattleCamera.selected_zoom(mission))
	_after_action()
	_refresh()

func _attack(id: int, mode: String) -> void:
	if player_attack_pending or playing_enemy_events: return
	var actor: Dictionary = mission.unit_by_id(selected_id)
	var target: Dictionary = mission.unit_by_id(id)
	if actor.is_empty() or target.is_empty(): return
	if target not in InputControls.valid_targets(mission, actor, mode): return
	if DisplayServer.get_name() == "headless" and not animate_headless:
		if mode == "push": mission.push(selected_id, id)
		else: mission.shot(selected_id, id, mode)
		mission.action_events.clear(); _after_action(); _refresh()
		return
	player_attack_pending = true
	mission.presentation_active = true
	cam.skip_requested = false
	await cam.frame(Vector3(actor.x, Shot.elevation(mission, Shot.pos(actor)) * 0.7, actor.y), Vector3(target.x, Shot.elevation(mission, Shot.pos(target)) * 0.7, target.y), mode)
	mission.action_events.clear()
	cam.trace.append("resolve_%d" % selected_id)
	var success: bool = mission.push(selected_id, id) if mode == "push" else mission.shot(selected_id, id, mode)
	if success and not mission.action_events.is_empty():
		var event: Dictionary = mission.action_events.pop_front(); event.framed = true
		await AttackPresentation.play(self, event)
	await EnemyPresentation.drain(self)
	cam.finish()
	player_attack_pending = false
	mission.presentation_active = false
	phase_banner.visible = false
	_after_action()
	_refresh()


func _request_end_turn() -> void:
	if player_attack_pending or playing_enemy_events or mission.result != "" or mission.phase != "player": return
	var ready := 0
	for u in mission.living("player"):
		if int(u.ap) > 0: ready += 1
	if ready > 0 and not end_turn_armed:
		end_turn_armed = true
		warning_label.text = ("%d squad member%s still ha%s actions. Tap END TURN again." if preload("res://scripts/phone_layout.gd").touch_device() else "%d squad member%s still ha%s actions. End turn? Press Enter or END TURN again.") % [ready, "s" if ready != 1 else "", "ve" if ready != 1 else "s"]
		return
	end_turn_armed = false
	warning_label.text = ""
	_end_turn()

func _end_turn() -> void:
	if playing_enemy_events or player_attack_pending or mission.result != "": return
	# --- wave10 story ---
	if mission.get("bond_pairs") != null: preload("res://scripts/combat_bonds.gd").nearby_cohesion(mission)
	if DisplayServer.get_name() == "headless" and not animate_headless:
		mission.end_turn()
		mission.action_events.clear()
		_refresh()
		return
	await preload("res://scripts/combat_turns.gd").play(self)
	_recenter()


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
	pitch = clampf(pitch, 0.6, 1.4)
	zoom = clampf(zoom, 6.0, 65.0)
	if mission != null: pivot = BattleCamera.clamp_pivot(mission, pivot)
	var direction := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	camera.position = pivot + direction * zoom
	if mission != null: camera.position = BattleCamera.safe_position(mission, camera.position)
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
	cam.skip()
	if camera_tween != null and camera_tween.is_running(): camera_tween.kill()


func _unhandled_input(event: InputEvent) -> void:
	if player_attack_pending or playing_enemy_events:
		if event is InputEventKey and event.pressed and event.keycode in [KEY_SPACE, KEY_ESCAPE, KEY_ENTER]: _skip_activity()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: _skip_activity()
		return
	input_controls.handle_event(event)
