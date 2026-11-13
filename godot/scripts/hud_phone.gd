extends RefCounted
## Compact battle controls. The full desktop HUD remains available at wide sizes.
var g
var night
var overlay: Control
var root_control: Control
var unit_card: Button
var unit_card_readout: Label
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
var end_confirm_at_ms := -100000
var end_button: Button
var menu_button: Button
var end_pulse: Tween
var detail_scroll
var last_unit_id := -1
var last_unit_ap := -1
var momentum_pips: Label
var momentum_display: Label
var momentum_strike: Button
var momentum_row: HBoxContainer
var momentum_plate: Control
var last_chain_momentum := -1
var unit_plate: PanelContainer
var camera_rail: VBoxContainer
var camera_art: Control
var unit_portrait: TextureRect
var unit_plate_row: HBoxContainer
var portrait_frame: PanelContainer
var portrait_path := ""
var plate_touch_start := Vector2.ZERO
var plate_swiping := false
var threat_chip: Button
var objective_summary: Label
var opening_contact_seen := false
var group_reveal: Label
var radio_until := 0
var top_heading: HBoxContainer
var odds_plate: PanelContainer
var odds_title: Label
var odds_hit: Label
var odds_modifiers: Label
var odds_scroll: ScrollContainer
var odds_badge: Label
var alerts: Control
var enemy_card: PanelContainer
var enemy_text: Label
var deferred_radio: Array[Dictionary] = []
var deferred_story_comms: Dictionary = {}
var enemy_was_active := false
var feedback = preload("res://scripts/w24_hud_feedback.gd").new()
var last_threat: Dictionary = {}
const Targeting22 = preload("res://scripts/combat_targeting.gd")
const Threat22 = preload("res://scripts/decision22_threat.gd")
const AbilityHUD = preload("res://scripts/w30d_ability_hud.gd")
func setup(game, night_hud, root: Control, top: Control, left: Control, right: Control, bottom: Control, abilities: HFlowContainer) -> void:
	g = game; night = night_hud
	root_control = root
	top.hide(); left.hide(); right.hide(); bottom.hide()
	overlay = Control.new(); overlay.name = "PhoneBattleHUD"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(overlay)
	var physical := DisplayServer.window_get_size()
	var safe := preload("res://scripts/phone_layout.gd").safe_margins(root.size)
	safe = Vector4(maxf(0.0, safe.x), maxf(0.0, safe.y), maxf(0.0, safe.z), maxf(0.0, safe.w))
	overlay.offset_left = clampf(safe.x, 0.0, root.size.x * 0.2)
	overlay.offset_top = clampf(safe.y, 0.0, root.size.y * 0.2)
	overlay.offset_right = -clampf(safe.z, 0.0, root.size.x * 0.2)
	overlay.offset_bottom = -clampf(safe.w, 0.0, root.size.y * 0.2)
	var safe_size := root.size - Vector2(safe.x + safe.z, safe.y + safe.w)
	var layout: Dictionary = preload("res://scripts/hud_phone_layout.gd").boxes(safe_size)
	var logical_height := float(preload("res://scripts/phone_layout.gd").logical_size(physical).y) if physical.y > 0 else float(g.get_tree().root.size.y)
	var visual_height := 44.0 * root.size.y / maxf(1.0, logical_height)
	var top_back := ColorRect.new(); top_back.name = "PhoneTopBackground"
	top_back.color = preload("res://scripts/campaign/ui.gd").SURFACE; top_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preload("res://scripts/hud_phone_layout.gd").place(top_back, Rect2(0, 0, safe_size.x, visual_height))
	overlay.add_child(top_back)
	var strip := PanelContainer.new(); strip.name = "PhoneTopStrip"
	preload("res://scripts/hud_phone_layout.gd").place(strip, layout.header)
	var strip_style: StyleBoxFlat = night.panel_style(); strip_style.set_content_margin_all(0)
	strip_style.content_margin_left = 8; strip_style.content_margin_right = 8
	strip_style.bg_color = Color.TRANSPARENT; strip_style.border_color = Color.TRANSPARENT
	strip.add_theme_stylebox_override("panel", strip_style); overlay.add_child(strip)
	var heading := HBoxContainer.new(); top_heading = heading
	heading.add_theme_constant_override("separation", 3); strip.add_child(heading)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.objective_label.reparent(heading); g.objective_label.add_theme_font_size_override("font_size", 14)
	g.objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.objective_label.custom_minimum_size.y = 44
	g.objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	g.objective_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	g.objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	threat_chip = _button("", _toggle.bind("threat")); threat_chip.name = "EndThreatChip"
	threat_chip.custom_minimum_size = Vector2(44, 44)
	var threat_icon: Label = night.label("!", 20, Color("f2d99a")); threat_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	threat_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); threat_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; threat_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; threat_chip.add_child(threat_icon)
	var threat_style: StyleBoxFlat = night.panel_style(); threat_style.set_content_margin_all(0)
	threat_chip.add_theme_stylebox_override("normal", threat_style); overlay.add_child(threat_chip)
	objective_summary = night.label("", 12, Color("e9ca83")); objective_summary.name = "PhoneObjectiveSummary"
	objective_summary.mouse_filter = Control.MOUSE_FILTER_STOP
	objective_summary.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventScreenTouch and event.pressed or event is InputEventMouseButton and event.pressed: _toggle("objective"))
	objective_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective_summary.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	objective_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay.add_child(objective_summary)
	group_reveal = night.label("", 12, Color("f2d99a")); group_reveal.name = "PhoneGroupReveal"
	group_reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group_reveal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	group_reveal.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	group_reveal.hide(); overlay.add_child(group_reveal)
	var reveal_timer := Timer.new(); reveal_timer.wait_time = 0.1
	reveal_timer.timeout.connect(_update_group_reveal)
	overlay.add_child(reveal_timer); reveal_timer.start()
	end_button = _button("END TURN", _end_turn); end_button.name = "PhoneEndTurn"
	end_button.custom_minimum_size = Vector2(88, 44); overlay.add_child(end_button)
	heading.add_theme_constant_override("separation", 8)
	var menu := _button("MENU" if preload("res://scripts/phone_layout.gd").touch_device() else "☰", _show_menu); menu.name = "PhoneMenu"; menu_button = menu
	menu.custom_minimum_size = Vector2(44, 44); heading.add_child(menu)
	for button in [menu]:
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var end_style: StyleBoxFlat = night.panel_style()
	end_style.border_color = Color("e9ca83")
	end_style.set_border_width_all(2)
	end_button.add_theme_stylebox_override("normal", end_style)
	end_button.add_theme_stylebox_override("hover", end_style)
	end_button.add_theme_stylebox_override("pressed", end_style)
	end_button.add_theme_stylebox_override("focus", end_style)
	end_button.toggle_mode = true
	end_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	end_button.button_down.connect(_end_turn)
	var armed_style: StyleBoxFlat = end_style.duplicate()
	armed_style.bg_color = Color("70521f")
	end_button.add_theme_stylebox_override("pressed", armed_style)
	unit_plate = PanelContainer.new(); unit_plate.name = "UnitPlate"
	preload("res://scripts/hud_phone_layout.gd").place(unit_plate, layout.plate)
	var plate_style: StyleBoxFlat = night.panel_style(); plate_style.set_content_margin_all(0)
	unit_plate.add_theme_stylebox_override("panel", plate_style); overlay.add_child(unit_plate)
	var plate_row := HBoxContainer.new(); unit_plate_row = plate_row
	plate_row.add_theme_constant_override("separation", 8); unit_plate.add_child(plate_row)
	portrait_frame = PanelContainer.new(); portrait_frame.name = "PhonePortraitTopLeft"
	var portrait_style: StyleBoxFlat = night.panel_style(); portrait_style.set_content_margin_all(0)
	portrait_frame.add_theme_stylebox_override("panel", portrait_style)
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	portrait_frame.gui_input.connect(_plate_input)
	portrait_frame.hide(); overlay.add_child(portrait_frame)
	unit_portrait = left.find_children("*", "TextureRect", true, false)[0] as TextureRect
	unit_portrait.name = "UnitPortrait"; unit_portrait.reparent(plate_row)
	unit_portrait.texture = load("res://assets/story/portraits14/satele.png")
	unit_portrait.custom_minimum_size = Vector2(52, 52)
	unit_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	unit_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	unit_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unit_card = _button("UNIT", _toggle.bind("unit")); unit_card.name = "UnitCard"
	unit_card.custom_minimum_size = Vector2(48, 44)
	unit_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit_card.add_theme_font_size_override("font_size", 12); plate_row.add_child(unit_card)
	unit_card.clip_text = true
	unit_card.clip_contents = true
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		unit_card.add_theme_color_override(color_name, Color.TRANSPARENT)
	unit_card_readout = night.label("UNIT", 12, Color("edf3f4"))
	unit_card_readout.name = "UnitCardReadout"
	unit_card_readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unit_card_readout.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	unit_card_readout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	unit_card_readout.offset_left = 2
	unit_card.add_child(unit_card_readout)
	for state in ["normal", "hover", "pressed", "disabled"]:
		unit_card.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	unit_plate.gui_input.connect(_plate_input)
	for direction in [-1, 1]:
		var arrow := _button("<" if direction < 0 else ">", _cycle_unit.bind(direction))
		arrow.name = "UnitPrevious" if direction < 0 else "UnitNext"
		arrow.custom_minimum_size = Vector2(44, 44); plate_row.add_child(arrow)
		if direction < 0: arrow.hide()
		for state in ["normal", "hover", "pressed", "disabled"]:
			arrow.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	camera_rail = VBoxContainer.new(); camera_rail.name = "CameraRail"
	camera_rail.add_theme_constant_override("separation", 8)
	preload("res://scripts/hud_phone_layout.gd").place(camera_rail, Rect2(layout.camera.position - Vector2(4, 0), layout.camera.size)); overlay.add_child(camera_rail)
	for entry in [["L", -1], ["C", 0], ["R", 1]]:
		var button := _button(str(entry[0]), func() -> void:
			if int(entry[1]) == 0: g._recenter()
			else: g._rotate_camera(float(entry[1]) * PI / 2.0))
		button.name = "CameraCenter" if int(entry[1]) == 0 else "CameraRotateLeft" if int(entry[1]) < 0 else "CameraRotateRight"
		button.tooltip_text = "Center on selected unit" if int(entry[1]) == 0 else "Rotate camera left" if int(entry[1]) < 0 else "Rotate camera right"
		button.text = ""
		button.custom_minimum_size = Vector2(44, 44); camera_rail.add_child(button)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	camera_art = preload("res://scripts/hud_phone_camera_art.gd").new()
	camera_art.name = "CameraArt"
	preload("res://scripts/hud_phone_layout.gd").place(camera_art, Rect2(layout.camera.position - Vector2(4, 0), layout.camera.size))
	overlay.add_child(camera_art)
	target_card = _button("TARGET", _toggle.bind("target")); target_card.name = "TargetCard"
	target_card.visible = false; overlay.add_child(target_card)
	AbilityHUD.setup_action_bar(self, layout, abilities)
	popup = PanelContainer.new(); popup.name = "PhoneDetails"; popup.visible = false
	popup.anchor_left = 0.5; popup.anchor_right = 0.5; popup.anchor_bottom = 1.0
	var popup_half := minf(250.0, (safe_size.x - 16.0) * 0.5)
	popup.offset_left = -popup_half; popup.offset_right = popup_half; popup.offset_top = 48; popup.offset_bottom = -96
	popup.add_theme_stylebox_override("panel", night.panel_style()); overlay.add_child(popup)
	detail_scroll = preload("res://scripts/touch_scroll.gd").new(); detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	popup.add_child(detail_scroll)
	popup_body = VBoxContainer.new(); popup_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_body.add_theme_constant_override("separation", 8); detail_scroll.add_child(popup_body)
	odds_plate = PanelContainer.new(); odds_plate.name = "DecisionOdds"; odds_plate.visible = false
	odds_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var odds_style: StyleBoxFlat = preload("res://scripts/campaign/ui.gd").style(preload("res://scripts/campaign/ui.gd").SURFACE_RAISED, preload("res://scripts/campaign/ui.gd").LINE); odds_style.set_content_margin_all(3)
	odds_plate.add_theme_stylebox_override("panel", odds_style); overlay.add_child(odds_plate)
	var odds_box := VBoxContainer.new(); odds_box.add_theme_constant_override("separation", 0); odds_plate.add_child(odds_box)
	odds_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	odds_title = night.label("", 14, Color("dbe7e4")); odds_title.name = "DecisionTarget"; odds_box.add_child(odds_title)
	odds_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	odds_hit = night.label("", 24, Color("f2d99a")); odds_hit.name = "DecisionHit"; odds_box.add_child(odds_hit)
	odds_hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	odds_badge = night.label("", 14, Color("ef6a5d")); odds_badge.name = "DecisionBadge"; odds_box.add_child(odds_badge)
	odds_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	odds_scroll = preload("res://scripts/touch_scroll.gd").new(); odds_scroll.name = "OddsReasonsScroll"
	odds_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	odds_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	odds_box.add_child(odds_scroll)
	odds_modifiers = night.label("", 14, Color("dbe7e4")); odds_modifiers.name = "DecisionModifiers"
	odds_modifiers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	odds_modifiers.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; odds_scroll.add_child(odds_modifiers)
	enemy_card = PanelContainer.new(); enemy_card.name = "PhoneEnemyEvent"; enemy_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_card.add_theme_stylebox_override("panel", odds_style.duplicate()); enemy_card.hide(); overlay.add_child(enemy_card)
	enemy_text = night.label("", 14, Color("f2d99a")); enemy_text.name = "PhoneEnemyEventText"
	enemy_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; enemy_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_card.add_child(enemy_text)
	feedback.setup(self, g, overlay)
	if safe_size.y > safe_size.x:
		alerts = preload("res://scripts/w23_uiart_alerts.gd").new()
		alerts.name = "PhoneAlertLayer"
		alerts.setup(g, night, overlay)
	var guard := preload("res://scripts/w27c_phone_overlay_guard.gd").new()
	guard.name = "PhoneOverlayGuard27"; guard.hud = self; overlay.add_child(guard)
	var move_controls = preload("res://scripts/w29a_move_controls.gd").new(); move_controls.g = g; overlay.add_child(move_controls)
	root_control.resized.connect(_relayout)
	_relayout.call_deferred()
func _relayout() -> void:
	AbilityHUD.relayout(self)

func _button(title: String, action: Callable) -> Button:
	var button := Button.new(); button.text = title; button.focus_mode = Control.FOCUS_NONE
	preload("res://scripts/campaign/ui.gd").style_button(button)
	button.add_theme_font_size_override("font_size", 14)
	button.custom_minimum_size = Vector2(44, 56 if title in ["END TURN", "MOVE", "FIRE", "OVERWATCH", "CANCEL"] else 44); button.pressed.connect(action)
	return button
func hud_safe_rect28() -> Rect2:
	if not is_instance_valid(overlay): return Rect2()
	var box: Rect2 = preload("res://scripts/hud_phone_layout.gd").boxes(overlay.size).map
	return Rect2(overlay.global_position + box.position, box.size)
func hud_scale28() -> float:
	return root_control.get_window().content_scale_factor if is_instance_valid(root_control) else 1.0
func _place_reinforcement() -> void:
	if feedback.reinforcement == null: return
	# The same alert lives in the top strip; a floating map label blocks taps.
	feedback.reinforcement.hide()
func _refresh_odds() -> void:
	if odds_plate == null: return
	if g.hud_controls != null and g.hud_controls.preview_card26 != null:
		g.hud_controls.preview_card26.hide()
	var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
	var target: Dictionary = g.mission.unit_by_id(g.target_id)
	var active: bool = g.action in ["shoot", "strike"] and g.mission.phase == "player" and g.mission.result == "" and not actor.is_empty() and not target.is_empty() and (bool(target.get("spotted", false)) or bool(target.get("detected", false)) or bool(target.get("awake", false)))
	var move_preview: Dictionary = g.hud_controls.move_decision
	var moving: bool = not active and g.action == "move" and not move_preview.is_empty()
	odds_plate.visible = (active or moving) and open_card == ""
	unit_plate.visible = not active
	if moving:
		odds_title.text = "DESTINATION %d, %d" % [g.hud_controls.move_destination.x, g.hud_controls.move_destination.y]
		odds_hit.text = "1 ACTION" if int(move_preview.ap) == 1 else "DASH · 2 AP"
		odds_hit.add_theme_color_override("font_color", Color("60b9ff") if int(move_preview.ap) == 1 else Color("ffd16a"))
		var tactical: Dictionary = g.hud_controls.move_tactical27
		var cue: Dictionary = preload("res://scripts/w29a_move_cue.gd").at(g.mission, actor, g.hud_controls.move_destination, tactical)
		var danger: Vector2i = move_preview.get("first_danger_tile", Vector2i(-1, -1))
		odds_badge.text = "DANGER · %d enemy sightline%s" % [int(move_preview.get("danger_sightlines", 0)), "" if int(move_preview.get("danger_sightlines", 0)) == 1 else "s"] if danger.x >= 0 else str(cue.label)
		odds_badge.add_theme_color_override("font_color", Color("ef6a5d") if danger.x >= 0 or cue.flanked or cue.exposed else Color("e0bd78"))
		odds_modifiers.text = "FIRST DANGER TILE %d,%d  ·  %s" % [danger.x, danger.y, str(cue.detail)] if danger.x >= 0 else str(cue.detail)
		feedback.refresh_odds()
		odds_scroll.show(); feedback.details_button.hide()
		return
	if not active:
		feedback.refresh_odds()
		return
	var data: Dictionary = Targeting22.shot_breakdown(g.mission, actor, target, g.action == "strike", int(actor.get("leap_aim", 0)) if g.action == "strike" else 0)
	var decision: Dictionary = Targeting22.decision_summary(data, str(target.name), g.action == "strike")
	odds_title.text = str(decision.target).to_upper()
	odds_hit.text = "%d%% HIT  ·  %d%% CRIT" % [int(decision.hit), int(data.get("crit", 0))]
	odds_hit.add_theme_color_override("font_color", Color("f2d99a"))
	odds_badge.text = "◆ " + str(decision.badge)
	odds_badge.add_theme_color_override("font_color", Color("ef6a5d") if str(decision.badge) == "FLANKED" else Color("e0bd78"))
	var cover_reason := "NO COVER" if int(data.get("cover", 0)) == 0 else "COVER -%d" % int(data.cover)
	var height_delta := 0
	for item in data.get("lines", []):
		if str(item[0]) == "High ground": height_delta = int(item[1]); break
	var height_reason := "HEIGHT %+d" % height_delta
	var flank_reason := "FLANKED" if bool(data.get("flanked", false)) else "NO FLANK"
	var reason_lines: Array[String] = [cover_reason, height_reason, flank_reason]
	odds_modifiers.text = "  ·  ".join(reason_lines)
	feedback.refresh_odds()
	if overlay.size.y > overlay.size.x:
		odds_scroll.show(); feedback.details_button.hide()

static func compact_names(names: Array) -> String:
	var counts: Dictionary = {}
	for name in names: counts[str(name)] = int(counts.get(str(name), 0)) + 1
	var labels: Array[String] = []
	for name in counts: labels.append(str(name) + (" ×%d" % int(counts[name]) if int(counts[name]) > 1 else ""))
	return ", ".join(labels)

func _show_ability(button: Button) -> void:
	button.set_meta("w28d_touch_count", int(button.get_meta("w28d_touch_count", 0)) + 1)
	action_name.text = button.tooltip_text
	feedback.show_ability(button)

func _ability_input(event: InputEvent, button: Button) -> void:
	if event is InputEventScreenTouch and event.pressed or event is InputEventMouseButton and event.pressed: _show_ability(button)
	if event is InputEventScreenDrag:
		# An ability drag belongs to the HUD; only touches begun on the map pan it.
		if g.cam.touch.has_method("gesture_owns_touch24") and g.cam.touch.gesture_owns_touch24(): return
		return

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

func queue_radio(speaker: String, words: String, priority: int = 1) -> void:
	if g.mission.phase == "enemy":
		deferred_radio.append({"speaker": speaker, "words": words, "priority": priority})
		return
	if words == "EAST FLANK APPROACHING":
		group_reveal.text = words
		radio_until = Time.get_ticks_msec() + 2500
		group_reveal.show()
	if is_instance_valid(alerts): alerts.call("queue_radio", speaker, words, priority)
	elif words != "EAST FLANK APPROACHING":
		group_reveal.text = words
		radio_until = Time.get_ticks_msec() + 2500
		group_reveal.show()

func _update_group_reveal() -> void:
	if not is_instance_valid(overlay): return
	if g.hud_controls != null and g.hud_controls.preview_card26 != null:
		g.hud_controls.preview_card26.hide()
	var enemy_active: bool = g.mission.phase == "enemy" or g.playing_enemy_events
	if enemy_active:
		enemy_was_active = true
		var reason := str(g.phase_banner.text).strip_edges()
		var outcome := str(night.activity.text).strip_edges() if night.activity != null else ""
		if reason.is_empty(): reason = "Enemy is acting"
		if outcome == reason: outcome = ""
		enemy_text.text = reason + ("\n" + outcome if outcome != "" else "")
		enemy_card.show()
		g.phase_banner.hide()
		night.phase_plate.hide(); night.activity_plate.hide()
		group_reveal.hide()
		if is_instance_valid(alerts): alerts.card.hide()
		return
	_place_reinforcement()
	enemy_card.hide()
	night.phase_plate.hide(); night.activity_plate.hide()
	if enemy_was_active:
		enemy_was_active = false
		if not deferred_story_comms.is_empty() and g.has_meta("story_comms"):
			var comms = g.get_meta("story_comms")
			if comms != null and comms.has_method("show_radio"):
				comms.show_radio(str(deferred_story_comms.speaker), str(deferred_story_comms.speaker), str(deferred_story_comms.words), 1)
			deferred_story_comms.clear()
	if not deferred_radio.is_empty() and (is_instance_valid(alerts) or Time.get_ticks_msec() >= radio_until):
		var item: Dictionary = deferred_radio.pop_front()
		queue_radio(str(item.speaker), str(item.words), int(item.priority))
	var notes = g.get_node_or_null("ThreatNotes11")
	if notes == null or notes.get("panel") == null: return
	notes.panel.modulate.a = 0.0
	if Time.get_ticks_msec() < radio_until: return
	var active := Time.get_ticks_msec() < int(notes.reveal_until)
	if active and str(notes.reveal_text).begins_with("GROUP "):
		var title := str(notes.reveal_text).get_slice(" REVEALED", 0)
		var count := str(notes.reveal_text).get_slice("·", 1).strip_edges().get_slice(":", 0)
		group_reveal.text = title + " · " + count
		group_reveal.show()
		if is_instance_valid(alerts) and alerts.heading.text == "CONTACT":
			alerts.message.text = group_reveal.text
			alerts.card.modulate.a = 0.0
	elif not active and Time.get_ticks_msec() >= radio_until:
		group_reveal.hide()
		if is_instance_valid(alerts): alerts.card.modulate.a = 1.0
func _cycle_unit(direction: int) -> void:
	var id: int = preload("res://scripts/input_controls.gd").next_squad(g.mission, g.selected_id, direction)
	if id >= 0: g._select(id)
func _end_turn() -> void:
	if g.mission.phase != "player" or g.playing_enemy_events:
		end_confirm = false; end_button.text = "END TURN"; end_button.set_pressed_no_signal(false); return
	if not end_confirm:
		end_confirm = true
		end_confirm_at_ms = Time.get_ticks_msec()
		end_button.text = "CONFIRM"
		end_button.set_pressed_no_signal(true)
		action_name.text = "End the squad turn? Tap END TURN again."
		return
	if Time.get_ticks_msec() - end_confirm_at_ms < 500: return
	if g.player_attack_pending or g.playing_enemy_events or g.mission.phase != "player": return
	end_confirm = false
	end_button.text = "END TURN"
	end_button.set_pressed_no_signal(false)
	g._request_end_turn()
	if g.end_turn_armed: g._request_end_turn()

func _close() -> void:
	open_card = ""; refresh()
func _unit_details(unit: Dictionary) -> String: return preload("res://scripts/w29a_phone_details.gd").unit_details(g, unit)
func _claim_strike() -> void:
	var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
	if preload("res://scripts/ability_chains.gd").claim_momentum_strike(g.mission, actor):
		g._refresh()

func refresh(from_game: bool = false) -> void:
	if overlay == null: return
	if from_game:
		var forecast: Dictionary = Threat22.summary(g.mission)
		var pressure_script: Script = load("res://scripts/mission_pressure.gd")
		if pressure_script != null and pressure_script.has_method("next_wave26"):
			var next_wave: Dictionary = pressure_script.call("next_wave26", g.mission)
			if not next_wave.is_empty():
				forecast["next_wave26"] = {"count":int(next_wave.get("count", 0)), "turns":maxi(0, int(next_wave.get("turn", g.mission.turn)) - int(g.mission.turn))}
		last_threat = forecast
		g.objective_label.text = Threat22.sight_text(forecast)
		threat_chip.text = ""
		threat_chip.tooltip_text = str(forecast)
		threat_chip.visible = preload("res://scripts/w28d_phone_labels.gd").threat(forecast) != ""
		var objective: Dictionary = g.mission.objective_status()
		objective_summary.text = str(objective.get("label", "OBJECTIVE")).to_upper()
		var unit_script: Script = load("res://scripts/unit_view.gd")
		if unit_script != null and unit_script.has_method("side_color26"):
			var plate_style: StyleBoxFlat = unit_plate.get_theme_stylebox("panel").duplicate()
			plate_style.border_color = unit_script.call("side_color26", "player")
			plate_style.set_border_width_all(2)
			unit_plate.add_theme_stylebox_override("panel", plate_style)
		var contact: Dictionary = {}
		if pressure_script != null and pressure_script.has_method("opening_contact26"):
			contact = pressure_script.call("opening_contact26", g.mission)
		elif g.mission.has_method("opening_contact26"):
			contact = g.mission.call("opening_contact26")
		if not opening_contact_seen and str(contact.get("status", "")) == "active" and str(contact.get("pod", "")) == "east":
			opening_contact_seen = true
			queue_radio("CONTACT", "EAST FLANK APPROACHING", 2)
	_refresh_odds()
	feedback.refresh_pressure(last_threat)
	_place_reinforcement()
	var pips: int = clampi(int(g.mission.chain_momentum), 0, 3)
	var used_this_turn: bool = int(g.mission.chain_strike_used_turn) == int(g.mission.turn)
	momentum_row.visible = false
	momentum_plate.visible = false
	momentum_pips.text = "MOM " + char(0x25CF).repeat(pips) + char(0x25CB).repeat(3 - pips)
	momentum_display.text = "MOM %d/3" % pips
	momentum_strike.visible = pips >= 3
	momentum_strike.disabled = pips < 3 or used_this_turn or g.mission.phase != "player"
	if pips != last_chain_momentum:
		last_chain_momentum = pips
		momentum_display.pivot_offset = momentum_display.size * 0.5
		var pulse: Tween = g.create_tween()
		pulse.tween_property(momentum_display, "scale", Vector2(1.10, 1.10), 0.12)
		pulse.tween_property(momentum_display, "scale", Vector2.ONE, 0.20)
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
	end_button.text = "CONFIRM" if end_confirm else "END TURN"

	_update_actions(from_game)
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
	var hp: int = int(unit.get("hp", 0))
	var display_name := str(unit.get("name", "UNIT"))
	# Legacy readers inspect the hidden button text; the visible readout uses ASCII.
	var legacy_ap := char(0x25CF) + char(0x25CB) if int(unit.get("ap", 0)) == 1 else ""
	unit_card.text = "%s\nHP%d/%d AP%s %s" % [str(unit.get("name", "UNIT")), hp, int(unit.get("max_hp", 0)), g.hud_controls.ap_pips(unit), legacy_ap]
	unit_card_readout.text = "%s\nHP%d/%d AP%d" % [display_name, hp, int(unit.get("max_hp", 0)), int(unit.get("ap", 0))]
	var target: Dictionary = g.mission.unit_by_id(g.target_id)
	target_card.text = "%s  %s  v" % [str(target.get("name", "TARGET")), g.hit_big_label.text]
	popup.visible = open_card != ""
	if is_instance_valid(alerts): alerts.visible = open_card == ""
	if open_card == "": return
	if open_card == "settings": return
	if detail_scroll.touch_dragging: return
	var saved_scroll: int = detail_scroll.scroll_vertical
	for child in popup_body.get_children(): child.queue_free()
	if open_card == "more":
		AbilityHUD.build_more_list(self)
	elif open_card == "objective":
		popup_body.add_child(night.label("OBJECTIVE", 16, Color("efd49b")))
		var objective_detail: Label = night.label(objective_summary.text, 16)
		objective_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		popup_body.add_child(objective_detail)
	elif open_card == "threat":
		popup_body.add_child(night.label("THREAT & REINFORCEMENTS", 16, Color("efd49b")))
		var threat_detail: Label = night.label(preload("res://scripts/w28d_phone_labels.gd").detail(last_threat), 16)
		threat_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		popup_body.add_child(threat_detail)
	elif open_card == "unit":
		popup_body.add_child(night.label("SQUAD  ·  tap a name to select", 14, Color("efd49b")))
		var squad := HFlowContainer.new(); squad.add_theme_constant_override("h_separation", 8); squad.add_theme_constant_override("v_separation", 8); popup_body.add_child(squad)
		for member in g.mission.living("player"):
			var id: int = int(member.id)
			squad.add_child(_button(str(member.name), func() -> void: g._select(id); refresh()))
		popup_body.add_child(night.label(preload("res://scripts/w29a_phone_details.gd").unit_details(g, unit), 14))
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
		popup_body.add_child(_button("Settings", _show_settings))
		popup_body.add_child(_button("SAVE / LOAD", func() -> void: g.get_node("/root/CampaignFlow").open_saves("rescue")))
		popup_body.add_child(_button("ACTION CAM: %s" % ("ON" if g.action_camera else "OFF"), func() -> void: g.action_camera = not g.action_camera; refresh()))
		popup_body.add_child(_button("SOUND: %s" % ("OFF" if g.sound.muted else "ON"), func() -> void: g.sound.muted = not g.sound.muted; refresh()))
		popup_body.add_child(_button("NUMBERS: %s" % ("ON" if bool(g.Prefs.get_value("numbers")) else "OFF"), func() -> void:
			g.Prefs.set_value("numbers", not bool(g.Prefs.get_value("numbers"))); g._refresh(); refresh()))
		popup_body.add_child(_button("RESTART MISSION", func() -> void: g.get_tree().reload_current_scene()))
		popup_body.add_child(_button("MAIN MENU", func() -> void: g.get_node("/root/CampaignFlow").go("menu")))
	popup_body.add_child(_button("CLOSE", _close))
	detail_scroll.set_deferred("scroll_vertical", saved_scroll)

func _update_actions(from_game: bool) -> void:
	AbilityHUD.update_actions(self, from_game)

func _show_settings() -> void:
	open_card = "settings"
	if is_instance_valid(alerts): alerts.hide()
	feedback.ability_reason.hide()
	for child in popup_body.get_children(): child.queue_free()
	popup_body.add_child(_button("BACK", _show_menu))
	popup_body.add_child(preload("res://scripts/graphics_options.gd").build_settings_panel())
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
