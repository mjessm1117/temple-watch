extends Node3D

const Mission = preload("res://scripts/mission.gd")
const Shot = preload("res://scripts/shot.gd")
const UnitView = preload("res://scripts/unit_view.gd")
const Effects = preload("res://scripts/fx.gd")
const Audio = preload("res://scripts/audio.gd")
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
var saved_camera: Vector3
var saved_pivot: Vector3
var phase_banner: Label
var path_label: Label
var audio_slider: HSlider
var portrait_viewport: SubViewport
var portrait_model: Node3D
var portrait_kind := ""
var demo_mode := false

func _ready() -> void:
	mission = Mission.new(7)
	_setup_scene()
	_load_models()
	_build_terrain()
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

func _clear(node: Node) -> void:
	for child in node.get_children(): child.queue_free()

func _refresh_figures() -> void:
	var seen: Dictionary = {}
	for u in mission.units:
		var id := int(u.id)
		if int(u.hp) <= 0 or (str(u.side) == "enemy" and not bool(u.awake)):
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
		elif views.has(id) and views[id].position.distance_to(at) > 0.05 and (views[id].motion == null or not views[id].motion.is_running()):
			views[id].travel([at])
		if views.has(id): views[id].set_selected(id == selected_id, str(u.side) == "enemy")
	if not bool(mission.prisoner.freed) or mission.result != "win":
		var p := Vector2i(int(mission.prisoner.x), int(mission.prisoner.y))
		var at := Vector3(p.x, Shot.elevation(mission, p) * 0.7 + 0.5, p.y)
		if not is_instance_valid(figures.get_node_or_null("Prisoner")):
			var marker := _box(figures, at, Vector3(0.35, 1.0, 0.35), Color("f3d498"))
			marker.name = "Prisoner"
		else: figures.get_node("Prisoner").position = at

func _refresh_highlights(force: bool = false) -> void:
	_clear(hover_highlights)
	if force: _clear(range_highlights)
	if path_label != null: path_label.text = ""
	var u: Dictionary = mission.unit_by_id(selected_id)
	if u.is_empty() or mission.result != "" or mission.phase != "player": return
	if force and action == "move" and int(u.ap) > 0:
		var reach: Dictionary = mission.paths(u, int(u.mob) * 2)
		for p in reach.costs:
			if p == Shot.pos(u): continue
			var cost: int = int(reach.costs[p])
			if cost > int(u.mob) and int(u.ap) < 2: continue
			var color := Color(0.15, 0.6, 0.9, 0.24) if cost <= int(u.mob) else Color(0.95, 0.66, 0.17, 0.20)
			var box := _box(range_highlights, Vector3(p.x, Shot.elevation(mission, p) * 0.7 + 0.09, p.y), Vector3(0.8, 0.04, 0.8), color)
			box.material_override = _mat(color, true)
	if hovered.x >= 0:
		var box := _box(hover_highlights, Vector3(hovered.x, Shot.elevation(mission, hovered) * 0.7 + 0.14, hovered.y), Vector3(0.95, 0.05, 0.95), Color("ffffff"))
		box.material_override = _mat(Color(1, 1, 1, 0.45), true)
		if action == "move":
			var route: Dictionary = mission.paths(u, int(u.mob) * 2)
			if route.costs.has(hovered):
				var cursor := hovered
				while route.prev.has(cursor):
					var here := Vector3(cursor.x, Shot.elevation(mission, cursor) * 0.7 + 0.18, cursor.y)
					var dot := _box(hover_highlights, here, Vector3(0.21, 0.06, 0.21), Color("70dfff"))
					dot.material_override = _mat(Color("70dfff"))
					var next: Vector2i = route.prev[cursor]
					var next_at := Vector3(next.x, Shot.elevation(mission, next) * 0.7 + 0.18, next.y)
					var line := _box(hover_highlights, (here + next_at) * 0.5, Vector3(0.08, 0.04, here.distance_to(next_at)), Color("70dfff"))
					line.look_at(next_at, Vector3.UP)
					cursor = next
				path_label.text = "%d AP  •  %d tiles" % [1 if int(route.costs[hovered]) <= int(u.mob) else 2, int(route.costs[hovered])]
			else: path_label.text = ""
		else: path_label.text = ""
		var shields := "  •  COVER "
		for entry in [["N", Vector2i.UP], ["E", Vector2i.RIGHT], ["S", Vector2i.DOWN], ["W", Vector2i.LEFT]]:
			var value := Shot.cover(mission, hovered, hovered + entry[1] * 2)
			shields += "%s%s " % [entry[0], "⬟" if value == 40 else "◐" if value == 20 else "○"]
		path_label.text += shields

func _label(text_value: String, size: int = 18) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("edf3f4"))
	return label

func _button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(78, 52)
	button.add_theme_color_override("font_color", Color("dceaf1"))
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(callback)
	return button

func _style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.075, 0.105, 0.91)
	style.border_color = Color(0.21, 0.48, 0.58, 0.8)
	style.set_border_width_all(1)
	style.set_content_margin_all(9)
	panel.add_theme_stylebox_override("panel", style)

func _build_ui() -> void:
	hud = CanvasLayer.new(); add_child(hud)
	var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud.add_child(root)
	overlay = root
	fx.setup(camera, root)
	var top := PanelContainer.new(); top.anchor_right = 1.0; top.offset_bottom = 64; root.add_child(top); _style_panel(top)
	var top_row := HBoxContainer.new(); top.add_child(top_row)
	title_label = _label("TEMPLE WATCH  /  RESCUE", 22); title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_row.add_child(title_label)
	objective_label = _label("", 18); top_row.add_child(objective_label)
	var left := PanelContainer.new(); left.offset_top = 75; left.offset_left = 10; left.offset_right = 205; left.offset_bottom = 560; root.add_child(left); _style_panel(left)
	var left_box := VBoxContainer.new(); left.add_child(left_box)
	left_box.add_child(_label("SQUAD", 17))
	for u in mission.living("player"):
		var id: int = int(u.id)
		left_box.add_child(_button(str(u.name), func() -> void: _select(id)))
	portrait_viewport = SubViewport.new(); portrait_viewport.size = Vector2i(132, 100); portrait_viewport.transparent_bg = true; portrait_viewport.own_world_3d = true; portrait_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; add_child(portrait_viewport)
	var portrait_camera := Camera3D.new(); portrait_camera.position = Vector3(0, 1.7, 3.0); portrait_camera.fov = 30; portrait_viewport.add_child(portrait_camera); portrait_camera.look_at(Vector3(0, 1.0, 0)); portrait_camera.current = true
	var portrait_light := DirectionalLight3D.new(); portrait_light.rotation_degrees = Vector3(-30, -35, 0); portrait_light.light_energy = 2.0; portrait_viewport.add_child(portrait_light)
	var portrait := TextureRect.new(); portrait.texture = portrait_viewport.get_texture(); portrait.custom_minimum_size = Vector2(140, 85); portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; left_box.add_child(portrait)
	selected_label = _label("", 16); left_box.add_child(selected_label)
	var right := PanelContainer.new(); right.anchor_left = 1.0; right.anchor_right = 1.0; right.offset_left = -265; right.offset_right = -10; right.offset_top = 75; right.offset_bottom = 475; root.add_child(right); _style_panel(right)
	var right_box := VBoxContainer.new(); right.add_child(right_box)
	right_box.add_child(_label("TARGETING", 17))
	hit_big_label = _label("--%", 31); hit_big_label.add_theme_color_override("font_color", Color("e9ca83")); right_box.add_child(hit_big_label)
	shot_label = _label("Hover over a target", 15); shot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; right_box.add_child(shot_label)
	right_box.add_child(_label("COMBAT LOG", 17))
	log_label = _label("", 14); log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; right_box.add_child(log_label)
	var bottom := PanelContainer.new(); bottom.anchor_top = 1.0; bottom.anchor_right = 1.0; bottom.anchor_bottom = 1.0; bottom.offset_top = -145; root.add_child(bottom); _style_panel(bottom)
	var bottom_box := VBoxContainer.new(); bottom.add_child(bottom_box)
	var info_row := HBoxContainer.new(); bottom_box.add_child(info_row)
	path_label = _label("", 15); path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; info_row.add_child(path_label)
	info_row.add_child(_label("LMB ORDER  •  RMB PAN  •  MMB ORBIT  •  WHEEL ZOOM", 12))
	var row := HBoxContainer.new(); bottom_box.add_child(row)
	var keys := {"move": "1", "shoot": "2", "strike": "3", "push": "4", "free": "5", "overwatch": "6"}
	var icons := {"move": "➜", "shoot": "◎", "strike": "✦", "push": "◈", "free": "◇", "overwatch": "◉"}
	for mode in keys:
		var b := _button("%s %s\n%s" % [keys[mode], icons[mode], mode.to_upper()], func() -> void: _choose_action(mode))
		row.add_child(b); action_buttons[mode] = b
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(spacer)
	var cine_button := _button("ACTION CAM\nON", func() -> void: action_camera = not action_camera; _refresh())
	cine_button.name = "CineButton"; row.add_child(cine_button)
	var mute_button := _button("SOUND", func() -> void: sound.muted = not sound.muted)
	row.add_child(mute_button)
	audio_slider = HSlider.new(); audio_slider.custom_minimum_size = Vector2(75, 0); audio_slider.max_value = 100; audio_slider.value = 55; audio_slider.value_changed.connect(func(value: float) -> void: sound.volume = value / 100.0); row.add_child(audio_slider)
	row.add_child(_button("END TURN\nENTER", _end_turn))
	row.add_child(_button("RESTART\nR", func() -> void: get_tree().reload_current_scene()))
	phase_banner = _label("ENEMY ACTIVITY", 31); phase_banner.visible = false; phase_banner.anchor_left = 0.5; phase_banner.anchor_top = 0.18; phase_banner.position = Vector2(-150, 0); root.add_child(phase_banner)
	result_panel = PanelContainer.new(); result_panel.visible = false; result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER); result_panel.offset_left = -220; result_panel.offset_right = 220; result_panel.offset_top = -100; result_panel.offset_bottom = 100; root.add_child(result_panel)
	var result_box := VBoxContainer.new(); result_panel.add_child(result_box)
	result_label = _label("", 28); result_box.add_child(result_label)
	result_box.add_child(_button("Restart mission", func() -> void: get_tree().reload_current_scene()))

func _choose_action(mode: String) -> void:
	action = mode
	if mode == "overwatch": mission.overwatch(selected_id)
	sound.play("click")
	_refresh()

func _select(id: int) -> void:
	selected_id = id
	sound.play("click")
	var u: Dictionary = mission.unit_by_id(id)
	if not u.is_empty(): _glide_to(Vector3(int(u.x), 0, int(u.y)), 0.55)
	_refresh()

func _glide_to(point: Vector3, seconds: float) -> void:
	if camera_tween != null and camera_tween.is_running(): camera_tween.kill()
	camera_tween = create_tween()
	camera_tween.tween_property(self, "pivot", point, seconds).set_trans(Tween.TRANS_SINE)
	camera_tween.tween_callback(_update_camera)
	set_process(true)

func _process(_delta: float) -> void:
	if camera_tween != null and camera_tween.is_running(): _update_camera()

func _action_cam(actor: Node3D, target: Node3D) -> void:
	if not action_camera or actor == null or target == null: return
	_skip_cinematic()
	if camera_tween != null and camera_tween.is_running(): camera_tween.kill()
	cinematic = true
	saved_camera = camera.position
	saved_pivot = pivot
	var direction := (target.position - actor.position).normalized()
	var shoulder := actor.position - direction * 3.0 + Vector3(-direction.z, 0, direction.x) * 1.25 + Vector3.UP * 2.3
	var look := (actor.position + target.position) * 0.5 + Vector3.UP
	action_tween = create_tween().set_parallel(true)
	action_tween.tween_property(camera, "position", shoulder, 0.6).set_trans(Tween.TRANS_SINE)
	action_tween.tween_method(func(value: Vector3) -> void: camera.look_at(value, Vector3.UP), pivot, look, 0.6)
	get_tree().create_timer(1.1).timeout.connect(_skip_cinematic)

func _skip_cinematic() -> void:
	if not cinematic: return
	cinematic = false
	if action_tween != null and action_tween.is_running(): action_tween.kill()
	camera.position = saved_camera
	pivot = saved_pivot
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
		_refresh()

func _attack(target_id: int, mode: String) -> void:
	var actor: Dictionary = mission.unit_by_id(selected_id)
	var target: Dictionary = mission.unit_by_id(target_id)
	if actor.is_empty() or target.is_empty(): return
	var before_hp := int(target.hp)
	var before_armor := int(target.get("armor", 0))
	var old_target := Shot.pos(target)
	var old_log: int = mission.log_lines.size()
	var terrain_before: String = mission.tile(old_target + Vector2i(signi(int(target.x) - int(actor.x)), signi(int(target.y) - int(actor.y))))
	var success: bool = mission.push(selected_id, target_id) if mode == "push" else mission.shot(selected_id, target_id, mode)
	if not success: return
	var from := Vector3(int(actor.x), Shot.elevation(mission, Shot.pos(actor)) * 0.7 + 1.15, int(actor.y))
	var to := Vector3(old_target.x, Shot.elevation(mission, old_target) * 0.7 + 1.1, old_target.y)
	if views.has(selected_id):
		views[selected_id].face(to)
		views[selected_id].act("cast" if mode == "push" else "swing" if mode == "strike" else "shoot")
	if views.has(target_id):
		views[target_id].face(from)
		if int(target.hp) > 0 and int(target.hp) < before_hp: views[target_id].act("hit")
		if mode == "push" and Shot.pos(target) != old_target:
			views[target_id].travel([Vector3(int(target.x), Shot.elevation(mission, Shot.pos(target)) * 0.7, int(target.y))])
	_action_cam(views.get(selected_id), views.get(target_id))
	var outcome := str(mission.log_lines[old_log]) if mission.log_lines.size() > old_log else ""
	var damage := before_hp - int(target.hp)
	if mode == "push":
		fx.shockwave(from, to); sound.play("push")
	elif mode == "strike":
		fx.saber(from, to); sound.play("saber")
	else:
		fx.bolt(from, to, str(actor.side) == "enemy", damage == 0); sound.play("shot")
	var word := "MISS" if damage == 0 and mode != "push" else "CRIT %d" % damage if "crits" in outcome else "GRAZE %d" % damage if "grazes" in outcome else "-%d" % damage if damage > 0 else "PUSH"
	fx.float_text(to + Vector3.UP * 0.6, word, Color("ffca70") if "CRIT" in word else Color("a8eaff") if "GRAZE" in word else Color("ffffff"), "CRIT" in word)
	if int(target.get("armor", 0)) < before_armor: fx.float_text(to + Vector3.UP * 0.15, "ARMOR -1", Color("f0c68b"))
	if int(target.hp) <= 0: _shake(0.16); sound.play("death")
	elif "crits" in outcome: _shake(0.12)
	if mode == "push" and terrain_before != mission.tile(old_target + Vector2i(signi(int(target.x) - int(actor.x)), signi(int(target.y) - int(actor.y)))):
		_build_terrain()
		fx.cover_chunks(to)
		_shake(0.1)
	_refresh()

func _end_turn() -> void:
	phase_banner.visible = true
	sound.play("turn")
	var before: Dictionary = {}
	for u in mission.units: before[int(u.id)] = {"position": Shot.pos(u), "hp": int(u.hp), "prev": mission.paths(u, int(u.mob)).prev if str(u.side) == "enemy" and bool(u.awake) else {}}
	mission.end_turn()
	for u in mission.units:
		var id := int(u.id)
		if not before.has(id): continue
		if str(u.side) == "enemy" and before[id].position != Shot.pos(u) and views.has(id):
			var cursor: Vector2i = Shot.pos(u)
			var route: Array[Vector3] = []
			while before[id].prev.has(cursor):
				route.push_front(Vector3(cursor.x, Shot.elevation(mission, cursor) * 0.7, cursor.y))
				cursor = before[id].prev[cursor]
			if route.is_empty(): route.append(Vector3(int(u.x), Shot.elevation(mission, Shot.pos(u)) * 0.7, int(u.y)))
			views[id].travel(route)
		if int(u.hp) < int(before[id].hp) and views.has(id):
			views[id].act("hit")
			fx.float_text(views[id].position + Vector3.UP * 1.7, "-%d" % (int(before[id].hp) - int(u.hp)), Color("ffad8d"))
			var shooter: Dictionary = {}
			for enemy in mission.living("enemy"):
				if bool(enemy.awake) and (shooter.is_empty() or Shot.distance(Shot.pos(enemy), Shot.pos(u)) < Shot.distance(Shot.pos(shooter), Shot.pos(u))): shooter = enemy
			if not shooter.is_empty():
				fx.bolt(Vector3(int(shooter.x), 1.1, int(shooter.y)), views[id].position + Vector3.UP, true, false)
				sound.play("shot")
				_shake(0.07)
	for enemy in mission.living("enemy"):
		if bool(enemy.awake) and before.has(int(enemy.id)) and before[int(enemy.id)].position != Shot.pos(enemy):
			_glide_to(Vector3(int(enemy.x), 0, int(enemy.y)), 0.55)
			break
	_refresh()
	get_tree().create_timer(1.2).timeout.connect(func() -> void: phase_banner.visible = false)

func _demo(kind: String) -> void:
	demo_mode = true
	var enemy: Dictionary = mission.living("enemy")[0]
	enemy.awake = true
	if kind == "push":
		enemy.x = 4; enemy.y = 19
		mission.set_tile(Vector2i(4, 18), "c")
		_build_terrain()
	else:
		enemy.x = 8; enemy.y = 19
	selected_id = int(mission.living("player")[0].id) if kind == "push" else int(mission.living("player")[2].id)
	if kind == "shot": hovered = Shot.pos(enemy)
	_refresh()
	var path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): path = arg.trim_prefix("--capture=")
	if kind == "push": _attack(int(enemy.id), "push")
	else: _attack(int(enemy.id), "shoot")
	if path != "":
		await get_tree().create_timer(0.18).timeout
		_capture(path, 1)

func _refresh() -> void:
	var u: Dictionary = mission.unit_by_id(selected_id)
	if u.is_empty() or int(u.get("hp", 0)) <= 0:
		var survivors: Array[Dictionary] = mission.living("player")
		if not survivors.is_empty():
			selected_id = int(survivors[0].id)
			u = survivors[0]
	objective_label.text = "TURN %d/%d  •  %s  •  %s" % [mission.turn, int(mission.spec.turn_limit), "ESCORT MIRA" if bool(mission.prisoner.freed) else "FREE MIRA", "EVAC" if bool(mission.prisoner.freed) else "CELL"]
	selected_label.text = "%s\n%s\nHP %s\nAP %s\nFOCUS %d" % [u.get("name", ""), u.get("class_name", ""), "●".repeat(int(u.get("hp", 0))) + "○".repeat(maxi(0, int(u.get("max_hp", 0)) - int(u.get("hp", 0)))), "◆".repeat(int(u.get("ap", 0))) + "◇".repeat(maxi(0, 3 - int(u.get("ap", 0)))), int(u.get("focus_left", 0))]
	var kind := str(u.get("model", ""))
	if kind != portrait_kind and model_cache.has(kind):
		if portrait_model != null: portrait_model.queue_free()
		portrait_model = model_cache[kind].instantiate()
		portrait_model.rotation.y = PI
		portrait_viewport.add_child(portrait_model)
		portrait_kind = kind
	log_label.text = "\n".join(mission.log_lines.slice(max(0, mission.log_lines.size() - 8)))
	for mode in action_buttons:
		action_buttons[mode].disabled = mission.result != "" or (mode == "free" and bool(mission.prisoner.freed)) or (mode in ["strike", "push"] and str(u.get("class_name", "")) not in ["Guardian", "Consular"])
	result_panel.visible = mission.result != ""
	var cine_button: Button = overlay.find_child("CineButton", true, false)
	if cine_button != null: cine_button.text = "ACTION CAM\n%s" % ("ON" if action_camera else "OFF")
	if mission.result != "": result_label.text = "MISSION COMPLETE" if mission.result == "win" else "MISSION FAILED"
	_refresh_figures(); _refresh_highlights(true); _show_shot()

func _show_shot() -> void:
	var actor: Dictionary = mission.unit_by_id(selected_id)
	var target: Dictionary = {}
	for u in mission.living("enemy"):
		if Shot.pos(u) == hovered and bool(u.awake): target = u; break
	if actor.is_empty() or target.is_empty():
		hit_big_label.text = "--%"
		shot_label.text = "Hover over a spotted enemy.\nBlue = 1 AP move\nAmber = 2 AP dash"
		return
	var info: Dictionary = Shot.calculate(mission, actor, target, action == "strike")
	hit_big_label.text = "%d%% HIT" % int(info.hit)
	var breakdown := ""
	for item in info.lines: breakdown += "%s  %+d\n" % [item[0], int(item[1])]
	shot_label.text = "%s  HP %d\nCRIT %d%%  •  GRAZE %d%%\nCOVER %s\n%s\n%s\n%s" % [target.name, int(target.hp), int(info.crit), int(info.graze), "⬟ FULL" if int(info.cover) == 40 else "◐ HALF" if int(info.cover) == 20 else "○ NONE", breakdown, "LOS CLEAR" if bool(info.los) else "LOS BLOCKED", "IN RANGE" if bool(info.range_ok) else "OUT OF RANGE"]

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
		if cinematic and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: _skip_cinematic(); return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom -= 2; _update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom += 2; _update_camera()
		elif event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]: drag_button = event.button_index if event.pressed else 0
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var p := _screen_tile(event.position)
			if p.x < 0: return
			for u in mission.living("player"):
				if Shot.pos(u) == p: _select(int(u.id)); return
			var target_id := -1
			for u in mission.living("enemy"):
				if Shot.pos(u) == p and bool(u.awake): target_id = int(u.id)
			if action == "move": _move_selected(p)
			elif action == "free": mission.free_prisoner(selected_id)
			elif target_id >= 0 and action in ["push", "shoot", "strike"]: _attack(target_id, action)
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
		if event.keycode == KEY_SPACE and cinematic: _skip_cinematic()
		elif event.keycode == KEY_ENTER: _end_turn()
		elif event.keycode == KEY_R: get_tree().reload_current_scene()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
			_choose_action(["move", "shoot", "strike", "push", "free", "overwatch"][event.keycode - KEY_1])
