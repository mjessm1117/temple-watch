extends RefCounted
## Shared aim strip for desktop and landscape phones.
const InputControls = preload("res://scripts/input_controls.gd")
const Shot = preload("res://scripts/shot.gd")
var g
var panel: PanelContainer
var targets: HBoxContainer
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
		panel.anchor_top = 1.0; panel.anchor_bottom = 1.0
		panel.offset_top = -62; panel.offset_bottom = -4
	else:
		panel.anchor_top = 1.0; panel.anchor_bottom = 1.0
		panel.offset_top = -114; panel.offset_bottom = -8
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
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 3); body.add_child(row)
	row.add_child(_button("‹", 44, func() -> void: g._cycle_target(-1)))
	targets = HBoxContainer.new(); targets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	targets.add_theme_constant_override("separation", 3); row.add_child(targets)
	row.add_child(_button("›", 44, func() -> void: g._cycle_target(1)))
	confirm = _button("FIRE", 190, _confirm); confirm.name = "FireButton"; row.add_child(confirm)
	details = _button("ODDS", 64, _details); row.add_child(details)
	cine_toggle = _button("CINE ON", 76, _toggle_cine); cine_toggle.name = "Cine15Toggle"; row.add_child(cine_toggle)
	row.add_child(_button("CANCEL", 76, g._cancel_order))
	panel.hide()

func _button(value: String, width: float, action: Callable) -> Button:
	var b := Button.new(); b.text = value; b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(width, 44 if phone else 50)
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(action)
	return b

func refresh() -> void:
	if panel == null: return
	var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
	var active: bool = g.action != "move" and g.action != "free" and g.action != "overwatch" and g.action != "hunker" and g.target_id >= 0 and not actor.is_empty() and g.mission.phase == "player" and g.mission.result == ""
	panel.visible = active
	sight.visible = active
	cine_toggle.text = "CINE ON" if g.action_camera else "CINE OFF"
	if phone and g.hud_controls.phone != null:
		g.hud_controls.phone.ability_tray.visible = not active
		g.hud_controls.phone.ability_tray.offset_top = 0.0 if active else -76.0
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
	for offset in range(mini(options.size(), 1 if phone else 2)):
		var enemy: Dictionary = options[(selected_index + offset) % options.size()]
		var id: int = int(enemy.id)
		var label := str(enemy.name)
		if g.action in ["shoot", "strike"]:
			var info: Dictionary = Shot.calculate(g.mission, actor, enemy, g.action == "strike")
			label += (" · %d/%d" % [int(enemy.hp), int(enemy.max_hp)]) if phone else ("\n%d%% HIT" % int(info.hit))
		var chip := _button(label, 104 if not phone else 130, func() -> void: g.target_id = id; g._frame_target(); g._show_shot())
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
		confirm.text = "%s · %d%% HIT\n%d–%d DMG" % ["FIRE" if g.action == "shoot" else "STRIKE", int(info.hit), int(damage.normal[0]), int(damage.normal[1])]
	else:
		confirm.text = "CONFIRM\n%s" % str(g.mission.abilities.get(g.action, {}).get("name", g.action)).to_upper()

func _confirm() -> void:
	if g.target_id < 0: return
	if g.action in ["shoot", "strike", "push"]: g._attack(g.target_id, g.action)
	else: g._use_ability(g.target_id)

func _toggle_cine() -> void:
	g.action_camera = not g.action_camera
	preload("res://scripts/campaign/strat_preferences.gd").set_value("cine", g.action_camera)
	cine_toggle.text = "CINE ON" if g.action_camera else "CINE OFF"

func _details() -> void:
	if phone and g.hud_controls.phone != null:
		g.hud_controls.phone._toggle("target")
	else:
		g.hud_controls.night.detail_open = not g.hud_controls.night.detail_open
		g.hud_controls.night.refresh_target()
