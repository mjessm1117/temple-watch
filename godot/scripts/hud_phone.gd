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
var more_button: Button
var ability_tray: PanelContainer
var ability_scroll
var ability_buttons: Array[Button] = []
var end_confirm := false
var end_button: Button
var end_pulse: Tween
var detail_scroll
var last_unit_id := -1
var last_unit_ap := -1

func setup(game, night_hud, root: Control, top: Control, left: Control, right: Control, bottom: Control, abilities: HFlowContainer) -> void:
	g = game; night = night_hud
	top.hide(); left.hide(); right.hide(); bottom.hide()
	overlay = Control.new(); overlay.name = "PhoneBattleHUD"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(overlay)
	var physical := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if physical.x > 0 and physical.y > 0 and safe.size.x > 0 and safe.size.y > 0:
		var scale := Vector2(root.size.x/float(physical.x),root.size.y/float(physical.y))
		overlay.offset_left = clampf(float(safe.position.x)*scale.x,0.0,root.size.x*0.2)
		overlay.offset_top = clampf(float(safe.position.y)*scale.y,0.0,root.size.y*0.2)
		overlay.offset_right = -clampf(float(physical.x-safe.end.x)*scale.x,0.0,root.size.x*0.2)
		overlay.offset_bottom = -clampf(float(physical.y-safe.end.y)*scale.y,0.0,root.size.y*0.2)
	var strip := PanelContainer.new(); strip.anchor_right = 1.0; strip.offset_bottom = 108
	var strip_style: StyleBoxFlat = night.panel_style(); strip_style.set_content_margin_all(2)
	strip_style.content_margin_top = 0; strip_style.content_margin_bottom = 0
	strip.add_theme_stylebox_override("panel", strip_style); overlay.add_child(strip)
	var rows := VBoxContainer.new(); rows.add_theme_constant_override("separation", 8); strip.add_child(rows)
	var heading := HBoxContainer.new(); heading.add_theme_constant_override("separation", 8); rows.add_child(heading)
	g.objective_label.reparent(heading); g.objective_label.add_theme_font_size_override("font_size", 12)
	g.objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.objective_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	g.objective_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	end_button = _button("END TURN", _end_turn); end_button.name = "PhoneEndTurn"
	end_button.custom_minimum_size = Vector2(110, 56); heading.add_child(end_button)
	var controls := HBoxContainer.new(); controls.add_theme_constant_override("separation", 8); rows.add_child(controls)
	unit_card = _button("UNIT", _toggle.bind("unit")); unit_card.name = "UnitCard"
	unit_card.custom_minimum_size = Vector2(105 if physical.x < 500 else 155, 44)
	unit_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit_card.add_theme_font_size_override("font_size", 14); controls.add_child(unit_card)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var card_style: StyleBox = unit_card.get_theme_stylebox(state).duplicate()
		card_style.content_margin_top = 0; card_style.content_margin_bottom = 0
		unit_card.add_theme_stylebox_override(state, card_style)
	controls.add_child(_button("◀", func() -> void: _cycle_unit(-1)))
	controls.add_child(_button("▶", func() -> void: _cycle_unit(1)))
	if physical.x >= 500: controls.add_child(_button("CENTER", g._recenter))
	controls.add_child(_button("☰", _show_menu))
	target_card = _button("TARGET", _toggle.bind("target")); target_card.name = "TargetCard"
	target_card.visible = false; overlay.add_child(target_card)
	var tray := PanelContainer.new(); tray.name = "AbilityTray"
	ability_tray = tray
	tray.anchor_left = 0.5; tray.anchor_right = 0.5
	tray.anchor_top = 1.0; tray.anchor_bottom = 1.0
	tray.offset_left = -minf(340.0, root.size.x * 0.47)
	tray.offset_right = minf(340.0, root.size.x * 0.47)
	tray.offset_top = -80
	var tray_style: StyleBoxFlat = night.panel_style(); tray_style.set_content_margin_all(2)
	tray.add_theme_stylebox_override("panel", tray_style); overlay.add_child(tray)
	var tray_box := VBoxContainer.new(); tray_box.add_theme_constant_override("separation", 0); tray.add_child(tray_box)
	action_name = night.label("Tap or hold an ability for its name", 12, Color("e9ca83"))
	action_name.custom_minimum_size.y = 17; tray_box.add_child(action_name)
	var scroll := preload("res://scripts/touch_scroll.gd").new(); scroll.name = "Abilities"
	ability_scroll = scroll
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.custom_minimum_size.y = 56; tray_box.add_child(scroll)
	scroll.get_h_scroll_bar().modulate.a = 0.0
	var track := HBoxContainer.new(); track.add_theme_constant_override("separation", 8); scroll.add_child(track)
	for node in abilities.get_children():
		var button: Button = node
		button.reparent(track); button.custom_minimum_size = Vector2(83, 56)
		ability_buttons.append(button)
		button.set_meta("graphics_custom_minimum_size", Vector2(83, 56))
		button.set("compact", true); button.button_down.connect(_show_ability.bind(button))
		button.pressed.connect(_show_ability.bind(button))
		button.gui_input.connect(_ability_input.bind(button))
	more_button = _button("MORE ▴", _toggle.bind("more")); more_button.custom_minimum_size = Vector2(84, 55); track.add_child(more_button)
	popup = PanelContainer.new(); popup.name = "PhoneDetails"; popup.visible = false
	popup.anchor_left = 0.5; popup.anchor_right = 0.5; popup.anchor_bottom = 1.0
	var popup_half := minf(250.0, (root.size.x - 16.0) * 0.5)
	popup.offset_left = -popup_half; popup.offset_right = popup_half; popup.offset_top = 96; popup.offset_bottom = -80
	popup.add_theme_stylebox_override("panel", night.panel_style()); overlay.add_child(popup)
	detail_scroll = preload("res://scripts/touch_scroll.gd").new(); detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	popup.add_child(detail_scroll)
	popup_body = VBoxContainer.new(); popup_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_body.add_theme_constant_override("separation", 8)
	detail_scroll.add_child(popup_body)

func _button(title: String, action: Callable) -> Button:
	var button := Button.new(); button.text = title; button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 14)
	button.custom_minimum_size = Vector2(44, 56 if title in ["END TURN", "MOVE", "FIRE", "OVERWATCH", "CANCEL"] else 44); button.pressed.connect(action)
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

func _cycle_unit(direction: int) -> void:
	var id: int = preload("res://scripts/input_controls.gd").next_squad(g.mission, g.selected_id, direction)
	if id >= 0: g._select(id)

func _end_turn() -> void:
	if not end_confirm:
		end_confirm = true
		action_name.text = "End the squad turn? Tap END TURN again."
		return
	end_confirm = false
	g._request_end_turn()
	if g.end_turn_armed: g._request_end_turn()

func _close() -> void:
	open_card = ""; refresh()

func refresh(from_game: bool = false) -> void:
	if overlay == null: return
	var all_spent: bool = g.mission.phase == "player" and g.mission.result == "" and not g.mission.living("player").is_empty()
	for member in g.mission.living("player"):
		if int(member.ap) > 0: all_spent = false; break
	if all_spent and (end_pulse == null or not end_pulse.is_running()):
		end_pulse = g.create_tween().set_loops()
		end_pulse.tween_property(end_button, "modulate", Color("ffe19a"), 0.55).set_trans(Tween.TRANS_SINE)
		end_pulse.tween_property(end_button, "modulate", Color.WHITE, 0.55).set_trans(Tween.TRANS_SINE)
	elif not all_spent and end_pulse != null:
		end_pulse.kill(); end_pulse = null; end_button.modulate = Color.WHITE
	if g.warning_label.text.contains("TAB / SHIFT+TAB"): action_name.text = "Tap a target · CONFIRM FIRE · CANCEL"
	elif g.warning_label.text != "": action_name.text = g.warning_label.text
	elif end_confirm: action_name.text = "End the squad turn? Tap END TURN again."
	elif all_spent: action_name.text = "Squad spent · END TURN"
	elif g.path_label.text != "": action_name.text = g.path_label.text.get_slice("  •  COVER",0)
	elif g.action == "move": action_name.text = "Blue: 1 action  ·  Amber: DASH ends turn"
	else: action_name.text = "Choose an action · tap the map to preview"
	_update_actions(from_game)
	var unit: Dictionary = g.mission.unit_by_id(g.selected_id)
	unit_card.text = "%s\nHP %s  AP %s  ▾" % [str(unit.get("name", "UNIT")), str(unit.get("hp", "?")), g.hud_controls.ap_pips(unit)]
	var target: Dictionary = g.mission.unit_by_id(g.target_id)
	target_card.text = "%s  %s  ▾" % [str(target.get("name", "TARGET")), g.hit_big_label.text]
	popup.visible = open_card != ""
	if open_card == "": return
	if open_card == "settings": return
	if detail_scroll.touch_dragging: return
	var saved_scroll: int = detail_scroll.scroll_vertical
	for child in popup_body.get_children(): child.queue_free()
	if open_card == "more":
		popup_body.add_child(night.label("MORE ACTIONS", 16, Color("efd49b")))
		for button in ability_buttons:
			if button.visible or not bool(button.get_meta("battle12_available", false)) or button.ability_id == "": continue
			var mode: String = button.ability_id
			var item := _button("%s  ·  %s AP%s" % [button.display_name, button.cost, "  ·  %d TURN CD" % button.cooldown if button.cooldown > 0 else ""], func() -> void: g._choose_action(mode); _close())
			item.disabled = button.disabled; popup_body.add_child(item)
	elif open_card == "unit":
		popup_body.add_child(night.label("SQUAD  ·  tap a name to select", 14, Color("efd49b")))
		var squad := HFlowContainer.new(); squad.add_theme_constant_override("h_separation", 8); squad.add_theme_constant_override("v_separation", 8); popup_body.add_child(squad)
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
	detail_scroll.set_deferred("scroll_vertical", saved_scroll)

func _update_actions(from_game: bool) -> void:
	var unit: Dictionary = g.mission.unit_by_id(g.selected_id)
	var available: int = int(unit.get("ap", 0))
	if from_game and ability_scroll != null and not ability_scroll.touch_dragging and (last_unit_id != g.selected_id or last_unit_ap != available):
		ability_scroll.set_deferred("scroll_horizontal", 0)
	last_unit_id = g.selected_id; last_unit_ap = available
	if from_game:
		for button in ability_buttons: button.set_meta("battle12_available", button.visible and not button.disabled)
	var primary: Array[String] = []
	for mode in ["move", "shoot", "strike", "push", "overwatch", "reload", "hunker", "medpac"]:
		if primary.size() >= 5: break
		for button in ability_buttons:
			if button.ability_id == mode and bool(button.get_meta("battle12_available", false)):
				primary.append(mode); break
	for button in ability_buttons:
		if primary.size() >= 5: break
		if bool(button.get_meta("battle12_available", false)) and button.ability_id not in primary:
			primary.append(button.ability_id)
	for button in ability_buttons:
		button.visible = bool(button.get_meta("battle12_available", false)) and button.ability_id in primary
	var overflow := 0
	for button in ability_buttons:
		if bool(button.get_meta("battle12_available", false)) and not button.visible: overflow += 1
	more_button.visible = overflow > 0

func _unit_details(unit: Dictionary) -> String:
	var lines: Array[String] = [str(unit.get("name", "UNIT")), str(unit.get("class_name", "Jedi"))]
	lines.append("HP %d/%d  ·  AP %d" % [int(unit.get("hp", 0)), int(unit.get("max_hp", 0)), int(unit.get("ap", 0))])
	if unit.has("will"): lines.append("WILL %d" % int(unit.will))
	lines.append("FOCUS %d  ·  MEDPACS %d" % [int(unit.get("focus_left", 0)), int(unit.get("medpacs", 0))])
	if unit.has("ammo"): lines.append("AMMO %d/%d" % [int(unit.ammo), int(unit.clip)])
	if g.mission.get("momentum") != null: lines.append("MOMENTUM %d/10" % int(g.mission.momentum))
	var cooldowns: Dictionary = unit.get("cooldowns", {})
	for ability in cooldowns:
		var remaining: int = maxi(0, int(cooldowns[ability]) - g.mission.turn)
		if remaining > 0: lines.append("%s  ·  %d TURN CD" % [str(g.mission.abilities.get(ability, {}).get("name", ability)).to_upper(), remaining])
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
	tips.custom_minimum_size.y = 44; tips.add_theme_font_size_override("font_size", 14)
	tips.toggled.connect(func(value: bool) -> void: g.Prefs.set_value("tips", value)); popup_body.add_child(tips)
	var speed := CheckButton.new(); speed.text = "Fast enemy turns"; speed.button_pressed = RescueSettings.battle_value("fast_enemy")
	speed.custom_minimum_size.y = 44; speed.add_theme_font_size_override("font_size", 14)
	speed.toggled.connect(func(value: bool) -> void: RescueSettings.set_battle_value("fast_enemy", value)); popup_body.add_child(speed)
	var auto_select := CheckButton.new(); auto_select.text = "Auto-select next ready unit"
	auto_select.custom_minimum_size.y = 44; auto_select.add_theme_font_size_override("font_size", 14)
	auto_select.button_pressed = RescueSettings.battle_value("auto_select")
	auto_select.toggled.connect(func(value: bool) -> void: RescueSettings.set_battle_value("auto_select", value)); popup_body.add_child(auto_select)
