extends RefCounted

const Shot = preload("res://scripts/shot.gd")
const InputControls = preload("res://scripts/input_controls.gd")
var g

func _border(parent: Node3D, p: Vector2i, color: Color, height: float = 0.12) -> void:
	var at := Vector3(p.x, Shot.elevation(g.mission, p) * 0.7 + height, p.y)
	for side in [Vector3(-0.43, 0, 0), Vector3(0.43, 0, 0), Vector3(0, 0, -0.43), Vector3(0, 0, 0.43)]:
		var size := Vector3(0.08, 0.05, 0.86) if side.x != 0 else Vector3(0.86, 0.05, 0.08)
		g._box(parent, at + side, size, color)

func _refresh_highlights(force: bool = false) -> void:
	g._clear(g.hover_highlights)
	if force: g._clear(g.range_highlights)
	if g.path_label != null: g.path_label.text = ""
	var u: Dictionary = g.mission.unit_by_id(g.selected_id)
	if u.is_empty() or g.mission.result != "" or g.mission.phase != "player": return
	if g.target_id >= 0:
		var target: Dictionary = g.mission.unit_by_id(g.target_id)
		if not target.is_empty(): _border(g.hover_highlights, Shot.pos(target), Color("ff746b"), 0.23)
	if force and g.action == "move" and int(u.ap) > 0:
		var reach: Dictionary = g.mission.paths(u, int(u.mob) * 2)
		for p in reach.costs:
			if p == Shot.pos(u): continue
			var cost: int = int(reach.costs[p])
			if cost > int(u.mob) and int(u.ap) < 2: continue
			_border(g.range_highlights, p, Color("399ef2") if cost <= int(u.mob) else Color("f2ba47"))
	if g.preview_tile.x >= 0 and g.mission.in_bounds(g.preview_tile):
		_border(g.hover_highlights, g.preview_tile, Color("f8f3c5"), 0.21)
	var shown: Vector2i = g.hovered if g.hovered.x >= 0 else g.preview_tile
	if shown.x >= 0 and g.mission.in_bounds(shown):
		_border(g.hover_highlights, shown, Color("ffffff"), 0.18)
		if g.action == "move":
			var preview: Dictionary = InputControls.move_preview(g.mission, u, shown)
			if not preview.is_empty():
				var cursor := shown
				while preview.prev.has(cursor):
					var here := Vector3(cursor.x, Shot.elevation(g.mission, cursor) * 0.7 + 0.18, cursor.y)
					var dot: MeshInstance3D = g._box(g.hover_highlights, here, Vector3(0.21, 0.06, 0.21), Color("70dfff"))
					dot.material_override = g._mat(Color("70dfff"))
					var next: Vector2i = preview.prev[cursor]
					var next_at := Vector3(next.x, Shot.elevation(g.mission, next) * 0.7 + 0.18, next.y)
					var line: MeshInstance3D = g._box(g.hover_highlights, (here + next_at) * 0.5, Vector3(0.08, 0.04, here.distance_to(next_at)), Color("70dfff"))
					line.look_at(next_at, Vector3.UP)
					cursor = next
				g.path_label.text = "%d AP  •  %d tiles" % [int(preview.ap), int(preview.tiles)]
			else: g.path_label.text = ""
		else: g.path_label.text = ""
		var shields := "  •  COVER "
		for entry in [["N", Vector2i.UP], ["E", Vector2i.RIGHT], ["S", Vector2i.DOWN], ["W", Vector2i.LEFT]]:
			var value := Shot.cover(g.mission, shown, shown + entry[1] * 2)
			shields += "%s%s " % [entry[0], "⬟" if value == 40 else "◐" if value == 20 else "○"]
		g.path_label.text += shields


func _label(text_value: String, size: int = 18) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("edf3f4"))
	return label


func _button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
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
	g.hud = CanvasLayer.new(); g.add_child(g.hud)
	var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; g.hud.add_child(root)
	g.overlay = root
	g.fx.setup(g.camera, root)
	var top := PanelContainer.new(); top.anchor_right = 1.0; top.offset_bottom = 64; root.add_child(top); _style_panel(top)
	var top_row := HBoxContainer.new(); top.add_child(top_row)
	g.title_label = _label("TEMPLE WATCH  /  RESCUE", 22); g.title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_row.add_child(g.title_label)
	g.objective_label = _label("", 18); top_row.add_child(g.objective_label)
	var left := PanelContainer.new(); left.offset_top = 75; left.offset_left = 10; left.offset_right = 205; left.offset_bottom = 560; root.add_child(left); _style_panel(left)
	var left_box := VBoxContainer.new(); left.add_child(left_box)
	left_box.add_child(_label("SQUAD", 17))
	for u in g.mission.living("player"):
		var id: int = int(u.id)
		left_box.add_child(_button(str(u.name), func() -> void: g._select(id)))
	g.portrait_viewport = SubViewport.new(); g.portrait_viewport.size = Vector2i(132, 100); g.portrait_viewport.transparent_bg = true; g.portrait_viewport.own_world_3d = true; g.portrait_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; g.add_child(g.portrait_viewport)
	var portrait_camera := Camera3D.new(); portrait_camera.position = Vector3(0, 1.7, 3.0); portrait_camera.fov = 30; g.portrait_viewport.add_child(portrait_camera); portrait_camera.look_at(Vector3(0, 1.0, 0)); portrait_camera.current = true
	var portrait_light := DirectionalLight3D.new(); portrait_light.rotation_degrees = Vector3(-30, -35, 0); portrait_light.light_energy = 2.0; g.portrait_viewport.add_child(portrait_light)
	var portrait := TextureRect.new(); portrait.texture = g.portrait_viewport.get_texture(); portrait.custom_minimum_size = Vector2(140, 85); portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; left_box.add_child(portrait)
	g.selected_label = _label("", 16); left_box.add_child(g.selected_label)
	var right := PanelContainer.new(); right.anchor_left = 1.0; right.anchor_right = 1.0; right.offset_left = -265; right.offset_right = -10; right.offset_top = 75; right.offset_bottom = 475; root.add_child(right); _style_panel(right)
	var right_box := VBoxContainer.new(); right.add_child(right_box)
	right_box.add_child(_label("TARGETING", 17))
	g.hit_big_label = _label("--%", 31); g.hit_big_label.add_theme_color_override("font_color", Color("e9ca83")); right_box.add_child(g.hit_big_label)
	g.shot_label = _label("Hover over a target", 15); g.shot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; right_box.add_child(g.shot_label)
	right_box.add_child(_label("COMBAT LOG", 17))
	g.log_label = _label("", 14); g.log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; right_box.add_child(g.log_label)
	var bottom := PanelContainer.new(); bottom.anchor_top = 1.0; bottom.anchor_right = 1.0; bottom.anchor_bottom = 1.0; bottom.offset_top = -145; root.add_child(bottom); _style_panel(bottom)
	var bottom_box := VBoxContainer.new(); bottom.add_child(bottom_box)
	var info_row := HBoxContainer.new(); bottom_box.add_child(info_row)
	g.path_label = _label("", 15); g.path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; info_row.add_child(g.path_label)
	info_row.add_child(_label("LMB PREVIEW/CONFIRM  •  RMB CANCEL/PAN  •  TAB CYCLE  •  Q/E ROTATE  •  WASD PAN  •  SPACE SKIP", 12))
	g.warning_label = _label("", 15); g.warning_label.add_theme_color_override("font_color", Color("ffd37a")); bottom_box.add_child(g.warning_label)
	var row := HBoxContainer.new(); bottom_box.add_child(row)
	var keys := {"move": "1", "shoot": "2", "strike": "3", "push": "4", "free": "5", "overwatch": "6"}
	var icons := {"move": "➜", "shoot": "◎", "strike": "✦", "push": "◈", "free": "◇", "overwatch": "◉"}
	for mode in keys:
		var b := _button("%s %s\n%s" % [keys[mode], icons[mode], mode.to_upper()], func() -> void: g._choose_action(mode))
		row.add_child(b); g.action_buttons[mode] = b
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(spacer)
	var cine_button := _button("ACTION CAM\nON", func() -> void: g.action_camera = not g.action_camera; _refresh())
	cine_button.name = "CineButton"; row.add_child(cine_button)
	var mute_button := _button("SOUND", func() -> void: g.sound.muted = not g.sound.muted)
	row.add_child(mute_button)
	g.audio_slider = HSlider.new(); g.audio_slider.custom_minimum_size = Vector2(75, 0); g.audio_slider.max_value = 100; g.audio_slider.value = 55; g.audio_slider.value_changed.connect(func(value: float) -> void: g.sound.volume = value / 100.0); row.add_child(g.audio_slider)
	row.add_child(_button("END TURN\nENTER", g._request_end_turn))
	row.add_child(_button("RESTART\nR", func() -> void: g.get_tree().reload_current_scene()))
	g.phase_banner = _label("ENEMY ACTIVITY", 31); g.phase_banner.visible = false; g.phase_banner.anchor_left = 0.5; g.phase_banner.anchor_top = 0.18; g.phase_banner.position = Vector2(-150, 0); root.add_child(g.phase_banner)
	g.result_panel = PanelContainer.new(); g.result_panel.visible = false; g.result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER); g.result_panel.offset_left = -220; g.result_panel.offset_right = 220; g.result_panel.offset_top = -100; g.result_panel.offset_bottom = 100; root.add_child(g.result_panel)
	var result_box := VBoxContainer.new(); g.result_panel.add_child(result_box)
	g.result_label = _label("", 28); result_box.add_child(g.result_label)
	result_box.add_child(_button("Restart mission", func() -> void: g.get_tree().reload_current_scene()))


func _refresh() -> void:
	var u: Dictionary = g.mission.unit_by_id(g.selected_id)
	if u.is_empty() or int(u.get("hp", 0)) <= 0:
		var survivors: Array[Dictionary] = g.mission.living("player")
		if not survivors.is_empty():
			g.selected_id = int(survivors[0].id)
			u = survivors[0]
	g.objective_label.text = "TURN %d/%d  •  %s  •  %s" % [g.mission.turn, int(g.mission.spec.turn_limit), "ESCORT MIRA" if bool(g.mission.prisoner.freed) else "FREE MIRA", "EVAC" if bool(g.mission.prisoner.freed) else "CELL"]
	g.selected_label.text = "%s\n%s\nHP %s\nAP %s\nFOCUS %d" % [u.get("name", ""), u.get("class_name", ""), "●".repeat(int(u.get("hp", 0))) + "○".repeat(maxi(0, int(u.get("max_hp", 0)) - int(u.get("hp", 0)))), "◆".repeat(int(u.get("ap", 0))) + "◇".repeat(maxi(0, 3 - int(u.get("ap", 0)))), int(u.get("focus_left", 0))]
	var kind := str(u.get("model", ""))
	if kind != g.portrait_kind and g.model_cache.has(kind):
		if g.portrait_model != null: g.portrait_model.queue_free()
		g.portrait_model = g.model_cache[kind].instantiate()
		g.portrait_model.rotation.y = PI
		g.portrait_viewport.add_child(g.portrait_model)
		g.portrait_kind = kind
	g.log_label.text = "\n".join(g.mission.log_lines.slice(max(0, g.mission.log_lines.size() - 8)))
	for mode in g.action_buttons:
		var needed_ap: int = 1 if mode == "overwatch" else int(g.mission.abilities[mode].ap)
		g.action_buttons[mode].disabled = g.mission.result != "" or int(u.get("ap", 0)) < needed_ap or (mode == "free" and bool(g.mission.prisoner.freed)) or (mode in ["strike", "push"] and str(u.get("class_name", "")) not in ["Guardian", "Consular"]) or (mode == "push" and int(u.get("focus_left", 0)) < int(g.mission.abilities.push.focus))
	g.result_panel.visible = g.mission.result != ""
	var cine_button: Button = g.overlay.find_child("CineButton", true, false)
	if cine_button != null: cine_button.text = "ACTION CAM\n%s" % ("ON" if g.action_camera else "OFF")
	if g.mission.result != "": g.result_label.text = "MISSION COMPLETE" if g.mission.result == "win" else "MISSION FAILED"
	g._refresh_figures(); _refresh_highlights(true); _show_shot()


func _show_shot() -> void:
	var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
	var target: Dictionary = {}
	for u in g.mission.living("enemy"):
		if (int(u.id) == g.target_id or (g.target_id < 0 and Shot.pos(u) == g.hovered)) and bool(u.awake): target = u; break
	if actor.is_empty() or target.is_empty():
		g.hit_big_label.text = "--%"
		g.shot_label.text = "Choose Shoot, Strike or Push.\nTab cycles valid targets.\nEnter confirms; Esc cancels."
		return
	if g.action == "push":
		g.hit_big_label.text = "PUSH"
		g.shot_label.text = "%s  HP %d\nForce Push: guaranteed if in range and line of sight.\nNo hit or crit roll.\nCosts %d AP and %d Focus." % [target.name, int(target.hp), int(g.mission.abilities.push.ap), int(g.mission.abilities.push.focus)]
		return
	var info: Dictionary = Shot.calculate(g.mission, actor, target, g.action == "strike")
	g.hit_big_label.text = "%d%% HIT" % int(info.hit)
	var breakdown := ""
	for item in info.lines: breakdown += "%s  %+d\n" % [item[0], int(item[1])]
	g.shot_label.text = "%s  HP %d\nCRIT %d%%  •  GRAZE %d%%\nCOVER %s\n%s\n%s\n%s" % [target.name, int(target.hp), int(info.crit), int(info.graze), "⬟ FULL" if int(info.cover) == 40 else "◐ HALF" if int(info.cover) == 20 else "○ NONE", breakdown, "LOS CLEAR" if bool(info.los) else "LOS BLOCKED", "IN RANGE" if bool(info.range_ok) else "OUT OF RANGE"]

