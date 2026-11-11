extends RefCounted

const Shot = preload("res://scripts/shot.gd")
const InputControls = preload("res://scripts/input_controls.gd")
const Ability = preload("res://scripts/abilities_engine.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Rules12 = preload("res://scripts/rules12_actions.gd")
const Threat22 = preload("res://scripts/decision22_threat.gd")
var g
var techniques: HFlowContainer
var techniques_open := false
var targeting = preload("res://scripts/combat_targeting.gd").new()
var night
var phone
var bar
var left_panel: PanelContainer
var right_panel: PanelContainer
var desktop_bottom: PanelContainer
var desktop_threat_chip: Label
var aim_ui
var combo_overlay: Control
var move_decision: Dictionary = {}
var move_destination := Vector2i(-1, -1)

static func ap_pips(unit: Dictionary) -> String:
	var maximum: int = int(unit.get("max_ap", Rules12.ACTIONS_PER_TURN))
	var available: int = clampi(int(unit.get("ap", 0)), 0, maximum)
	return "%d/%d" % [available,maximum]

static func move_color(ap_cost: int) -> Color:
	return Color("60b9ff") if ap_cost == 1 else Color("ffd16a")

static func move_fill(ap_cost: int) -> Color:
	var color := Color("0875df") if ap_cost == 1 else Color("e6a000")
	color.a = 0.24
	return color

func _range_edge(parent: Node3D, p: Vector2i, ap_cost: int, blue: Dictionary, all: Dictionary) -> void:
	var at := Vector3(p.x, Shot.elevation(g.mission, p) * 0.7 + 0.13, p.y)
	for entry in [[Vector2i.LEFT, Vector3(-0.43, 0, 0)], [Vector2i.RIGHT, Vector3(0.43, 0, 0)], [Vector2i.UP, Vector3(0, 0, -0.43)], [Vector2i.DOWN, Vector3(0, 0, 0.43)]]:
		var next: Vector2i = p + entry[0]
		if all.costs.has(next) and (blue.costs.has(next) == (ap_cost == 1)): continue
		var size := Vector3(0.10, 0.05, 0.86) if entry[0].x != 0 else Vector3(0.86, 0.05, 0.10)
		g._box(parent, at + entry[1], size, move_color(ap_cost))

func _route_end(parent: Node3D, p: Vector2i, color: Color, previous: Vector2i) -> void:
	var at := Vector3(p.x, Shot.elevation(g.mission, p) * 0.7 + 0.23, p.y)
	for offset in [Vector3(-0.32, 0, -0.32), Vector3(0.32, 0, -0.32), Vector3(-0.32, 0, 0.32), Vector3(0.32, 0, 0.32)]:
		g._box(parent, at + offset, Vector3(0.16, 0.05, 0.16), color)
	var marker: MeshInstance3D = g._box(parent, at, Vector3(0.34, 0.06, 0.34), color)
	marker.rotation.y = PI / 4.0
	var direction := Vector3(p.x - previous.x, 0, p.y - previous.y).normalized()
	if direction.length_squared() < 0.1: return
	var tip := at + direction * 0.39
	var side := Vector3(-direction.z, 0, direction.x)
	for wing in [tip - direction * 0.30 + side * 0.19, tip - direction * 0.30 - side * 0.19]:
		var arrow: MeshInstance3D = g._box(parent, (tip + wing) * 0.5, Vector3(0.11, 0.05, tip.distance_to(wing)), color)
		arrow.look_at(wing, Vector3.UP)

func _border(parent: Node3D, p: Vector2i, color: Color, height: float = 0.12) -> void:
	var at := Vector3(p.x, Shot.elevation(g.mission, p) * 0.7 + height, p.y)
	for side in [Vector3(-0.43, 0, 0), Vector3(0.43, 0, 0), Vector3(0, 0, -0.43), Vector3(0, 0, 0.43)]:
		var size := Vector3(0.08, 0.05, 0.86) if side.x != 0 else Vector3(0.86, 0.05, 0.08)
		g._box(parent, at + side, size, color)

func _refresh_highlights(force: bool = false) -> void:
	g._clear(g.hover_highlights)
	move_decision = {}; move_destination = Vector2i(-1, -1)
	targeting.g = g
	if force: targeting.detection()
	if force: g._clear(g.range_highlights)
	if g.path_label != null:
		g.path_label.text = ""
		g.path_label.add_theme_color_override("font_color", Color("edf3f4"))
	var u: Dictionary = g.mission.unit_by_id(g.selected_id)
	if u.is_empty() or g.mission.result != "" or g.mission.phase != "player": return
	if g.target_id >= 0:
		var target: Dictionary = g.mission.unit_by_id(g.target_id)
		if not target.is_empty(): _border(g.hover_highlights, Shot.pos(target), Color("71ed9a") if str(target.side) == "player" else Color("ff746b"), 0.23)
	if force and g.action == "move" and int(u.ap) > 0:
		var blue: Dictionary = g.mission.reach_tiles(u, 1)
		var yellow: Dictionary = g.mission.reach_tiles(u, 2) if int(u.ap) >= 2 else blue
		for p in yellow.costs:
			if p == Shot.pos(u): continue
			var ap_cost := 1 if blue.costs.has(p) else 2
			var color := move_fill(ap_cost)
			var tile: MeshInstance3D = g._box(g.range_highlights, Vector3(p.x, Shot.elevation(g.mission, p) * 0.7 + 0.10, p.y), Vector3(0.79, 0.025, 0.79), color)
			var fill_material: StandardMaterial3D = g._mat(color, true)
			fill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			tile.material_override = fill_material
			_range_edge(g.range_highlights, p, ap_cost, blue, yellow)
	elif force and g.action not in ["move", "free", "overwatch", "hunker"] and g.mission.abilities.has(g.action):
		var target_kind := str(g.mission.abilities[g.action].target)
		if target_kind.begins_with("tile"):
			for p in Ability.tiles(g.mission, u, g.action): _border(g.range_highlights, p, Color("7bc7ff"))
		elif target_kind.begins_with("ally") or target_kind.begins_with("enemy"):
			for t in InputControls.valid_targets(g.mission, u, g.action): _border(g.range_highlights, Shot.pos(t), Color("62d992") if str(t.side) == "player" else Color("f3a570"))
	if g.preview_tile.x >= 0 and g.mission.in_bounds(g.preview_tile):
		_border(g.hover_highlights, g.preview_tile, Color("f8f3c5"), 0.21)
	var shown: Vector2i = g.hovered if g.hovered.x >= 0 else g.preview_tile
	if shown.x >= 0 and g.mission.in_bounds(shown):
		_border(g.hover_highlights, shown, Color("ffffff"), 0.18)
		if g.action == "move":
			var preview: Dictionary = InputControls.move_preview(g.mission, u, shown)
			if not preview.is_empty():
				move_decision = preview; move_destination = shown
				var cursor := shown
				var route_color := move_color(int(preview.ap))
				_route_end(g.hover_highlights, shown, route_color, preview.prev.get(shown, Shot.pos(u)))
				while preview.prev.has(cursor):
					var here := Vector3(cursor.x, Shot.elevation(g.mission, cursor) * 0.7 + 0.20, cursor.y)
					var next: Vector2i = preview.prev[cursor]
					var next_at := Vector3(next.x, Shot.elevation(g.mission, next) * 0.7 + 0.20, next.y)
					var line: MeshInstance3D = g._box(g.hover_highlights, (here + next_at) * 0.5, Vector3(0.15, 0.06, here.distance_to(next_at) * 0.88), route_color)
					line.look_at(next_at, Vector3.UP)
					cursor = next
				var cost_label := "1 action · 1 action remains" if int(preview.ap) == 1 and int(u.ap) == 2 else "1 action" if int(preview.ap) == 1 else "DASH: ends turn"
				var risk := "  ·  FLANKED: %s" % ", ".join(preview.flanks) if not preview.flanks.is_empty() else "  ·  SEEN: %s" % ", ".join(preview.seen_by) if not preview.seen_by.is_empty() else "  ·  NO KNOWN LOS"
				g.path_label.text = "%s  ·  %d tiles%s" % [cost_label, int(preview.tiles), risk]
				g.path_label.add_theme_color_override("font_color", Color("ff746b") if not preview.flanks.is_empty() else Color("ffd16a") if not preview.seen_by.is_empty() else Color("91d6fa"))
			else: g.path_label.text = ""
		else: g.path_label.text = ""
		var shields := "  •  COVER "
		for entry in [["N", Vector2i.UP], ["E", Vector2i.RIGHT], ["S", Vector2i.DOWN], ["W", Vector2i.LEFT]]:
			var value := Shot.cover(g.mission, shown, shown + entry[1] * 2)
			shields += "%s%s " % [entry[0], "⬟" if value == 40 else "◐" if value == 20 else "○"]
			if g.action == "move" and value > 0: _shield(g.hover_highlights, shown, entry[1], value == 40)
		g.path_label.text += shields
	if phone != null and g.warning_label.text == "" and g.action == "move":
		var path_text: String = g.path_label.text.get_slice("  •  COVER", 0)
		phone.action_name.text = path_text if path_text != "" else "Blue: 1 action  ·  Amber: DASH ends turn"

func _shield(parent: Node3D, tile: Vector2i, direction: Vector2i, full: bool) -> void:
	var phone_scale := 1.65 if phone != null else 1.0
	var center := Vector3(tile.x + direction.x * 0.36, Shot.elevation(g.mission, tile) * 0.7 + 1.65, tile.y + direction.y * 0.36)
	var points := [Vector2(-0.19, -0.16), Vector2(0.19, -0.16), Vector2(0.15, 0.09), Vector2(0, 0.21), Vector2(-0.15, 0.09)]
	for i in range(points.size()): points[i] *= phone_scale
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new(); material.albedo_color = Color("ffe6a2") if full else Color("9fe3ff")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	if full:
		for i in range(1, 4):
			for j in [0, i, i + 1]: mesh.surface_add_vertex(center + Vector3(points[j].x, 0, points[j].y))
	else:
		for i in range(5):
			var a: Vector2 = points[i]; var b: Vector2 = points[(i + 1) % 5]
			var side := (b - a).normalized().orthogonal() * 0.018
			for v in [a + side, b + side, b - side, a + side, b - side, a - side]: mesh.surface_add_vertex(center + Vector3(v.x, 0, v.y))
	mesh.surface_end()
	var icon := MeshInstance3D.new(); icon.mesh = mesh; parent.add_child(icon)


func _label(text_value: String, size: int = 18) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", preload("res://scripts/campaign/ui.gd").font("display" if size >= 24 else "body"))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", preload("res://scripts/campaign/ui.gd").TEXT)
	return label


func _button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(72, 44)
	button.add_theme_color_override("font_color", Color("dceaf1"))
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(callback)
	return button


func _style_panel(panel: PanelContainer) -> void:
	var style: StyleBoxFlat = preload("res://scripts/campaign/ui.gd").style(preload("res://scripts/campaign/ui.gd").SURFACE, preload("res://scripts/campaign/ui.gd").BORDER)
	style.set_content_margin_all(9)
	panel.add_theme_stylebox_override("panel", style)


func _build_ui() -> void:
	g.hud = CanvasLayer.new(); g.add_child(g.hud)
	var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; g.hud.add_child(root)
	g.overlay = root
	# --- wave10 story ---
	var bond_lines := preload("res://scripts/campaign/bond_overlay.gd").new()
	bond_lines.name = "BondLines"; bond_lines.game = g
	bond_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bond_lines)
	g.fx.setup(g.camera, root)
	var top := PanelContainer.new(); top.anchor_right = 1.0; top.offset_bottom = 48; root.add_child(top); _style_panel(top)
	var top_row := HBoxContainer.new(); top.add_child(top_row)
	g.title_label = _label("TEMPLE WATCH", 20); g.title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_row.add_child(g.title_label)
	g.objective_label = _label("", 15); g.objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; g.objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top_row.add_child(g.objective_label)
	var left := PanelContainer.new(); left.offset_top = 58; left.offset_left = 10; left.offset_right = 194; left.offset_bottom = 440; root.add_child(left); _style_panel(left)
	left_panel = left
	var left_box := VBoxContainer.new(); left.add_child(left_box)
	left_box.add_child(_label("SQUAD", 17))
	for u in g.mission.living("player"):
		var id: int = int(u.id)
		var squad_button := _button(str(u.name), func() -> void: g._select(id))
		squad_button.custom_minimum_size.y = 38; left_box.add_child(squad_button)
	g.portrait_viewport = SubViewport.new(); g.portrait_viewport.size = Vector2i(132, 100); g.portrait_viewport.transparent_bg = true; g.portrait_viewport.own_world_3d = true; g.portrait_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; g.add_child(g.portrait_viewport)
	var portrait_camera := Camera3D.new(); portrait_camera.position = Vector3(0.12, 1.6, 1.15); portrait_camera.fov = 30; g.portrait_viewport.add_child(portrait_camera); portrait_camera.look_at(Vector3(0, 1.45, 0)); portrait_camera.current = true
	var portrait_light := DirectionalLight3D.new(); portrait_light.rotation_degrees = Vector3(-30, -35, 0); portrait_light.light_energy = 2.0; g.portrait_viewport.add_child(portrait_light)
	var portrait := TextureRect.new(); portrait.texture = g.portrait_viewport.get_texture(); portrait.custom_minimum_size = Vector2(140, 44); portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; left_box.add_child(portrait)
	g.selected_label = _label("", 14); left_box.add_child(g.selected_label)
	var right := PanelContainer.new(); right.anchor_left = 1.0; right.anchor_right = 1.0; right.offset_left = -258; right.offset_right = -10; right.offset_top = 58; right.offset_bottom = 318; root.add_child(right); _style_panel(right)
	right_panel = right
	var right_box := VBoxContainer.new(); right.add_child(right_box)
	right_box.add_child(_label("TARGETING", 17))
	g.hit_big_label = _label("--%", 31); g.hit_big_label.add_theme_color_override("font_color", Color("e9ca83")); right_box.add_child(g.hit_big_label)
	g.shot_label = _label("Hover over a target", 14); g.shot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; right_box.add_child(g.shot_label)
	var log_title := _label("COMBAT LOG", 17); log_title.visible = false; right_box.add_child(log_title)
	g.log_label = _label("", 14); g.log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; g.log_label.visible = false; right_box.add_child(g.log_label)
	var bottom := PanelContainer.new(); bottom.anchor_left = 0.5; bottom.anchor_right = 0.5
	desktop_bottom = bottom
	bottom.anchor_top = 1.0; bottom.anchor_bottom = 1.0
	bottom.offset_left = -350; bottom.offset_right = 350; bottom.offset_top = -124
	root.add_child(bottom); _style_panel(bottom)
	var bottom_box := VBoxContainer.new(); bottom.add_child(bottom_box)
	var info_row := HBoxContainer.new(); bottom_box.add_child(info_row)
	info_row.visible = false
	g.path_label = _label("", 15); g.path_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; info_row.add_child(g.path_label)
	info_row.add_child(_label("LMB PREVIEW/CONFIRM  •  RMB CANCEL/PAN  •  TAB / Q-E TARGET  •  WASD PAN  •  SPACE SKIP", 12))
	g.warning_label = _label("", 15); g.warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; g.warning_label.add_theme_color_override("font_color", Color("ffd37a")); bottom_box.add_child(g.warning_label)
	g.warning_label.visible = false
	var ability_scroll := preload("res://scripts/touch_scroll.gd").new(); ability_scroll.name = "DesktopAbilities"
	ability_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ability_scroll.custom_minimum_size.y = 60; ability_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_box.add_child(ability_scroll)
	var row := HFlowContainer.new(); row.size_flags_horizontal = Control.SIZE_EXPAND_FILL; ability_scroll.add_child(row)
	var keys := {"move": "1", "shoot": "2", "strike": "3", "push": "4", "free": "5", "overwatch": "6", "hunker": "7"}
	if g.mission.modern: keys.erase("free"); keys.interact = "5"
	for mode in keys:
		var b = preload("res://scripts/hud_ability_button.gd").new(); b.custom_minimum_size = Vector2(108, 58); b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void: g._choose_action(mode))
		row.add_child(b); g.action_buttons[mode] = b
	for mode in g.mission.abilities:
		if mode in keys or mode == "move": continue
		var b = preload("res://scripts/hud_ability_button.gd").new(); b.custom_minimum_size = Vector2(108, 58); b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void: g._choose_action(mode))
		row.add_child(b)
		g.action_buttons[mode] = b
	var command_row := HBoxContainer.new(); bottom_box.add_child(command_row)
	command_row.add_child(_button("INFO",func():
		g.Prefs.set_value("numbers",not bool(g.Prefs.get_value("numbers"))); _refresh()))
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; command_row.add_child(spacer)
	var cine_button := _button("Cinematics: On", func() -> void: g.action_camera = not g.action_camera; _refresh())
	cine_button.custom_minimum_size.x = 150
	cine_button.name = "CineButton"; command_row.add_child(cine_button)
	var mute_button := _button("SOUND", func() -> void: g.sound.muted = not g.sound.muted)
	command_row.add_child(mute_button)
	g.audio_slider = HSlider.new(); g.audio_slider.custom_minimum_size = Vector2(75, 0); g.audio_slider.max_value = 100; g.audio_slider.value = 55; g.audio_slider.value_changed.connect(func(value: float) -> void: g.sound.volume = value / 100.0); command_row.add_child(g.audio_slider)
	desktop_threat_chip = _label("", 14); desktop_threat_chip.name = "DesktopThreatChip"
	desktop_threat_chip.add_theme_font_override("font", preload("res://scripts/campaign/ui.gd").font("body"))
	desktop_threat_chip.custom_minimum_size.x = 104; desktop_threat_chip.visible = false
	command_row.add_child(desktop_threat_chip)
	command_row.add_child(_button("END TURN", g._request_end_turn))
	command_row.add_child(_button("RESTART", func() -> void: g.get_tree().reload_current_scene()))
	g.phase_banner = _label("ENEMY ACTIVITY", 30); g.phase_banner.visible = false; g.phase_banner.anchor_left = 0.5; g.phase_banner.anchor_right = 0.5; g.phase_banner.anchor_top = 0.18; g.phase_banner.offset_left = -370; g.phase_banner.offset_right = 370; g.phase_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; g.phase_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; root.add_child(g.phase_banner)
	g.phase_banner.modulate.a = 0.0
	g.result_panel = PanelContainer.new(); g.result_panel.visible = false; g.result_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER); g.result_panel.offset_left = -220; g.result_panel.offset_right = 220; g.result_panel.offset_top = -100; g.result_panel.offset_bottom = 100; root.add_child(g.result_panel)
	var result_box := VBoxContainer.new(); g.result_panel.add_child(result_box)
	g.result_label = _label("", 28); result_box.add_child(g.result_label)
	result_box.add_child(_button("Restart mission", func() -> void: g.get_tree().reload_current_scene()))
	result_box.add_child(_button("Main menu", func() -> void: g.get_node("/root/CampaignFlow").go("menu")))
	night = preload("res://scripts/hud_night1.gd").new(); night.g = g; root.add_child(night); night.setup(left_box, right_box)
	if not Phone.narrow(Phone.window_size()): night.vitals_pips.custom_minimum_size.x = 150
	if g.has_signal("battle_event") and not g.is_connected("battle_event", _on_battle_event): g.connect("battle_event", _on_battle_event)
	aim_ui = preload("res://scripts/battle12_aim.gd").new()
	aim_ui.setup(g, root, Phone.narrow(Phone.window_size()))
	if Phone.narrow(Phone.window_size()):
		phone = preload("res://scripts/hud_phone.gd").new()
		phone.setup(g, night, root, top, left, right, bottom, row)
	else:
		bar = preload("res://scripts/battle13_bar.gd").new()
		bar.setup(g, root, row, g.action_buttons)
	combo_overlay = preload("res://scripts/hud18_tags.gd").new()
	root.add_child(combo_overlay)
	combo_overlay.setup(g)

func _on_battle_event(kind: String, _actor_id: String, _target_id: String, context: Dictionary) -> void:
	if kind not in ["reveal", "villain_reveal"] or night == null: return
	var group: Array = []
	var token: Variant = context.get("group", [])
	if token is Array: group = token
	elif token is int or token is String and str(token).is_valid_int():
		for enemy in g.mission.living("enemy"):
			if int(enemy.get("group", -999)) == int(token): group.append(enemy)
	var info: Dictionary = Threat22.reveal(g.mission, group)
	if not info.is_empty(): night.show_reveal(str(info.get("title", "")))


func _refresh() -> void:
	var u: Dictionary = g.mission.unit_by_id(g.selected_id)
	if phone == null and desktop_threat_chip != null:
		var forecast: Dictionary = Threat22.summary(g.mission)
		desktop_threat_chip.text = Threat22.chip(forecast)
		desktop_threat_chip.visible = not forecast.is_empty()
	g.warning_label.visible = phone == null and g.warning_label.text != "" and not g.warning_label.text.begins_with("TAB / SHIFT+TAB")
	if u.is_empty() or int(u.get("hp", 0)) <= 0:
		var survivors: Array[Dictionary] = g.mission.living("player")
		if not survivors.is_empty():
			g.selected_id = int(survivors[0].id)
			u = survivors[0]
	var objective: Dictionary = g.mission.objective_status()
	var clock_note := " · %d turns left" % int(objective.turns_left) if int(objective.turns_left) >= 0 else " · clock starts on reveal" if objective.get("clock_trigger", "") == "concealment" else ""
	if phone != null:
		var brief: String = str(objective.label).replace("Rescue Mira and escort to evac", "Rescue Mira to evac" if Phone.touch_device() else "Rescue Mira → evac")
		if Phone.window_size().x < 600: brief = "RESCUE" if brief.begins_with("Rescue Mira") else brief.get_slice(" · ", 0)
		g.objective_label.text = "T%d · %s · %d left" % [g.mission.turn, brief, int(objective.turns_left)] if int(objective.turns_left) >= 0 else "T%d · %s" % [g.mission.turn, brief]
	else:
		g.objective_label.text = "TURN %d · %s%s · %s" % [g.mission.turn,objective.label,clock_note,str(objective.phase).to_upper()]
	g.selected_label.text = "%s\n%s%s\nHP %d/%d\nAP %s\nFOCUS %d  •  MEDPACS %d%s" % [u.get("name", ""), u.get("class_name", ""), "  WOUNDED" if bool(u.get("wounded", false)) else "", int(u.get("hp",0)), int(u.get("max_hp",0)), ap_pips(u), int(u.get("focus_left", 0)), int(u.get("medpacs", 0)), "\nHUNKERED  +30 DEF" if bool(u.get("hunkered", false)) else ""]
	if u.has("ammo"): g.selected_label.text += "\nAMMO %d/%d" % [int(u.ammo), int(u.clip)]
	# --- wave10 story ---
	var flow = g.get_node_or_null("/root/CampaignFlow")
	if flow != null and flow.active and u.has("rid"):
		g.selected_label.text += "\nBOND  " + preload("res://scripts/campaign/bond_overlay.gd").summary(flow.session().state,str(u.rid))
	if bool(u.get("concealed", false)): g.selected_label.text += "\nCONCEALED"
	if g.mission.get("momentum") != null: g.selected_label.text += "\nMOMENTUM %d/10" % int(g.mission.momentum)
	var kind := str(u.get("model", ""))
	if kind != g.portrait_kind and g.model_cache.has(kind):
		if g.portrait_model != null: g.portrait_model.queue_free()
		g.portrait_model = g.model_cache[kind].instantiate()
		g.portrait_model.rotation.y = PI
		g.portrait_viewport.add_child(g.portrait_model)
		g.portrait_kind = kind
	g.log_label.text = "\n".join(g.mission.log_lines.slice(max(0, g.mission.log_lines.size() - 4)))
	var extras: Array = []
	var shared: Array = ["revive"] if str(u.get("class_name", "")) == "Medic" else ["medpac", "revive"]
	for id in shared + u.get("kit", []):
		if id not in ["move", "shoot", "strike", "push", "free", "overwatch", "hunker"] and id not in extras: extras.append(id)
	for mode in g.action_buttons:
		var button: Button = g.action_buttons[mode]
		var core: bool = mode in ["move", "shoot", "strike", "push", "free", "overwatch", "hunker"]
		button.visible = mode == "move" or mode in u.get("kit", []) or mode in extras
		if mode == "free": button.visible = not g.mission.modern
		if not button.visible: continue
		var def: Dictionary = g.mission.abilities[mode]
		var reason: String = "" if mode == "move" else g.mission.ability_reason(g.selected_id, mode)
		if mode == "move" and int(u.get("ap", 0)) <= 0: reason = "Need AP"
		var key := str(["move", "shoot", "strike", "push", "free", "overwatch", "hunker"].find(mode) + 1) if core else ("F%d" % (extras.find(mode) + 1) if extras.find(mode) < 12 else "")
		if mode == "interact": key = "5"
		var ap := "all" if str(def.get("ap")) == "remaining" else str(int(def.get("ap", 1)))
		var charges := str(def.get("charges", ""))
		var detail := " • %d left" % int(u.get(charges, 0)) if charges != "" else ""
		var cd: Dictionary = u.get("cooldowns", {})
		var turns := maxi(0, int(cd.get(mode, 0)) - g.mission.turn)
		button.call("configure", mode, str(def.get("name", mode.capitalize())), key, ap, turns, reason, g.action == mode)
		button.call("set_chain", def, g.mission.unit_by_id(g.target_id))
		button.set_meta("battle13_available", button.visible and not button.disabled)
		if charges != "": button.tooltip_text += detail
	g.result_panel.visible = g.mission.result != ""
	var cine_button: Button = g.overlay.find_child("CineButton", true, false)
	if cine_button != null: cine_button.text = "Cinematics: %s" % ("On" if g.action_camera else "Off")
	if g.mission.result != "":
		var wounded: Array[String] = []
		for member in g.mission.units:
			if str(member.side) == "player" and bool(member.get("wounded", false)): wounded.append(str(member.name))
		g.result_label.text = ("MISSION COMPLETE" if g.mission.result == "win" else "MISSION FAILED") + "\nWounded: " + (", ".join(wounded) if not wounded.is_empty() else "None")
	g._refresh_figures(); _refresh_highlights(true); _show_shot(); night.refresh()
	if phone == null:
		night.log_heading.visible = false
		g.log_label.visible = false
	if phone != null: phone.refresh(true)
	if bar != null: bar.refresh()
	if aim_ui != null: aim_ui.refresh()
	if phone != null: night.chips.visible = false
	if phone == null:
		var aiming: bool = aim_ui != null and aim_ui.panel.visible
		left_panel.visible = not aiming
		right_panel.visible = not aiming and g.action != "move"


func _show_shot() -> void:
	targeting.g = g
	targeting.clear_trace()
	if night != null: night.refresh_target.call_deferred()
	if phone != null: phone.refresh.call_deferred()
	if aim_ui != null: aim_ui.refresh.call_deferred()
	var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
	if g.action not in ["shoot", "strike", "push", "move"]:
		var def: Dictionary = g.mission.abilities.get(g.action, {})
		var target: Dictionary = g.mission.unit_by_id(g.target_id)
		g.hit_big_label.text = str(def.get("name", "ABILITY")).to_upper()
		var lines: Array[String] = []
		if not target.is_empty(): lines.append("Target: %s • HP %d/%d" % [target.name, int(target.hp), int(target.max_hp)])
		elif g.preview_tile.x >= 0: lines.append("Tile: %d, %d" % [g.preview_tile.x, g.preview_tile.y])
		lines.append("Range %s • %s AP • %d Focus" % [str(def.get("range", "self")), ("remaining" if str(def.get("ap")) == "remaining" else str(int(def.get("ap", 1)))), int(def.get("focus", 0))])
		if def.has("heal"): lines.append("Heal %d HP (capped at max)" % int(def.heal))
		if def.has("revive"): lines.append("Revive at %d HP" % int(def.revive))
		if def.has("damage"): lines.append("Damage %s" % str(def.damage))
		if def.has("status"): lines.append("Applies %s" % str(def.status))
		if def.has("chance"): lines.append("Chance %d%%" % int(def.chance))
		if g.action in ["rewardSafe","rewardRisky"] and g.preview_tile.x >= 0:
			var options: Dictionary = preload("res://scripts/mission_hack.gd").options(g.mission,actor,g.preview_tile)
			if not options.is_empty(): lines.append("Safe %d%% · reveal / Intel or stun\nRisky %d%% · stun / control; failure alerts enemies" % [options.safe,options.risky])
		lines.append("Tap again to confirm." if preload("res://scripts/phone_layout.gd").touch_device() else "Click again or Enter to confirm.")
		g.shot_label.text = "\n".join(lines)
		return
	var target: Dictionary = {}
	for u in g.mission.living("enemy"):
		if (int(u.id) == g.target_id or (g.target_id < 0 and Shot.pos(u) == g.hovered)) and (bool(u.awake) or bool(u.get("spotted", false))): target = u; break
	if actor.is_empty() or target.is_empty():
		g.hit_big_label.text = "--%"
		g.shot_label.text = "Choose Shoot, Strike or Push.\nTap a target, then confirm or cancel." if preload("res://scripts/phone_layout.gd").touch_device() else "Choose Shoot, Strike or Push.\nTab cycles valid targets.\nEnter confirms; Esc cancels."
		return
	if g.action == "push":
		var legal := false
		for option in InputControls.valid_targets(g.mission, actor, "push"):
			if int(option.id) == int(target.id): legal = true
		g.hit_big_label.text = "PUSH" if legal else "NO PUSH"
		g.shot_label.text = "%s  HP %d\n%s\nNo hit or crit roll.\nCosts %d AP and %d Focus." % [target.name, int(target.hp), "Guaranteed knockback if confirmed." if legal else "Move into range with clear line of sight.", int(g.mission.abilities.push.ap), int(g.mission.abilities.push.focus)]
		return
	var info: Dictionary = targeting.shot_breakdown(g.mission, actor, target, g.action == "strike", int(actor.get("leap_aim", 0)) if g.action == "strike" else 0)
	g.hit_big_label.text = "%d%% HIT" % int(info.hit)
	var breakdown := ""
	for item in info.lines: breakdown += "%s  %+d\n" % [item[0], int(item[1])]
	var damage := Shot.damage_preview(actor, target)
	g.hit_big_label.text = "%d%% HIT" % int(info.hit) if bool(info.los) and bool(info.range_ok) else "BLOCKED" if not bool(info.los) else "OUT OF RANGE"
	g.shot_label.text = "%s  HP %d%s\nCRIT %d%%  ·  GRAZE %d%%\nDMG %d–%d  ·  ARMOR %d\nCRIT %d–%d  ·  GRAZE %d–%d\nSHRED %d on hit\n%s\n%s" % [target.name, int(target.hp), "  ·  FLANKED" if bool(info.flanked) else "", int(info.crit), int(info.graze), damage.normal[0], damage.normal[1], damage.armor, damage.critical[0], damage.critical[1], damage.graze[0], damage.graze[1], damage.shred, breakdown, "LOS CLEAR" if bool(info.los) else "LOS BLOCKED — red trace"]
	if actor.has("ammo"): g.shot_label.text += "\nAMMO %d/%d · 2 AP" % [int(actor.ammo), int(actor.clip)]
	targeting.trace(actor, target)
