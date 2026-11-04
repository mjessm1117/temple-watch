extends RefCounted
## Shared aim strip for desktop and landscape phones.
const InputControls = preload("res://scripts/input_controls.gd")
const Shot = preload("res://scripts/shot.gd")
var g
var panel: PanelContainer
var targets: HBoxContainer
var confirm: Button
var details: Button
var phone := false

static func phone_frame_point(game, midpoint: Vector3) -> Vector3:
	var size: Vector2i = preload("res://scripts/phone_layout.gd").window_size()
	if not preload("res://scripts/phone_layout.gd").narrow(size): return midpoint
	return midpoint + Vector3(sin(game.yaw), 0.0, cos(game.yaw)) * 0.5

static func frame_zoom(game, base_zoom: float) -> float:
	var size: Vector2i = preload("res://scripts/phone_layout.gd").window_size()
	return base_zoom * (1.6 if preload("res://scripts/phone_layout.gd").narrow(size) else 1.18)

func setup(game, root: Control, on_phone: bool) -> void:
	g = game; phone = on_phone
	panel = PanelContainer.new(); panel.name = "AimStrip"
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.offset_left = -minf(335.0 if not phone else 410.0, root.size.x * 0.49)
	panel.offset_right = minf(335.0 if not phone else 410.0, root.size.x * 0.49)
	if phone:
		panel.anchor_top = 1.0; panel.anchor_bottom = 1.0
		panel.offset_top = -126; panel.offset_bottom = -78
	else:
		panel.anchor_top = 1.0; panel.anchor_bottom = 1.0
		panel.offset_top = -268; panel.offset_bottom = -206
	var style := StyleBoxFlat.new(); style.bg_color = Color("101b26ee")
	style.border_color = Color("d2aa65"); style.set_border_width_all(1)
	style.set_content_margin_all(4); panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 3); panel.add_child(row)
	row.add_child(_button("‹", 44, func() -> void: g._cycle_target(-1)))
	targets = HBoxContainer.new(); targets.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	targets.add_theme_constant_override("separation", 3); row.add_child(targets)
	row.add_child(_button("›", 44, func() -> void: g._cycle_target(1)))
	confirm = _button("FIRE", 190 if not phone else 220, _confirm); row.add_child(confirm)
	details = _button("ODDS", 64, _details); row.add_child(details)
	row.add_child(_button("CANCEL", 72, g._cancel_order))
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
	if not active: return
	for child in targets.get_children(): child.queue_free()
	var options: Array[Dictionary] = InputControls.valid_targets(g.mission, actor, g.action)
	var selected_index := 0
	for index in range(options.size()):
		if int(options[index].id) == g.target_id: selected_index = index
	for offset in range(mini(options.size(), 1 if phone else 2)):
		var enemy: Dictionary = options[(selected_index + offset) % options.size()]
		var id: int = int(enemy.id)
		var label := str(enemy.name).left(10)
		if g.action in ["shoot", "strike"]:
			var info: Dictionary = Shot.calculate(g.mission, actor, enemy, g.action == "strike")
			label += "\n%d%% HIT" % int(info.hit)
		var chip := _button(label, 104 if not phone else 130, func() -> void: g.target_id = id; g._frame_target(); g._show_shot())
		chip.add_theme_color_override("font_color", Color("f6d28a") if id == g.target_id else Color("e3edf0"))
		targets.add_child(chip)
	var target: Dictionary = g.mission.unit_by_id(g.target_id)
	confirm.disabled = target.is_empty() or g.player_attack_pending
	if target.is_empty(): return
	if g.action in ["shoot", "strike"]:
		var info: Dictionary = Shot.calculate(g.mission, actor, target, g.action == "strike")
		var damage: Dictionary = Shot.damage_preview(actor, target)
		confirm.text = "%s · %d%% HIT\n%d%% CRIT · %d–%d DMG" % ["FIRE" if g.action == "shoot" else "STRIKE", int(info.hit), int(info.crit), int(damage.normal[0]), int(damage.normal[1])]
	else:
		confirm.text = "CONFIRM\n%s" % str(g.mission.abilities.get(g.action, {}).get("name", g.action)).to_upper()

func _confirm() -> void:
	if g.target_id < 0: return
	if g.action in ["shoot", "strike", "push"]: g._attack(g.target_id, g.action)
	else: g._use_ability(g.target_id)

func _details() -> void:
	if phone and g.hud_controls.phone != null:
		g.hud_controls.phone._toggle("target")
	else:
		g.hud_controls.night.detail_open = not g.hud_controls.night.detail_open
		g.hud_controls.night.refresh_target()
