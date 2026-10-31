extends Node3D

const Mission = preload("res://scripts/mission.gd")
const Shot = preload("res://scripts/shot.gd")
var mission: RefCounted
var camera: Camera3D
var pivot: Vector3 = Vector3(13, 0, 13)
var yaw: float = 0.3
var pitch: float = 0.8
var zoom: float = 31.0
var drag_button: int = 0
var selected_id: int = -1
var action: String = "move"
var hovered: Vector2i = Vector2i(-1, -1)
var terrain: Node3D
var figures: Node3D
var highlights: Node3D
var hud: CanvasLayer
var title_label: Label
var objective_label: Label
var selected_label: Label
var shot_label: Label
var log_label: Label
var result_panel: PanelContainer
var result_label: Label
var action_buttons: Dictionary = {}
var model_cache: Dictionary = {}

func _ready() -> void:
	mission = Mission.new(7)
	_setup_scene()
	_load_models()
	_build_terrain()
	_build_ui()
	selected_id = int(mission.living("player")[0].id)
	_update_camera()
	_refresh()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): _capture.call_deferred(arg.trim_prefix("--capture="))

func _capture(path: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("SCREENSHOT: %s (%s)" % [path, "ok" if error == OK else "error %d" % error])
	get_tree().quit(0 if error == OK else 1)

func _setup_scene() -> void:
	terrain = Node3D.new(); terrain.name = "Terrain"; add_child(terrain)
	figures = Node3D.new(); figures.name = "Units"; add_child(figures)
	highlights = Node3D.new(); highlights.name = "RangePreview"; add_child(highlights)
	camera = Camera3D.new(); camera.current = true; camera.fov = 45; add_child(camera)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("111b2a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9cacbd")
	env.ambient_light_energy = 0.8
	world.environment = env; add_child(world)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55, -35, 0); sun.light_energy = 1.2; add_child(sun)

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
	for child in terrain.get_children(): child.queue_free()
	for y in range(int(mission.spec.height)):
		for x in range(int(mission.spec.width)):
			var p := Vector2i(x, y)
			var c: String = mission.tile(p)
			var elev: int = Shot.elevation(mission, p)
			var floor_color := Color("293c4b") if (x + y) % 2 == 0 else Color("304656")
			if c == "^": floor_color = Color("536471")
			if c == "M": floor_color = Color("627480")
			if c == "E": floor_color = Color("137a91")
			if c == "r": floor_color = Color("5f5c59")
			_box(terrain, Vector3(x, elev * 0.7 - 0.08, y), Vector3(0.98, max(0.15, elev * 1.4 + 0.15), 0.98), floor_color)
			if c == "#":
				var edge: bool = x == 0 or y == 0 or x == int(mission.spec.width) - 1 or y == int(mission.spec.height) - 1
				var wall_height := 0.3 if edge else 1.6
				_box(terrain, Vector3(x, elev * 0.7 + wall_height * 0.5, y), Vector3(0.85, wall_height, 0.85), Color("68717a"))
			elif c in ["c", "h", "k"]:
				var key := "terminal" if c == "k" else "crate"
				if not _instance_model(terrain, key, Vector3(x, elev * 0.7 + 0.1, y), 0.42):
					_box(terrain, Vector3(x, elev * 0.7 + (0.65 if c == "h" else 0.35), y), Vector3(0.7, 1.3 if c == "h" else 0.7, 0.7), Color("a77c54"))
	# Prison cell marker and visible evacuation beacon.
	_box(terrain, Vector3(int(mission.prisoner.x), 0.02, int(mission.prisoner.y)), Vector3(0.85, 0.07, 0.85), Color("e5ae61"))

func _clear(node: Node) -> void:
	for child in node.get_children(): child.queue_free()

func _refresh_figures() -> void:
	_clear(figures)
	for u in mission.units:
		if int(u.hp) <= 0: continue
		if str(u.side) == "enemy" and not bool(u.awake): continue
		var p := Shot.pos(u)
		var at := Vector3(p.x, Shot.elevation(mission, p) * 0.7, p.y)
		var model_name: String = str(u.model)
		if not _instance_model(figures, model_name, at, 1.2):
			_box(figures, at + Vector3(0, 0.55, 0), Vector3(0.4, 1.1, 0.4), Color("7dc5e0") if str(u.side) == "player" else Color("de6d67"))
		var ring_color := Color("71d8ff") if str(u.side) == "player" else Color("f37065")
		if int(u.id) == selected_id: ring_color = Color("ffe493")
		_box(figures, at + Vector3(0, 0.035, 0), Vector3(0.8, 0.06, 0.8), ring_color)
	if not bool(mission.prisoner.freed) or mission.result != "win":
		var p := Vector2i(int(mission.prisoner.x), int(mission.prisoner.y))
		var at := Vector3(p.x, Shot.elevation(mission, p) * 0.7 + 0.5, p.y)
		_box(figures, at, Vector3(0.35, 1.0, 0.35), Color("f3d498"))

func _refresh_highlights() -> void:
	_clear(highlights)
	var u: Dictionary = mission.unit_by_id(selected_id)
	if u.is_empty() or mission.result != "" or mission.phase != "player": return
	if action == "move" and int(u.ap) > 0:
		var reach: Dictionary = mission.paths(u, int(u.mob) * 2)
		for p in reach.costs:
			if p == Shot.pos(u): continue
			var cost: int = int(reach.costs[p])
			if cost > int(u.mob) and int(u.ap) < 2: continue
			var color := Color(0.15, 0.6, 0.9, 0.24) if cost <= int(u.mob) else Color(0.95, 0.66, 0.17, 0.20)
			var box := _box(highlights, Vector3(p.x, Shot.elevation(mission, p) * 0.7 + 0.09, p.y), Vector3(0.8, 0.04, 0.8), color)
			box.material_override = _mat(color, true)
	if hovered.x >= 0:
		var box := _box(highlights, Vector3(hovered.x, Shot.elevation(mission, hovered) * 0.7 + 0.14, hovered.y), Vector3(0.95, 0.05, 0.95), Color("ffffff"))
		box.material_override = _mat(Color(1, 1, 1, 0.45), true)

func _label(text_value: String, size: int = 18) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("edf3f4"))
	return label

func _button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(118, 39)
	button.pressed.connect(callback)
	return button

func _build_ui() -> void:
	hud = CanvasLayer.new(); add_child(hud)
	var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.add_child(root)
	var top := PanelContainer.new(); top.anchor_right = 1.0; top.offset_bottom = 76; root.add_child(top)
	var top_row := HBoxContainer.new(); top.add_child(top_row)
	title_label = _label("TEMPLE WATCH  /  BREAK THE DETENTION LINE", 24); title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_row.add_child(title_label)
	objective_label = _label("", 18); top_row.add_child(objective_label)
	var left := PanelContainer.new(); left.offset_top = 86; left.offset_left = 10; left.offset_right = 250; left.anchor_bottom = 1.0; left.offset_bottom = -170; root.add_child(left)
	var left_box := VBoxContainer.new(); left.add_child(left_box)
	left_box.add_child(_label("SQUAD", 20))
	for u in mission.living("player"):
		var id: int = int(u.id)
		left_box.add_child(_button(str(u.name), func() -> void: selected_id = id; _refresh()))
	selected_label = _label("", 16); left_box.add_child(selected_label)
	var right := PanelContainer.new(); right.anchor_left = 1.0; right.anchor_right = 1.0; right.offset_left = -300; right.offset_right = -10; right.offset_top = 86; right.anchor_bottom = 1.0; right.offset_bottom = -170; root.add_child(right)
	var right_box := VBoxContainer.new(); right.add_child(right_box)
	right_box.add_child(_label("SHOT PREVIEW", 20))
	shot_label = _label("Hover over a target", 15); shot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; right_box.add_child(shot_label)
	right_box.add_child(_label("COMBAT LOG", 20))
	log_label = _label("", 14); log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; right_box.add_child(log_label)
	var bottom := PanelContainer.new(); bottom.anchor_top = 1.0; bottom.anchor_right = 1.0; bottom.anchor_bottom = 1.0; bottom.offset_top = -160; root.add_child(bottom)
	var bottom_box := VBoxContainer.new(); bottom.add_child(bottom_box)
	bottom_box.add_child(_label("LMB select / order • RMB drag pan • MMB drag orbit • Wheel zoom", 15))
	var row := HBoxContainer.new(); bottom_box.add_child(row)
	for mode in ["move", "shoot", "strike", "push", "free", "overwatch"]:
		var b := _button(mode.capitalize(), func() -> void: _choose_action(mode))
		row.add_child(b); action_buttons[mode] = b
	row.add_child(_button("End Turn", func() -> void: mission.end_turn(); _refresh()))
	row.add_child(_button("Restart", func() -> void: get_tree().reload_current_scene()))
	result_panel = PanelContainer.new(); result_panel.visible = false; result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER); result_panel.offset_left = -220; result_panel.offset_right = 220; result_panel.offset_top = -100; result_panel.offset_bottom = 100; root.add_child(result_panel)
	var result_box := VBoxContainer.new(); result_panel.add_child(result_box)
	result_label = _label("", 28); result_box.add_child(result_label)
	result_box.add_child(_button("Restart mission", func() -> void: get_tree().reload_current_scene()))

func _choose_action(mode: String) -> void:
	action = mode
	if mode == "overwatch": mission.overwatch(selected_id)
	_refresh()

func _refresh() -> void:
	var u: Dictionary = mission.unit_by_id(selected_id)
	if u.is_empty() or int(u.get("hp", 0)) <= 0:
		var survivors: Array[Dictionary] = mission.living("player")
		if not survivors.is_empty():
			selected_id = int(survivors[0].id)
			u = survivors[0]
	objective_label.text = "TURN %d / %d   •   %s   •   %s" % [mission.turn, int(mission.spec.turn_limit), "FREED" if bool(mission.prisoner.freed) else "FREE PRISONER", "EVAC" if bool(mission.prisoner.freed) else "CELL"]
	selected_label.text = "%s\n%s  HP %d/%d\nAP %d/3  Focus %d" % [u.get("name", ""), u.get("class_name", ""), int(u.get("hp", 0)), int(u.get("max_hp", 0)), int(u.get("ap", 0)), int(u.get("focus_left", 0))]
	log_label.text = "\n".join(mission.log_lines.slice(max(0, mission.log_lines.size() - 8)))
	for mode in action_buttons:
		action_buttons[mode].disabled = mission.result != "" or (mode == "free" and bool(mission.prisoner.freed)) or (mode in ["strike", "push"] and str(u.get("class_name", "")) not in ["Guardian", "Consular"])
	result_panel.visible = mission.result != ""
	if mission.result != "": result_label.text = "MISSION COMPLETE" if mission.result == "win" else "MISSION FAILED"
	_refresh_figures(); _refresh_highlights(); _show_shot()

func _show_shot() -> void:
	var actor: Dictionary = mission.unit_by_id(selected_id)
	var target: Dictionary = {}
	for u in mission.living("enemy"):
		if Shot.pos(u) == hovered and bool(u.awake): target = u; break
	if actor.is_empty() or target.is_empty():
		shot_label.text = "Hover over a spotted enemy.\nBlue = 1 AP move\nAmber = 2 AP dash"
		return
	var info: Dictionary = Shot.calculate(mission, actor, target, action == "strike")
	var breakdown := ""
	for item in info.lines: breakdown += "%s  %+d\n" % [item[0], int(item[1])]
	shot_label.text = "%s  HP %d\n%s\nHIT %d%%  CRIT %d%%  GRAZE %d%%\n%s\n%s" % [target.name, int(target.hp), breakdown, int(info.hit), int(info.crit), int(info.graze), "LOS clear" if bool(info.los) else "LOS blocked", "In range" if bool(info.range_ok) else "Out of range"]

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom -= 2; _update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom += 2; _update_camera()
		elif event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]: drag_button = event.button_index if event.pressed else 0
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var p := _screen_tile(event.position)
			if p.x < 0: return
			for u in mission.living("player"):
				if Shot.pos(u) == p: selected_id = int(u.id); _refresh(); return
			var target_id := -1
			for u in mission.living("enemy"):
				if Shot.pos(u) == p and bool(u.awake): target_id = int(u.id)
			if action == "move": mission.move(selected_id, p)
			elif action == "free": mission.free_prisoner(selected_id)
			elif target_id >= 0 and action == "push": mission.push(selected_id, target_id)
			elif target_id >= 0 and action in ["shoot", "strike"]: mission.shot(selected_id, target_id, action)
			_refresh()
	elif event is InputEventMouseMotion:
		if drag_button == MOUSE_BUTTON_MIDDLE: yaw -= event.relative.x * 0.008; pitch += event.relative.y * 0.008; _update_camera()
		elif drag_button == MOUSE_BUTTON_RIGHT:
			var right := camera.global_basis.x
			var forward := -camera.global_basis.z; forward.y = 0; forward = forward.normalized()
			pivot += (-right * event.relative.x + forward * event.relative.y) * zoom * 0.0015
			_update_camera()
		else:
			var p := _screen_tile(event.position)
			if p != hovered: hovered = p; _refresh_highlights(); _show_shot()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER: mission.end_turn(); _refresh()
		elif event.keycode == KEY_R: get_tree().reload_current_scene()
