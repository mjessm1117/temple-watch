extends RefCounted
## Shared aim strip for desktop and landscape phones.
const InputControls = preload("res://scripts/input_controls.gd")
const Shot = preload("res://scripts/shot.gd")
var g
var panel: PanelContainer
var targets: HBoxContainer
var target_row: PanelContainer
var odds: Label
var odds_detail: Label
var cancel: Button
var aim_momentum: Label
var confirm: Button
var details: Button
var summary: Label
var phone := false
var sight: Control
var lighting: Node
var cine_toggle: Button

static func phone_frame_point(game, midpoint: Vector3) -> Vector3:
	var size: Vector2i = preload("res://scripts/phone_layout.gd").window_size()
	if not preload("res://scripts/phone_layout.gd").narrow(size): return midpoint
	return midpoint + Vector3(sin(game.yaw), 0.0, cos(game.yaw)) * 0.5

static func frame_zoom(game, base_zoom: float) -> float:
	var size: Vector2i = preload("res://scripts/phone_layout.gd").window_size()
	return base_zoom * (1.6 if preload("res://scripts/phone_layout.gd").narrow(size) else 1.18)

func setup(game, root: Control, on_phone: bool) -> void:
	g = game; phone = on_phone
	lighting = preload("res://scripts/cine15_lighting.gd").new()
	lighting.name = "Cine15AimLighting"; lighting.game = g; g.add_child(lighting)
	var desktop_toggle: Button = root.find_child("CineButton", true, false)
	if desktop_toggle != null:
		desktop_toggle.pressed.connect(func() -> void:
			preload("res://scripts/campaign/strat_preferences.gd").set_value("cine", g.action_camera))
	panel = PanelContainer.new(); panel.name = "AimStrip"
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.offset_left = -minf(350.0, root.size.x * 0.47)
	panel.offset_right = minf(350.0, root.size.x * 0.47)
	if phone:
		panel.anchor_left = 1.0; panel.anchor_right = 1.0
		panel.anchor_top = 1.0; panel.anchor_bottom = 1.0
		panel.offset_left = -minf(350.0, root.size.x - 262.0); panel.offset_right = -6
		panel.offset_top = -62; panel.offset_bottom = -4
		if root.size.x < root.size.y:
			panel.anchor_left = 0.0; panel.anchor_right = 1.0
			panel.offset_left = 12; panel.offset_right = -12
	else:
		panel.anchor_top = 1.0; panel.anchor_bottom = 1.0
		panel.offset_top = -94; panel.offset_bottom = -8
	var style := StyleBoxFlat.new(); style.bg_color = Color("101b26ee")
	style.border_color = Color("d2aa65"); style.set_border_width_all(1)
	style.set_content_margin_all(4); panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	sight = preload("res://scripts/battle14_sight.gd").new()
	sight.name = "AimSight"; sight.game = g
	sight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(sight)
	root.move_child(sight, panel.get_index())
	var body := VBoxContainer.new(); body.add_theme_constant_override("separation", 2); panel.add_child(body)
	summary = Label.new(); summary.name = "TargetSummary"; summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 14); summary.add_theme_color_override("font_color", Color("f2d99a"))
	summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; body.add_child(summary)
	summary.visible = not phone
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 4); body.add_child(row)
	if phone:
		var odds_box := VBoxContainer.new(); odds_box.custom_minimum_size.x = 96 if root.size.x < root.size.y else 144; row.add_child(odds_box)
		odds_box.name = "AimInlineOdds"
		odds = Label.new(); odds.name = "AimOdds"; odds.add_theme_font_size_override("font_size", 21)
		odds.add_theme_color_override("font_color", Color("f2d99a")); odds_box.add_child(odds)
		odds_detail = Label.new(); odds_detail.name = "AimOddsDetail"; odds_detail.add_theme_font_size_override("font_size", 12)
		odds_detail.add_theme_color_override("font_color", Color("e7edf0")); odds_box.add_child(odds_detail)
		confirm = _button("CONFIRM", 105, _confirm); confirm.name = "FireButton"; row.add_child(confirm)
		if root.size.x < 600: confirm.add_theme_font_size_override("font_size", 12)
		cancel = _button("CANCEL", 70 if root.size.x < 600 else 76, g._cancel_order); cancel.name = "AimCancel"; row.add_child(cancel)
		target_row = PanelContainer.new(); target_row.name = "AimTargetRow"
		target_row.anchor_left = 1.0; target_row.anchor_right = 1.0
		target_row.offset_left = -minf(340.0, root.size.x * 0.48); target_row.offset_right = -6
		target_row.offset_top = 48; target_row.offset_bottom = 102
		target_row.add_theme_stylebox_override("panel", style.duplicate()); root.add_child(target_row)
		var target_box := HBoxContainer.new(); target_box.add_theme_constant_override("separation", 3); target_row.add_child(target_box)
		target_box.add_child(_button("‹", 44, func() -> void: g._cycle_target(-1)))
		targets = HBoxContainer.new(); targets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		targets.add_theme_constant_override("separation", 2); target_box.add_child(targets)
		target_box.add_child(_button("›", 44, func() -> void: g._cycle_target(1)))
		details = _button("ODDS", 44, _details); target_box.add_child(details)
		details.visible = root.size.x >= 600
		aim_momentum = Label.new(); aim_momentum.name = "AimMomentum"
		aim_momentum.custom_minimum_size = Vector2(33, 44)
		aim_momentum.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		aim_momentum.add_theme_font_size_override("font_size", 11)
		aim_momentum.add_theme_color_override("font_color", Color("e9ca83"))
		target_box.add_child(aim_momentum)
		cine_toggle = _button("Cinematics: On", 116, _toggle_cine); cine_toggle.visible = false
		target_box.add_child(cine_toggle)
	else:
		row.add_child(_button("‹", 44, func() -> void: g._cycle_target(-1)))
		targets = HBoxContainer.new(); targets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		targets.add_theme_constant_override("separation", 3); row.add_child(targets)
		row.add_child(_button("›", 44, func() -> void: g._cycle_target(1)))
		confirm = _button("CONFIRM", 190, _confirm); confirm.name = "FireButton"; row.add_child(confirm)
		details = _button("ODDS", 64, _details); row.add_child(details)
		cine_toggle = _button("Cinematics: On", 142, _toggle_cine); cine_toggle.name = "Cine15Toggle"; row.add_child(cine_toggle)
		cine_toggle.add_theme_font_size_override("font_size", 13)
		cancel = _button("CANCEL", 76, g._cancel_order); cancel.name = "AimCancel"; row.add_child(cancel)
	panel.hide()
	if target_row != null: target_row.hide()

func _button(value: String, width: float, action: Callable) -> Button:
	var b := Button.new(); b.text = value; b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(width, 50 if phone and value in ["CONFIRM", "CANCEL"] else 44 if phone else 50)
	b.add_theme_font_size_override("font_size", 14 if phone else 13)
	b.pressed.connect(action)
	return b

func refresh() -> void:
	if panel == null: return
	var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
	var active: bool = g.action != "move" and g.action != "free" and g.action != "overwatch" and g.action != "hunker" and g.target_id >= 0 and not actor.is_empty() and g.mission.phase == "player" and g.mission.result == ""
	panel.visible = active
	if target_row != null: target_row.visible = active
	if aim_momentum != null:
		var pip_count: int = clampi(int(g.mission.chain_momentum), 0, 3)
		aim_momentum.text = "●".repeat(pip_count) + "○".repeat(3 - pip_count)
	sight.visible = active
	cine_toggle.text = "Cinematics: On" if g.action_camera else "Cinematics: Off"
	if phone and g.hud_controls.phone != null:
		g.hud_controls.phone.ability_tray.visible = not active
		g.hud_controls.phone.camera_rail.visible = not active
		g.hud_controls.phone.camera_art.visible = not active

	elif g.hud_controls.desktop_bottom != null:
		g.hud_controls.desktop_bottom.visible = not active
	if not active:
		lighting.reset()
		g.cam.end_preview()
		return
	for child in targets.get_children(): child.queue_free()
	var options: Array[Dictionary] = InputControls.valid_targets(g.mission, actor, g.action)
	var selected_index := 0
	for index in range(options.size()):
		if int(options[index].id) == g.target_id: selected_index = index
	var portrait: bool = phone and g.get_viewport().get_visible_rect().size.y > g.get_viewport().get_visible_rect().size.x
	for offset in range(mini(options.size(), 1 if portrait else 2)):
		var enemy: Dictionary = options[(selected_index + offset) % options.size()]
		var id: int = int(enemy.id)
		var label := "◉" if phone else str(enemy.name)
		if g.action in ["shoot", "strike"] and not portrait:
			var info: Dictionary = Shot.calculate(g.mission, actor, enemy, g.action == "strike")
			label += ("\n%d%% HIT" % int(info.hit))
		var chip := _button(label, 104 if not phone else 52 if g.get_viewport().get_visible_rect().size.x < 600 else 62, func() -> void: g.target_id = id; g._frame_target(); g._show_shot())
		chip.tooltip_text = str(enemy.name)
		chip.add_theme_color_override("font_color", Color("f6d28a") if id == g.target_id else Color("e3edf0"))
		targets.add_child(chip)
	var target: Dictionary = g.mission.unit_by_id(g.target_id)
	confirm.disabled = target.is_empty() or g.player_attack_pending
	if target.is_empty(): return
	g.cam.preview(actor, target)
	lighting.sync(actor, target)
	summary.text = "%s  ·  HP %d/%d" % [str(target.name), int(target.hp), int(target.max_hp)]
	if g.action in ["shoot", "strike"]:
		var info: Dictionary = Shot.calculate(g.mission, actor, target, g.action == "strike")
		var damage: Dictionary = Shot.damage_preview(actor, target)
		confirm.text = "CONFIRM %s\nHIT · DMG" % ("FIRE" if g.action == "shoot" else "STRIKE") if phone else "%s · %d%% HIT\n%d–%d DMG" % ["FIRE" if g.action == "shoot" else "STRIKE", int(info.hit), int(damage.normal[0]), int(damage.normal[1])]
		if phone:
			odds.text = "%d%% HIT" % int(info.hit)
			odds_detail.text = "%d%% CRIT · %d–%d DMG" % [int(info.crit), int(damage.normal[0]), int(damage.normal[1])]
	else:
		confirm.text = "CONFIRM\n%s" % str(g.mission.abilities.get(g.action, {}).get("name", g.action)).to_upper()
	var chain: Dictionary = g.mission.abilities.get(g.action, {}).get("chain", {})
	var marks: Array[String] = []
	var ready := false
	for kind in ["consume", "apply"]:
		for entry in chain.get(kind, []):
			var tag := str(entry.get("tag", "")) if entry is Dictionary else str(entry)
			marks.append(("−" if kind == "consume" else "+") + str(preload("res://scripts/hud18_icon.gd").GLYPHS.get(tag, "•")))
			if kind == "consume" and target.get("combo_tags", {}).has(tag): ready = true
	if not marks.is_empty() and not phone: confirm.text += "  " + " ".join(marks)
	confirm.modulate = Color("b2ffc1") if ready else Color.WHITE

func _confirm() -> void:
	if g.target_id < 0: return
	if g.action in ["shoot", "strike", "push"]: g._attack(g.target_id, g.action)
	else: g._use_ability(g.target_id)

func _toggle_cine() -> void:
	g.action_camera = not g.action_camera
	preload("res://scripts/campaign/strat_preferences.gd").set_value("cine", g.action_camera)
	cine_toggle.text = "Cinematics: On" if g.action_camera else "Cinematics: Off"

func _details() -> void:
	if phone and g.hud_controls.phone != null:
		g.hud_controls.phone._toggle("target")
	else:
		g.hud_controls.night.detail_open = not g.hud_controls.night.detail_open
		g.hud_controls.night.refresh_target()
