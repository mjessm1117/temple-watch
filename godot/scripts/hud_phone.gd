extends RefCounted
## Compact battle controls. The full desktop HUD remains available at wide sizes.
var g
var night
var overlay: Control
var unit_card: Button
var target_card: Button
var action_name: Label
var popup: PanelContainer
var popup_body: VBoxContainer
var open_card := ""

func setup(game, night_hud, root: Control, top: Control, left: Control, right: Control, bottom: Control, abilities: HFlowContainer) -> void:
	g = game; night = night_hud
	top.hide(); left.hide(); right.hide(); bottom.hide()
	overlay = Control.new(); overlay.name = "PhoneBattleHUD"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(overlay)
	var strip := PanelContainer.new(); strip.anchor_right = 1.0; strip.offset_bottom = 34
	var strip_style: StyleBoxFlat = night.panel_style(); strip_style.set_content_margin_all(2)
	strip.add_theme_stylebox_override("panel", strip_style); overlay.add_child(strip)
	var heading := HBoxContainer.new(); strip.add_child(heading)
	g.objective_label.reparent(heading); g.objective_label.add_theme_font_size_override("font_size", 12)
	g.objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.objective_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	g.objective_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.add_child(_button("END TURN", _end_turn))
	heading.add_child(_button("☰", _show_menu))
	unit_card = _button("UNIT", _toggle.bind("unit")); unit_card.name = "UnitCard"
	unit_card.offset_left = 6; unit_card.offset_right = 224; unit_card.offset_top = 38; unit_card.offset_bottom = 75
	overlay.add_child(unit_card)
	target_card = _button("TARGET", _toggle.bind("target")); target_card.name = "TargetCard"
	target_card.anchor_left = 1.0; target_card.anchor_right = 1.0
	target_card.offset_left = -224; target_card.offset_right = -6; target_card.offset_top = 38; target_card.offset_bottom = 75
	overlay.add_child(target_card)
	var tray := PanelContainer.new(); tray.name = "AbilityTray"
	tray.anchor_top = 1.0; tray.anchor_right = 1.0; tray.anchor_bottom = 1.0
	tray.offset_top = -64
	var tray_style: StyleBoxFlat = night.panel_style(); tray_style.set_content_margin_all(2)
	tray.add_theme_stylebox_override("panel", tray_style); overlay.add_child(tray)
	var tray_box := VBoxContainer.new(); tray_box.add_theme_constant_override("separation", 0); tray.add_child(tray_box)
	action_name = night.label("Tap or hold an ability for its name", 12, Color("e9ca83"))
	action_name.custom_minimum_size.y = 13; tray_box.add_child(action_name)
	var scroll := ScrollContainer.new(); scroll.name = "Abilities"
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.custom_minimum_size.y = 46; tray_box.add_child(scroll)
	scroll.get_h_scroll_bar().modulate.a = 0.0
	var track := HBoxContainer.new(); track.add_theme_constant_override("separation", 3); scroll.add_child(track)
	for node in abilities.get_children():
		var button: Button = node
		button.reparent(track); button.custom_minimum_size = Vector2(46, 46)
		button.set_meta("graphics_custom_minimum_size", Vector2(46, 46))
		button.set("compact", true); button.button_down.connect(_show_ability.bind(button))
		button.pressed.connect(_show_ability.bind(button))
		button.gui_input.connect(_ability_input.bind(button))
	popup = PanelContainer.new(); popup.name = "PhoneDetails"; popup.visible = false
	popup.anchor_left = 0.5; popup.anchor_right = 0.5; popup.anchor_bottom = 1.0
	popup.offset_left = -220; popup.offset_right = 220; popup.offset_top = 38; popup.offset_bottom = -74
	popup.add_theme_stylebox_override("panel", night.panel_style()); overlay.add_child(popup)
	var detail_scroll := ScrollContainer.new(); detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	popup.add_child(detail_scroll)
	popup_body = VBoxContainer.new(); popup_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(popup_body)

func _button(title: String, action: Callable) -> Button:
	var button := Button.new(); button.text = title; button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 38; button.pressed.connect(action)
	return button

func _show_ability(button: Button) -> void:
	action_name.text = button.tooltip_text

func _ability_input(event: InputEvent, button: Button) -> void:
	if event is InputEventScreenTouch and event.pressed: _show_ability(button)

func _toggle(card: String) -> void:
	open_card = "" if open_card == card else card
	refresh()

func _show_menu() -> void:
	open_card = "menu"; refresh()

func _end_turn() -> void:
	g._request_end_turn()
	if g.warning_label.text != "": action_name.text = g.warning_label.text

func _close() -> void:
	open_card = ""; refresh()

func refresh() -> void:
	if overlay == null: return
	if g.warning_label.text != "": action_name.text = g.warning_label.text
	elif g.path_label.text != "": action_name.text = g.path_label.text
	var unit: Dictionary = g.mission.unit_by_id(g.selected_id)
	unit_card.text = "%s  HP %s  AP %s  ▾" % [str(unit.get("name", "UNIT")), str(unit.get("hp", "?")), str(unit.get("ap", "?"))]
	var target: Dictionary = g.mission.unit_by_id(g.target_id)
	target_card.text = "%s  %s  ▾" % [str(target.get("name", "TARGET")), g.hit_big_label.text]
	popup.visible = open_card != ""
	if open_card == "": return
	if open_card == "settings": return
	for child in popup_body.get_children(): child.queue_free()
	if open_card == "unit":
		popup_body.add_child(night.label("SQUAD  ·  tap a name to select", 14, Color("efd49b")))
		var squad := HFlowContainer.new(); popup_body.add_child(squad)
		for member in g.mission.living("player"):
			var id: int = int(member.id)
			squad.add_child(_button(str(member.name), func() -> void: g._select(id); refresh()))
		popup_body.add_child(night.label(_unit_details(unit), 14))
		popup_body.add_child(night.label("TURN OBJECTIVE  " + g.objective_label.text, 12))
		if g.path_label.text != "": popup_body.add_child(night.label(g.path_label.text, 12))
		if g.warning_label.text != "": popup_body.add_child(night.label(g.warning_label.text, 12))
	elif open_card == "target":
		popup_body.add_child(night.label("TARGETING  ·  " + g.hit_big_label.text, 16, Color("efd49b")))
		popup_body.add_child(night.label(g.shot_label.text, 14))
		if night.target_details.visible:
			popup_body.add_child(night.label(night.target_details.text, 14))
			popup_body.add_child(_button("ODDS BREAKDOWN", func() -> void: night.detail_open = not night.detail_open; night.refresh_target(); refresh()))
		popup_body.add_child(night.label("COMBAT LOG\n" + g.log_label.text, 12))
	else:
		popup_body.add_child(_button("RESUME", _close))
		popup_body.add_child(_button("GRAPHICS", _show_settings))
		popup_body.add_child(_button("ACTION CAM: %s" % ("ON" if g.action_camera else "OFF"), func() -> void: g.action_camera = not g.action_camera; refresh()))
		popup_body.add_child(_button("SOUND: %s" % ("OFF" if g.sound.muted else "ON"), func() -> void: g.sound.muted = not g.sound.muted; refresh()))
		popup_body.add_child(_button("NUMBERS: %s" % ("ON" if bool(g.Prefs.get_value("numbers")) else "OFF"), func() -> void:
			g.Prefs.set_value("numbers", not bool(g.Prefs.get_value("numbers"))); g._refresh(); refresh()))
		popup_body.add_child(_button("RESTART MISSION", func() -> void: g.get_tree().reload_current_scene()))
		popup_body.add_child(_button("MAIN MENU", func() -> void: g.get_node("/root/CampaignFlow").go("menu")))
	popup_body.add_child(_button("CLOSE", _close))

func _unit_details(unit: Dictionary) -> String:
	var lines: Array[String] = [str(unit.get("name", "UNIT")), str(unit.get("class_name", "Jedi"))]
	lines.append("HP %d/%d  ·  AP %d" % [int(unit.get("hp", 0)), int(unit.get("max_hp", 0)), int(unit.get("ap", 0))])
	if unit.has("will"): lines.append("WILL %d" % int(unit.will))
	lines.append("FOCUS %d  ·  MEDPACS %d" % [int(unit.get("focus_left", 0)), int(unit.get("medpacs", 0))])
	if unit.has("ammo"): lines.append("AMMO %d/%d" % [int(unit.ammo), int(unit.clip)])
	if g.mission.get("momentum") != null: lines.append("MOMENTUM %d/10" % int(g.mission.momentum))
	var partners: Array[String] = []
	for mate_id in unit.get("bondmates", {}):
		var mate: Dictionary = g.mission.unit_by_id(int(mate_id))
		if not mate.is_empty(): partners.append(str(mate.get("name", "")))
	lines.append("BOND  " + (", ".join(partners) if not partners.is_empty() else "No partner"))
	var statuses: Array[String] = []
	for key in ["hunkered", "overwatch", "concealed", "stunned", "rooted", "disarmed", "wounded"]:
		if bool(unit.get(key, false)): statuses.append(key.capitalize())
	if not statuses.is_empty(): lines.append("STATUS  " + ", ".join(statuses))
	return "\n".join(lines)

func _show_settings() -> void:
	open_card = "settings"
	for child in popup_body.get_children(): child.queue_free()
	popup_body.add_child(_button("BACK", _show_menu))
	popup_body.add_child(preload("res://scripts/graphics_options.gd").new())
	var tips := CheckButton.new(); tips.text = "Tips"; tips.button_pressed = bool(g.Prefs.get_value("tips"))
	tips.toggled.connect(func(value: bool) -> void: g.Prefs.set_value("tips", value)); popup_body.add_child(tips)
	var speed := CheckButton.new(); speed.text = "Fast enemy turns"; speed.button_pressed = RescueSettings.battle_value("fast_enemy")
	speed.toggled.connect(func(value: bool) -> void: RescueSettings.set_battle_value("fast_enemy", value)); popup_body.add_child(speed)
	var auto_select := CheckButton.new(); auto_select.text = "Auto-select next ready unit"
	auto_select.button_pressed = RescueSettings.battle_value("auto_select")
	auto_select.toggled.connect(func(value: bool) -> void: RescueSettings.set_battle_value("auto_select", value)); popup_body.add_child(auto_select)
