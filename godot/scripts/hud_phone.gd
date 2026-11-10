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
var action_art: Control
var ability_buttons: Array[Button] = []
var end_confirm := false
var end_button: Button
var end_pulse: Tween
var detail_scroll
var last_unit_id := -1
var last_unit_ap := -1
var momentum_pips: Label
var momentum_strike: Button
var momentum_row: HBoxContainer
var momentum_plate: Control
var last_chain_momentum := -1
var unit_plate: PanelContainer
var camera_rail: VBoxContainer
var camera_art: Control
var unit_portrait: TextureRect
var portrait_path := ""
var plate_touch_start := Vector2.ZERO
var plate_swiping := false

func setup(game, night_hud, root: Control, top: Control, left: Control, right: Control, bottom: Control, abilities: HFlowContainer) -> void:
	g = game; night = night_hud
	top.hide(); left.hide(); right.hide(); bottom.hide()
	overlay = Control.new(); overlay.name = "PhoneBattleHUD"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(overlay)
	var physical := DisplayServer.window_get_size()
	var safe := preload("res://scripts/phone_layout.gd").safe_margins(root.size)
	overlay.offset_left = clampf(safe.x, 0.0, root.size.x * 0.2)
	overlay.offset_top = clampf(safe.y, 0.0, root.size.y * 0.2)
	overlay.offset_right = -clampf(safe.z, 0.0, root.size.x * 0.2)
	overlay.offset_bottom = -clampf(safe.w, 0.0, root.size.y * 0.2)
	var safe_size := root.size - Vector2(safe.x + safe.z, safe.y + safe.w)
	var layout: Dictionary = preload("res://scripts/hud_phone_layout.gd").boxes(safe_size)
	var physical_height := float(physical.y) if physical.y > 0 else float(g.get_tree().root.size.y)
	var visual_height := 44.0 * root.size.y / maxf(1.0, physical_height)
	var top_back := ColorRect.new(); top_back.name = "PhoneTopBackground"
	top_back.color = Color("101b26ee"); top_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preload("res://scripts/hud_phone_layout.gd").place(top_back, Rect2(0, 0, safe_size.x, visual_height))
	overlay.add_child(top_back)
	var strip := PanelContainer.new(); strip.name = "PhoneTopStrip"
	preload("res://scripts/hud_phone_layout.gd").place(strip, layout.header)
	var strip_style: StyleBoxFlat = night.panel_style(); strip_style.set_content_margin_all(0)
	strip_style.bg_color = Color.TRANSPARENT; strip_style.border_color = Color.TRANSPARENT
	strip.add_theme_stylebox_override("panel", strip_style); overlay.add_child(strip)
	var heading := HBoxContainer.new(); heading.add_theme_constant_override("separation", 3); strip.add_child(heading)
	g.objective_label.reparent(heading); g.objective_label.add_theme_font_size_override("font_size", 12)
	g.objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.objective_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	g.objective_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	end_button = _button("END TURN", _end_turn); end_button.name = "PhoneEndTurn"
	end_button.custom_minimum_size = Vector2(96, 44); heading.add_child(end_button)
	var menu := _button("MENU" if preload("res://scripts/phone_layout.gd").touch_device() else "☰", _show_menu); menu.name = "PhoneMenu"
	menu.custom_minimum_size = Vector2(44, 44); heading.add_child(menu)
	for button in [end_button, menu]:
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	unit_plate = PanelContainer.new(); unit_plate.name = "UnitPlate"
	preload("res://scripts/hud_phone_layout.gd").place(unit_plate, layout.plate)
	var plate_style: StyleBoxFlat = night.panel_style(); plate_style.set_content_margin_all(0)
	unit_plate.add_theme_stylebox_override("panel", plate_style); overlay.add_child(unit_plate)
	var plate_row := HBoxContainer.new(); plate_row.add_theme_constant_override("separation", 0); unit_plate.add_child(plate_row)
	unit_portrait = left.find_children("*", "TextureRect", true, false)[0] as TextureRect
	unit_portrait.name = "UnitPortrait"; unit_portrait.reparent(plate_row)
	unit_portrait.texture = load("res://assets/story/portraits14/satele.png")
	unit_portrait.custom_minimum_size = Vector2(52, 52)
	unit_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	unit_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	unit_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unit_card = _button("UNIT", _toggle.bind("unit")); unit_card.name = "UnitCard"
	unit_card.custom_minimum_size = Vector2(54, 40)
	unit_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit_card.add_theme_font_size_override("font_size", 11); plate_row.add_child(unit_card)
	unit_plate.gui_input.connect(_plate_input)
	for direction in [-1, 1]:
		var arrow := _button("‹" if direction < 0 else "›", _cycle_unit.bind(direction))
		arrow.name = "UnitPrevious" if direction < 0 else "UnitNext"
		arrow.custom_minimum_size = Vector2(37, 40); plate_row.add_child(arrow)
		for state in ["normal", "hover", "pressed", "disabled"]:
			arrow.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	camera_rail = VBoxContainer.new(); camera_rail.name = "CameraRail"
	camera_rail.add_theme_constant_override("separation", 0)
	preload("res://scripts/hud_phone_layout.gd").place(camera_rail, layout.camera); overlay.add_child(camera_rail)
	for entry in [["↶", -1], ["⌖", 0], ["↷", 1]]:
		var button := _button(str(entry[0]), func() -> void:
			if int(entry[1]) == 0: g._recenter()
			else: g._rotate_camera(float(entry[1]) * PI / 2.0))
		button.name = "CameraCenter" if int(entry[1]) == 0 else "CameraRotateLeft" if int(entry[1]) < 0 else "CameraRotateRight"
		button.text = ""
		button.custom_minimum_size = Vector2(44, 44); camera_rail.add_child(button)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	camera_art = preload("res://scripts/hud_phone_camera_art.gd").new()
	camera_art.name = "CameraArt"
	preload("res://scripts/hud_phone_layout.gd").place(camera_art, layout.camera)
	overlay.add_child(camera_art)
	target_card = _button("TARGET", _toggle.bind("target")); target_card.name = "TargetCard"
	target_card.visible = false; overlay.add_child(target_card)
	var tray := PanelContainer.new(); tray.name = "AbilityTray"; ability_tray = tray
	preload("res://scripts/hud_phone_layout.gd").place(tray, layout.tray)
	var tray_style: StyleBoxFlat = night.panel_style(); tray_style.set_content_margin_all(0)
	tray.add_theme_stylebox_override("panel", tray_style); overlay.add_child(tray)
	var tray_box := VBoxContainer.new(); tray_box.add_theme_constant_override("separation", 0); tray.add_child(tray_box)
	var readout := HBoxContainer.new(); readout.add_theme_constant_override("separation", 4); tray_box.add_child(readout)
	momentum_plate = Control.new(); momentum_plate.name = "MomentumPlate"
	momentum_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	momentum_plate.custom_minimum_size = Vector2(82, 13); readout.add_child(momentum_plate)
	momentum_pips = night.label("MOM 0/3" if preload("res://scripts/phone_layout.gd").touch_device() else "○ ○ ○", 11, Color("e9ca83")); momentum_pips.name = "ChainPips"
	momentum_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	momentum_pips.position = Vector2(2, 0); momentum_plate.add_child(momentum_pips)
	action_name = night.label("Choose an action", 11, Color("e9ca83"))
	action_name.name = "AbilityReadout"; action_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_name.custom_minimum_size.y = 13; readout.add_child(action_name)
	momentum_row = HBoxContainer.new(); momentum_row.name = "ChainMomentum"
	momentum_row.visible = false; tray_box.add_child(momentum_row)
	var scroll := preload("res://scripts/touch_scroll.gd").new(); scroll.name = "Abilities"
	ability_scroll = scroll; scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.custom_minimum_size.y = 40; tray_box.add_child(scroll)
	scroll.get_h_scroll_bar().modulate.a = 0.0
	var track := HBoxContainer.new(); track.add_theme_constant_override("separation", 4); scroll.add_child(track)
	for node in abilities.get_children():
		var button: Button = node
		button.reparent(track); button.custom_minimum_size = Vector2(44, 40)
		ability_buttons.append(button)
		button.set_meta("graphics_custom_minimum_size", Vector2(44, 40))
		button.set_meta("shared_phone_art", true)
		button.set("compact", true); button.set("phone_icon", true)
		button.button_down.connect(_show_ability.bind(button))
		button.pressed.connect(_show_ability.bind(button))
		button.gui_input.connect(_ability_input.bind(button))
	momentum_strike = _button("STRIKE" if preload("res://scripts/phone_layout.gd").touch_device() else "✦\nSTRIKE", _claim_strike)
	momentum_strike.name = "MomentumStrike"; momentum_strike.custom_minimum_size = Vector2(44, 40)
	momentum_strike.add_theme_font_size_override("font_size", 11); track.add_child(momentum_strike)
	more_button = _button("MORE", _toggle.bind("more")); more_button.custom_minimum_size = Vector2(44, 40); track.add_child(more_button)
	for button in [momentum_strike, more_button]:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var round_style := StyleBoxFlat.new()
			round_style.bg_color = Color("12303a") if state != "disabled" else Color("28333c")
			round_style.border_color = Color("a8f3bb") if button == momentum_strike and state != "disabled" else Color("be9d5b")
			round_style.set_border_width_all(1); round_style.set_corner_radius_all(18)
			button.add_theme_stylebox_override(state, round_style)
	action_art = preload("res://scripts/hud_phone_action_art.gd").new()
	action_art.name = "PhoneActionArt"; action_art.buttons = ability_buttons
	preload("res://scripts/hud_phone_layout.gd").place(action_art, layout.tray)
	overlay.add_child(action_art)
	popup = PanelContainer.new(); popup.name = "PhoneDetails"; popup.visible = false
	popup.anchor_left = 0.5; popup.anchor_right = 0.5; popup.anchor_bottom = 1.0
	var popup_half := minf(250.0, (safe_size.x - 16.0) * 0.5)
	popup.offset_left = -popup_half; popup.offset_right = popup_half; popup.offset_top = 48; popup.offset_bottom = -96
	popup.add_theme_stylebox_override("panel", night.panel_style()); overlay.add_child(popup)
	detail_scroll = preload("res://scripts/touch_scroll.gd").new(); detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	popup.add_child(detail_scroll)
	popup_body = VBoxContainer.new(); popup_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_body.add_theme_constant_override("separation", 8); detail_scroll.add_child(popup_body)

func _button(title: String, action: Callable) -> Button:
	var button := Button.new(); button.text = title; button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 14)
	button.custom_minimum_size = Vector2(44, 56 if title in ["END TURN", "MOVE", "FIRE", "OVERWATCH", "CANCEL"] else 44); button.pressed.connect(action)
	return button

func _show_ability(button: Button) -> void:
	action_name.text = button.tooltip_text

func _ability_input(event: InputEvent, button: Button) -> void:
	if event is InputEventScreenTouch and event.pressed: _show_ability(button)
	if event is InputEventScreenDrag:
		if g.camera_tween != null and g.camera_tween.is_running(): g.camera_tween.kill()
		var right: Vector3 = g.camera.global_basis.x
		var forward: Vector3 = -g.camera.global_basis.z; forward.y = 0.0; forward = forward.normalized()
		g.pivot += (-right * event.relative.x + forward * event.relative.y) * g.zoom * 0.0015
		g._update_camera()

func _plate_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			plate_touch_start = event.position; plate_swiping = true
		elif plate_swiping:
			plate_swiping = false
			if absf(event.position.x - plate_touch_start.x) >= 65.0:
				_cycle_unit(-1 if event.position.x > plate_touch_start.x else 1)

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

func _claim_strike() -> void:
	var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
	if preload("res://scripts/ability_chains.gd").claim_momentum_strike(g.mission, actor):
		g._refresh()

func refresh(from_game: bool = false) -> void:
	if overlay == null: return
	var pips: int = clampi(int(g.mission.chain_momentum), 0, 3)
	var used_this_turn: bool = int(g.mission.chain_strike_used_turn) == int(g.mission.turn)
	momentum_row.visible = false
	momentum_plate.visible = true
	momentum_pips.text = "MOM %d/3" % pips if preload("res://scripts/phone_layout.gd").touch_device() else "MOM " + "●".repeat(pips) + "○".repeat(3 - pips)
	momentum_strike.visible = true
	momentum_strike.disabled = pips < 3 or used_this_turn or g.mission.phase != "player"
	if pips != last_chain_momentum:
		last_chain_momentum = pips
		momentum_pips.pivot_offset = momentum_pips.size * 0.5
		var pulse: Tween = g.create_tween()
		pulse.tween_property(momentum_pips, "scale", Vector2(1.10, 1.10), 0.12)
		pulse.tween_property(momentum_pips, "scale", Vector2.ONE, 0.20)
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
	action_art.queue_redraw()
	if g.warning_label.text == "" and not end_confirm and g.path_label.text == "":
		var selected_ability: Dictionary = g.mission.abilities.get(g.action, {})
		if not selected_ability.is_empty():
			var effect := "1 AP; dash 2 AP" if g.action == "move" else "weapon damage" if g.action == "shoot" else str(selected_ability.get("effect", "action")).replace("_", " ")
			action_name.text = "%s  ·  %s" % [str(selected_ability.get("name", g.action)).to_upper(), effect]
	var unit: Dictionary = g.mission.unit_by_id(g.selected_id)
	var portrait_name := str(unit.get("name", "")).to_lower().replace(" ", "_")
	var candidate := "res://assets/story/portraits14/%s.png" % portrait_name
	var wanted := candidate if ResourceLoader.exists(candidate) else "res://assets/story/portraits14/jace.png" if str(unit.get("class_name", "")).to_lower().contains("soldier") else "res://assets/portraits/jedi/satele.png"
	if wanted != portrait_path:
		portrait_path = wanted; unit_portrait.texture = load(wanted)
	var tag_glyphs: Array[String] = []
	for tag in preload("res://scripts/hud18_tags.gd").shown(unit.get("combo_tags", {})):
		tag_glyphs.append(str(preload("res://scripts/hud18_icon.gd").GLYPHS.get(tag, tag)))
	var hp: int = int(unit.get("hp", 0))
	var ap: int = clampi(int(unit.get("ap", 0)), 0, 2)
	if preload("res://scripts/phone_layout.gd").touch_device():
		unit_card.text = "%s\nHP %d/%d\nAP %s" % [str(unit.get("name", "UNIT")), hp, int(unit.get("max_hp", 0)), g.hud_controls.ap_pips(unit)]
	else:
		var hp_pips := "▮".repeat(mini(hp, 7)) + "▯".repeat(mini(maxi(0, int(unit.get("max_hp", 0)) - hp), 7))
		unit_card.text = "%s\n%d %s\n%s %s %s" % [str(unit.get("name", "UNIT")), hp, hp_pips, g.hud_controls.ap_pips(unit), "●".repeat(ap) + "○".repeat(2 - ap), " ".join(tag_glyphs)]
	var target: Dictionary = g.mission.unit_by_id(g.target_id)
	target_card.text = "%s  %s  %s" % [str(target.get("name", "TARGET")), g.hit_big_label.text, "v" if preload("res://scripts/phone_layout.gd").touch_device() else "▾"]
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
			var item := _button("%s %s  ·  %s AP%s" % [button.display_name, preload("res://scripts/hud18_icon.gd").marks(g.mission.abilities.get(mode, {})), button.cost, "  ·  %d TURN CD" % button.cooldown if button.cooldown > 0 else ""], func() -> void: g._choose_action(mode); _close())
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
	var primary_limit := mini(4, maxi(3, int(floor((ability_tray.size.x - 8.0) / 48.0)) - 2))
	last_unit_id = g.selected_id; last_unit_ap = available
	if from_game:
		for button in ability_buttons: button.set_meta("battle12_available", button.visible and not button.disabled)
	var primary: Array[String] = []
	for mode in ["move", "shoot", "strike", "push", "overwatch", "reload", "hunker", "medpac"]:
		if primary.size() >= primary_limit: break
		for button in ability_buttons:
			if button.ability_id == mode and bool(button.get_meta("battle12_available", false)):
				primary.append(mode); break
	for button in ability_buttons:
		if primary.size() >= primary_limit: break
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
