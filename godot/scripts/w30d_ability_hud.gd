extends RefCounted
## Phone action tray, overflow order, and its layout wiring.
const Signature = preload("res://scripts/w27d_ability_signature.gd")
const STANDARD = ["move", "shoot", "strike", "overwatch", "push", "reload", "hunker", "guard", "rapidFire", "suppress"]
const UTILITY = ["free", "medpac", "revive", "reviveStim", "heal", "forceHeal", "massHeal", "forceRevive"]

static func setup_action_bar(h, layout: Dictionary, abilities: HFlowContainer) -> void:
	var night = h.night
	var overlay: Control = h.overlay
	var ability_buttons: Array[Button] = h.ability_buttons
	var ability_tray: PanelContainer
	var momentum_plate: Control
	var momentum_pips: Label
	var momentum_display: Label
	var action_name: Label
	var momentum_row: HBoxContainer
	var ability_scroll: ScrollContainer
	var momentum_strike: Button
	var more_button: Button
	var action_art: Control
	var tray := PanelContainer.new(); tray.name = "AbilityTray"; ability_tray = tray
	tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preload("res://scripts/hud_phone_layout.gd").place(tray, Rect2(layout.tray.position, layout.tray.size - Vector2(8, 0)))
	var tray_style: StyleBoxFlat = night.panel_style(); tray_style.set_content_margin_all(0)
	tray.add_theme_stylebox_override("panel", tray_style); overlay.add_child(tray)
	var tray_box := HBoxContainer.new(); tray_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tray_box.add_theme_constant_override("separation", 4); tray.add_child(tray_box)
	momentum_plate = Control.new(); momentum_plate.name = "MomentumPlate"
	momentum_plate.mouse_filter = Control.MOUSE_FILTER_STOP
	momentum_plate.custom_minimum_size = Vector2(82, 17); tray_box.add_child(momentum_plate)
	momentum_pips = night.label("", 14, Color.TRANSPARENT); momentum_pips.name = "ChainPips"
	momentum_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	momentum_pips.position = Vector2(2, 0); momentum_plate.add_child(momentum_pips)
	momentum_display = night.label("MOM 0/3", 14, Color("e9ca83")); momentum_display.name = "ChainCount"
	momentum_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	momentum_display.position = Vector2(2, 0); momentum_plate.add_child(momentum_display)
	action_name = night.label("Choose an action", 14, Color("e9ca83"))
	action_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_name.name = "AbilityReadout"; action_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	action_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	action_name.custom_minimum_size.y = 17; overlay.add_child(action_name)
	momentum_row = HBoxContainer.new(); momentum_row.name = "ChainMomentum"
	momentum_row.visible = false; tray_box.add_child(momentum_row)
	var scroll := preload("res://scripts/touch_scroll.gd").new(); scroll.name = "Abilities"
	ability_scroll = scroll; scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.custom_minimum_size.y = 44; tray_box.add_child(scroll)
	tray_box.move_child(momentum_plate, tray_box.get_child_count() - 1)
	scroll.get_h_scroll_bar().modulate.a = 0.0
	var track := HBoxContainer.new(); track.add_theme_constant_override("separation", 8); scroll.add_child(track)
	for node in abilities.get_children():
		var button: Button = node
		button.reparent(track); button.custom_minimum_size = preload("res://scripts/hud_phone_layout.gd").ACTION_MIN_SIZE
		button.flat = true
		ability_buttons.append(button)
		button.set_meta("graphics_custom_minimum_size", preload("res://scripts/hud_phone_layout.gd").ACTION_MIN_SIZE)
		button.set_meta("shared_phone_art", true)
		button.set("compact", true); button.set("phone_icon", true)
		button.button_down.connect(h._show_ability.bind(button))
		button.pressed.connect(h._show_ability.bind(button))
		button.gui_input.connect(h._ability_input.bind(button))
	momentum_strike = h._button("STRIKE", h._claim_strike)
	momentum_strike.name = "MomentumStrike"; momentum_strike.custom_minimum_size = preload("res://scripts/hud_phone_layout.gd").ACTION_MIN_SIZE
	momentum_strike.add_theme_font_size_override("font_size", 11); track.add_child(momentum_strike)
	more_button = h._button("MORE", h._toggle.bind("more")); more_button.custom_minimum_size = preload("res://scripts/hud_phone_layout.gd").ACTION_MIN_SIZE; track.add_child(more_button)
	for button in [momentum_strike, more_button]:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var round_style := StyleBoxFlat.new()
			round_style.bg_color = Color("12303a") if state != "disabled" else Color("28333c")
			round_style.border_color = Color("a8f3bb") if button == momentum_strike and state != "disabled" else Color("be9d5b")
			round_style.set_border_width_all(1); round_style.set_corner_radius_all(18)
			button.add_theme_stylebox_override(state, round_style)
	action_art = preload("res://scripts/hud_phone_action_art.gd").new()
	action_art.name = "PhoneActionArt"; action_art.buttons = ability_buttons
	preload("res://scripts/hud_phone_layout.gd").place(action_art, Rect2(layout.tray.position, layout.tray.size - Vector2(8, 0)))
	overlay.add_child(action_art)
	h.ability_tray = ability_tray
	h.momentum_plate = momentum_plate
	h.momentum_pips = momentum_pips
	h.momentum_display = momentum_display
	h.action_name = action_name
	h.momentum_row = momentum_row
	h.ability_scroll = ability_scroll
	h.momentum_strike = momentum_strike
	h.more_button = more_button
	h.action_art = action_art

static func relayout(h) -> void:
	var overlay: Control = h.overlay
	var root_control: Control = h.root_control
	var threat_chip: Button = h.threat_chip
	var end_button: Button = h.end_button
	var unit_plate: PanelContainer = h.unit_plate
	var ability_tray: PanelContainer = h.ability_tray
	var action_art: Control = h.action_art
	var objective_summary: Label = h.objective_summary
	var action_name: Label = h.action_name
	var camera_rail: VBoxContainer = h.camera_rail
	var camera_art: Control = h.camera_art
	var unit_portrait: TextureRect = h.unit_portrait
	var unit_plate_row: HBoxContainer = h.unit_plate_row
	var portrait_frame: PanelContainer = h.portrait_frame
	var top_heading: HBoxContainer = h.top_heading
	var last_threat: Dictionary = h.last_threat
	var menu_button: Button = h.menu_button
	var end_confirm: bool = h.end_confirm
	var ability_scroll: ScrollContainer = h.ability_scroll
	var odds_plate: PanelContainer = h.odds_plate
	var enemy_card: PanelContainer = h.enemy_card
	var odds_title: Label = h.odds_title
	var odds_hit: Label = h.odds_hit
	var odds_badge: Label = h.odds_badge
	var odds_scroll: ScrollContainer = h.odds_scroll
	var odds_modifiers: Label = h.odds_modifiers
	var feedback = h.feedback
	var g = h.g
	var alerts: Control = h.alerts
	var group_reveal: Label = h.group_reveal
	if not is_instance_valid(overlay) or root_control.size.x <= 0.0: return
	var safe := preload("res://scripts/phone_layout.gd").safe_margins(root_control.size)
	safe = Vector4(maxf(0.0, safe.x), maxf(0.0, safe.y), maxf(0.0, safe.z), maxf(0.0, safe.w))
	overlay.offset_left = clampf(safe.x, 0.0, root_control.size.x * 0.2)
	overlay.offset_top = clampf(safe.y, 0.0, root_control.size.y * 0.2)
	overlay.offset_right = -clampf(safe.z, 0.0, root_control.size.x * 0.2)
	overlay.offset_bottom = -clampf(safe.w, 0.0, root_control.size.y * 0.2)
	var area := root_control.size - Vector2(safe.x + safe.z, safe.y + safe.w)
	var boxes: Dictionary = preload("res://scripts/hud_phone_layout.gd").boxes(area)
	var layout = preload("res://scripts/hud_phone_layout.gd")
	layout.place(overlay.find_child("PhoneTopBackground", false, false), boxes.header)
	layout.place(overlay.find_child("PhoneTopStrip", false, false), boxes.header)
	var portrait := area.y > area.x
	layout.place(threat_chip, Rect2(8, 2, 44, 44))
	layout.place(end_button, boxes.end)
	layout.place(unit_plate, boxes.plate)
	layout.place(ability_tray, boxes.tray)
	layout.place(action_art, boxes.tray)
	h._update_actions.call_deferred(false)
	layout.place(objective_summary, Rect2(60, 2, area.x - 164, 44))
	layout.place(action_name, Rect2(8 if portrait else boxes.tray.position.x, (boxes.plate.position.y if portrait else boxes.tray.position.y) - 24, area.x - 16 if portrait else boxes.tray.size.x, 20))
	action_name.hide()
	layout.place(camera_rail, boxes.camera)
	layout.place(camera_art, boxes.camera)
	if unit_portrait.get_parent() != unit_plate_row:
		unit_portrait.reparent(unit_plate_row)
		unit_plate_row.move_child(unit_portrait, 0)
	portrait_frame.hide()
	layout.place(group_reveal, Rect2(8, 78 if portrait else 54, minf(240.0, area.x - 70.0), 32))
	if portrait and g.objective_label.get_parent() != overlay:
		g.objective_label.reparent(overlay)
	elif not portrait and g.objective_label.get_parent() != top_heading:
		g.objective_label.reparent(top_heading)
		top_heading.move_child(g.objective_label, 0)
	top_heading.alignment = BoxContainer.ALIGNMENT_END
	g.objective_label.hide()
	threat_chip.visible = preload("res://scripts/w28d_phone_labels.gd").threat(last_threat) != ""
	menu_button.custom_minimum_size = Vector2(64, 52)
	menu_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	end_button.add_theme_font_size_override("font_size", 15)
	if end_confirm: end_button.set_pressed_no_signal(true)
	ability_scroll.custom_minimum_size.y = 56
	unit_portrait.custom_minimum_size = Vector2(52, 52)
	layout.place(odds_plate, Rect2(12, 72 if portrait else 50, minf(150.0 if portrait else 340.0, area.x - 82.0), 126 if portrait else 96))
	layout.place(enemy_card, Rect2(12, 150 if portrait else 50, minf(250.0 if portrait else 350.0, area.x - 76.0), 76))
	odds_title.add_theme_font_size_override("font_size", 12 if portrait else 14)
	odds_hit.add_theme_font_size_override("font_size", 24)
	odds_badge.visible = true
	odds_scroll.custom_minimum_size.y = 52 if portrait else 20
	odds_scroll.custom_minimum_size.x = 140 if portrait else 300
	odds_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if portrait else ScrollContainer.SCROLL_MODE_AUTO
	odds_modifiers.custom_minimum_size.x = 134 if portrait else 294
	odds_modifiers.add_theme_font_size_override("font_size", 14)
	odds_scroll.visible = true
	feedback.relayout(area)
	if portrait:
		odds_scroll.show()
		feedback.details_button.hide()
	h._place_reinforcement()
	if g != null and g.cam != null and g.selected_id >= 0: g.cam.frame_selected_safe29.call_deferred()
	preload("res://scripts/w28d_phone_bridge.gd").publish.call_deferred(h)
	if is_instance_valid(alerts):
		alerts.call("set_safe_area", area)
		alerts.card.position.y = boxes.plate.end.y + 38
	if g.hud_controls != null and g.hud_controls.aim_ui != null:
		var aim = g.hud_controls.aim_ui
		if portrait:
			aim.odds.get_parent().visible = false
			aim.odds_detail.visible = false
			aim.panel.anchor_left = 0.0; aim.panel.anchor_right = 1.0
			aim.panel.offset_left = 12 + safe.x; aim.panel.offset_right = -12 - safe.z
			aim.panel.offset_top = -72 - safe.w; aim.panel.offset_bottom = -8 - safe.w
			aim.confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			aim.target_row.anchor_left = 1.0; aim.target_row.anchor_right = 1.0
			aim.target_row.offset_left = -minf(190.0, area.x * 0.49) - safe.z; aim.target_row.offset_right = -12 - safe.z
			aim.target_row.offset_top = 64 + safe.y; aim.target_row.offset_bottom = 118 + safe.y
			aim.aim_momentum.visible = false
		else:
			aim.odds.get_parent().visible = true
			aim.aim_momentum.visible = true
			aim.odds.get_parent().custom_minimum_size.x = 144
			aim.odds_detail.visible = true
			aim.panel.anchor_left = 1.0; aim.panel.anchor_right = 1.0
			aim.panel.anchor_top = 1.0; aim.panel.anchor_bottom = 1.0
			aim.panel.offset_left = -minf(356.0, area.x - 262.0) - safe.z
			aim.panel.offset_right = -12 - safe.z
			aim.panel.offset_top = -62 - safe.w; aim.panel.offset_bottom = -4 - safe.w
			aim.target_row.anchor_left = 1.0; aim.target_row.anchor_right = 1.0
			aim.target_row.offset_left = -minf(340.0, area.x * 0.48) - safe.z
			aim.target_row.offset_right = -12 - safe.z
			aim.target_row.offset_top = 64 + safe.y; aim.target_row.offset_bottom = 118 + safe.y

static func update_actions(h, from_game: bool) -> void:
	var g = h.g
	var ability_buttons: Array[Button] = h.ability_buttons
	var ability_tray: PanelContainer = h.ability_tray
	var momentum_plate: Control = h.momentum_plate
	var momentum_strike: Button = h.momentum_strike
	var overlay: Control = h.overlay
	var more_button: Button = h.more_button
	var action_art: Control = h.action_art
	var unit: Dictionary = g.mission.unit_by_id(g.selected_id)
	var available: int = int(unit.get("ap", 0))
	var action_width: float = ability_tray.size.x - (82.0 if momentum_plate.visible else 0.0) - (68.0 if momentum_strike.visible else 0.0) - 4.0
	var primary_limit := clampi(int(floor((action_width + 8.0) / 75.0)) - 1, 1, 4)
	h.last_unit_id = g.selected_id; h.last_unit_ap = available
	if from_game:
		for button in ability_buttons: button.set_meta("battle12_available", button.visible)
	var primary: Array[String] = []
	for mode in ["move", "shoot", "strike", "overwatch", "push", "reload", "hunker", "medpac"]:
		if primary.size() >= primary_limit: break
		for button in ability_buttons:
			if button.ability_id == mode and bool(button.get_meta("battle12_available", false)):
				primary.append(mode); break
	if overlay.size.y > overlay.size.x and "overwatch" not in primary:
		for button in ability_buttons:
			if button.ability_id == "overwatch" and bool(button.get_meta("battle12_available", false)):
				if primary.size() >= primary_limit: primary.pop_back()
				primary.append("overwatch")
				break
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
	action_art.queue_redraw()

static func more_group(button: Button, abilities: Dictionary, unit: Dictionary, target: Dictionary) -> int:
	var id: String = button.ability_id
	var def: Dictionary = abilities.get(id, {})
	if Signature.chain_ready(def, target, unit): return 0
	if id in UTILITY or int(def.get("cost", def.get("ap", 1))) <= 0: return 3
	if int(def.get("rank", 0)) > 0 and unit.get("kit", []).has(id): return 1
	if id in STANDARD: return 2
	return 3

static func more_before(a: Button, b: Button, abilities: Dictionary, unit: Dictionary, target: Dictionary) -> bool:
	var a_group := more_group(a, abilities, unit, target)
	var b_group := more_group(b, abilities, unit, target)
	if a_group != b_group: return a_group < b_group
	var a_cost := int(abilities.get(a.ability_id, {}).get("cost", abilities.get(a.ability_id, {}).get("ap", 1)))
	var b_cost := int(abilities.get(b.ability_id, {}).get("cost", abilities.get(b.ability_id, {}).get("ap", 1)))
	if a_cost != b_cost: return a_cost > b_cost
	return a.ability_id < b.ability_id

static func build_more_list(h) -> void:
	var g = h.g
	var popup_body: VBoxContainer = h.popup_body
	var night = h.night
	popup_body.add_child(night.label("MORE ACTIONS", 16, Color("efd49b")))
	var reason_label: Label = night.label("", 14, Color("f2d99a"))
	reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason_label.hide(); popup_body.add_child(reason_label)
	var unit: Dictionary = g.mission.unit_by_id(g.selected_id)
	var target: Dictionary = g.mission.unit_by_id(g.target_id)
	var candidates: Array[Button] = []
	for button in h.ability_buttons:
		if button.visible or not bool(button.get_meta("battle12_available", false)) or button.ability_id == "": continue
		candidates.append(button)
	candidates.sort_custom(func(a: Button, b: Button) -> bool: return more_before(a, b, g.mission.abilities, unit, target))
	for button in candidates:
		var mode: String = button.ability_id
		var def: Dictionary = g.mission.abilities.get(mode, {})
		var item: Button = h._button("%s %s  ·  %s AP%s" % [button.display_name, preload("res://scripts/hud18_icon.gd").marks(def), button.cost, "  ·  %d TURN CD" % button.cooldown if button.cooldown > 0 else ""], func() -> void:
			if button.disabled:
				h.feedback.show_ability(button)
				reason_label.text = button.tooltip_text; reason_label.show()
			else: g._choose_action(mode); h._close())
		item.set_meta("ability_id", mode)
		item.modulate = Color("9aa9ac") if button.disabled else Color.WHITE
		popup_body.add_child(item)
