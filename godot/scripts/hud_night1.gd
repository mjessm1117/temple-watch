extends Control
## Battle-only presentation. Reads mission state; never changes combat outcomes.
const Shot = preload("res://scripts/shot.gd")
const Targeting = preload("res://scripts/combat_targeting.gd")
var g
var name_label: Label
var vitals_label: Label
var status_row: HBoxContainer
var target_details: Label
var details_button: Button
var detail_open := false
var chips: Control
var phase_plate: PanelContainer
var phase_text: Label
var activity: Label
var activity_plate: PanelContainer
var log_heading: Label
var last_phase := ""
var last_log_count := 0
var log_until := 0.0
var next_chip_update := 0.0
var pause_back: ColorRect
var pause_panel: PanelContainer
var settings_box: VBoxContainer

func setup(left_box: VBoxContainer, right_box: VBoxContainer) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var selected: Label = g.selected_label
	selected.visible = false
	var plate := PanelContainer.new(); left_box.add_child(plate)
	plate.add_theme_stylebox_override("panel", panel_style())
	var body := VBoxContainer.new(); plate.add_child(body)
	name_label = label("", 17, Color("efd49b")); name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; body.add_child(name_label)
	vitals_label = label("", 12); vitals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; body.add_child(vitals_label)
	status_row = HBoxContainer.new(); body.add_child(status_row)
	details_button = Button.new(); details_button.text = "ODDS BREAKDOWN ▸"; details_button.focus_mode = Control.FOCUS_NONE
	details_button.pressed.connect(func() -> void: detail_open = not detail_open; refresh_target())
	right_box.add_child(details_button)
	target_details = label("", 12, Color("b8d3dd")); target_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; right_box.add_child(target_details)
	right_box.move_child(details_button, 3)
	right_box.move_child(target_details, 4)
	log_heading = right_box.get_child(5)
	chips = Control.new(); chips.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); chips.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(chips)
	phase_plate = PanelContainer.new(); phase_plate.visible = false; phase_plate.anchor_left = 0.5; phase_plate.anchor_right = 0.5
	phase_plate.offset_left = -170; phase_plate.offset_right = 170; phase_plate.offset_top = 72; phase_plate.offset_bottom = 126
	phase_plate.add_theme_stylebox_override("panel", panel_style()); add_child(phase_plate)
	phase_text = label("JEDI TURN", 26, Color("f0cf86")); phase_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; phase_plate.add_child(phase_text)
	activity_plate = PanelContainer.new(); activity_plate.anchor_left = 0.5; activity_plate.anchor_right = 0.5
	activity_plate.offset_left = -260; activity_plate.offset_right = 260; activity_plate.offset_top = 128; activity_plate.offset_bottom = 158
	activity_plate.add_theme_stylebox_override("panel", panel_style()); add_child(activity_plate)
	activity = label("", 16, Color("f4dfb3")); activity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; activity_plate.add_child(activity)
	build_pause()

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color("101b26ee"); style.border_color = Color("be9d5b")
	style.set_border_width_all(1); style.set_content_margin_all(8); return style

func label(value: String, font_size: int, color: Color = Color("e9eff0")) -> Label:
	var l := Label.new(); l.text = value; l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color); return l

func refresh() -> void:
	var u: Dictionary = g.mission.unit_by_id(g.selected_id)
	if not u.is_empty():
		name_label.text = str(u.get("name", ""))
		var bond := ""
		for mate_id in u.get("bondmates", {}):
			var mate: Dictionary = g.mission.unit_by_id(int(mate_id))
			if not mate.is_empty(): bond = str(mate.get("name", "")); break
		var rows: Array[String] = [str(u.get("class_name", "Jedi")), "HP %s" % ("●".repeat(int(u.get("hp", 0))) + "○".repeat(maxi(0, int(u.get("max_hp", 0)) - int(u.get("hp", 0)))))]
		var ap_pips := "◆".repeat(int(u.get("ap", 0))) + "◇".repeat(maxi(0, (2 if g.mission.modern else 3) - int(u.get("ap", 0))))
		rows.append(("WILL %s   " % str(u.will) if u.has("will") else "") + "AP %s" % ap_pips)
		rows.append("FOCUS %d  ·  MEDPACS %d" % [int(u.get("focus_left", 0)), int(u.get("medpacs", 0))])
		var supplies := "AMMO %d/%d" % [int(u.ammo), int(u.clip)] if u.has("ammo") else ""
		if g.mission.get("momentum") != null: supplies += ("  ·  " if supplies != "" else "") + "MOMENTUM %d/10" % int(g.mission.momentum)
		if supplies != "": rows.append(supplies)
		rows.append("BOND  " + bond if bond != "" else "NO BOND PARTNER")
		vitals_label.text = "\n".join(rows)
		for child in status_row.get_children(): child.queue_free()
		for key in ["hunkered", "overwatch", "concealed", "stunned", "rooted", "disarmed", "wounded"]:
			if not bool(u.get(key, false)): continue
			var icon := label("◆", 16, Color("80d5e9") if key in ["overwatch","concealed"] else Color("eeae79"))
			icon.tooltip_text = key.capitalize(); icon.mouse_filter = Control.MOUSE_FILTER_STOP; status_row.add_child(icon)
	refresh_target()

func refresh_target() -> void:
	if target_details == null: return
	var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
	var target: Dictionary = g.mission.unit_by_id(g.target_id)
	var aiming: bool = g.action in ["shoot", "strike"] and not actor.is_empty() and not target.is_empty()
	details_button.visible = aiming
	target_details.visible = aiming
	g.shot_label.visible = not aiming
	if log_heading != null: log_heading.visible = not aiming
	g.log_label.visible = not aiming
	if aiming:
		var data: Dictionary = Targeting.shot_breakdown(g.mission, actor, target, g.action == "strike", int(actor.get("leap_aim",0)) if g.action == "strike" else 0)
		var rows: Array[String] = []
		for item in data.aim_lines: rows.append("%s  %+d" % [item[0], int(item[1])])
		rows.append("TOTAL  %d%%  ·  CRIT %d%%" % [int(data.hit), int(data.crit)])
		var damage: Dictionary = Shot.damage_preview(actor, target)
		var summary := "%s  HP %d/%d\nCRIT %d%%  ·  GRAZE %d%%\nDMG %d–%d  ·  ARMOR %d\nCRIT %d–%d  ·  GRAZE %d–%d\nSHRED %d on hit\n%s" % [str(target.name), int(target.hp), int(target.max_hp), int(data.crit), int(data.graze), int(damage.normal[0]), int(damage.normal[1]), int(damage.armor), int(damage.critical[0]), int(damage.critical[1]), int(damage.graze[0]), int(damage.graze[1]), int(damage.shred), "FLANKED" if bool(data.flanked) else "LOS CLEAR" if bool(data.los) else "LOS BLOCKED — red trace"]
		if actor.has("ammo"): summary += "\nAMMO %d/%d · %d AP" % [int(actor.ammo), int(actor.clip), int(g.mission.abilities[g.action].ap)]
		target_details.text = summary + ("\n" + "\n".join(rows) if detail_open else "")
		details_button.text = "ODDS BREAKDOWN %s" % ("▾" if detail_open else "▸")
	update_chips()

func update_chips() -> void:
	if chips == null: return
	for child in chips.get_children(): child.queue_free()
	if g.action not in ["shoot", "strike"] or g.mission.phase != "player": return
	var actor: Dictionary = g.mission.unit_by_id(g.selected_id)
	if actor.is_empty(): return
	for enemy in g.mission.living("enemy"):
		if not bool(enemy.get("awake",false)) and not bool(enemy.get("spotted",false)): continue
		var data: Dictionary = Shot.calculate(g.mission, actor, enemy, g.action == "strike")
		if not bool(data.los) or not bool(data.range_ok): continue
		var at: Vector2 = g.camera.unproject_position(Vector3(enemy.x, Shot.elevation(g.mission, Shot.pos(enemy)) * 0.7 + 2.2, enemy.y))
		if at.x < 210 or at.x > size.x - 270 or at.y < 75 or at.y > size.y - 170: continue
		var chip := label("%d%% HIT  ·  %d%% CRIT" % [int(data.hit), int(data.crit)] if int(enemy.id) == g.target_id else "%d%%" % int(data.hit), 18 if int(enemy.id) == g.target_id else 14, Color("f2d38a"))
		chip.position = Vector2(at.x - 45, maxf(66.0, at.y - 65.0)); chip.add_theme_stylebox_override("normal", panel_style()); chips.add_child(chip)

func _process(_delta: float) -> void:
	if g == null or g.mission == null: return
	var phase: String = str(g.mission.phase)
	if phase != last_phase:
		last_phase = phase
		phase_text.text = "ENEMY ACTIVITY" if phase == "enemy" else "JEDI TURN"
		phase_plate.visible = true; phase_plate.modulate.a = 1.0; phase_plate.position.y = 54
		var tween := create_tween(); tween.tween_property(phase_plate, "position:y", 72.0, 0.22).set_trans(Tween.TRANS_SINE)
		tween.tween_interval(1.0); tween.tween_property(phase_plate, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func() -> void: phase_plate.visible = false)
	if g.phase_banner.visible and g.phase_banner.text == "YOUR TURN": phase_plate.visible = false
	if phase == "enemy" and g.mission.log_lines.size() > last_log_count:
		activity.text = str(g.mission.log_lines.back()); log_until = Time.get_ticks_msec() / 1000.0 + 2.0
	last_log_count = g.mission.log_lines.size()
	activity_plate.visible = phase == "enemy" and Time.get_ticks_msec() / 1000.0 < log_until
	if g.action in ["shoot","strike"] and g.target_id >= 0 and Time.get_ticks_msec() / 1000.0 >= next_chip_update:
		update_chips(); next_chip_update = Time.get_ticks_msec() / 1000.0 + 0.15

func _unhandled_input(event: InputEvent) -> void:
	if pause_back.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE: pause_back.visible = false
		get_viewport().set_input_as_handled(); return
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE): return
	if g.action == "move" and g.preview_tile.x < 0 and not g.playing_enemy_events:
		pause_back.visible = true; get_viewport().set_input_as_handled()

func build_pause() -> void:
	pause_back = ColorRect.new(); pause_back.color = Color("050a10cc"); pause_back.visible = false
	pause_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); pause_back.mouse_filter = Control.MOUSE_FILTER_STOP; add_child(pause_back)
	pause_panel = PanelContainer.new(); pause_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_panel.offset_left = -210; pause_panel.offset_right = 210; pause_panel.offset_top = -190; pause_panel.offset_bottom = 190
	pause_panel.add_theme_stylebox_override("panel", panel_style()); pause_back.add_child(pause_panel)
	var box := VBoxContainer.new(); pause_panel.add_child(box)
	box.add_child(label("BATTLE PAUSED", 25, Color("e9c77b")))
	var resume := Button.new(); resume.text = "RESUME  ·  ESC"; resume.pressed.connect(func() -> void: pause_back.visible = false); box.add_child(resume)
	var settings := Button.new(); settings.text = "SETTINGS"; settings.pressed.connect(func() -> void: settings_box.visible = not settings_box.visible); box.add_child(settings)
	settings_box = VBoxContainer.new(); settings_box.visible = false; box.add_child(settings_box)
	settings_box.add_child(preload("res://scripts/graphics_options.gd").new())
	var cine := CheckButton.new(); cine.text = "Action camera"; cine.button_pressed = bool(g.Prefs.get_value("cine")); settings_box.add_child(cine)
	cine.toggled.connect(func(value: bool) -> void: g.action_camera = value; g.Prefs.set_value("cine", value))
	var tips := CheckButton.new(); tips.text = "Tips"; tips.button_pressed = bool(g.Prefs.get_value("tips")); settings_box.add_child(tips)
	tips.toggled.connect(func(value: bool) -> void: g.Prefs.set_value("tips", value))
	var enemy_speed := OptionButton.new(); enemy_speed.add_item("Enemy turns: Normal", 0); enemy_speed.add_item("Enemy turns: Fast", 1)
	enemy_speed.selected = 1 if RescueSettings.battle_value("fast_enemy") else 0; settings_box.add_child(enemy_speed)
	enemy_speed.item_selected.connect(func(index: int) -> void: RescueSettings.set_battle_value("fast_enemy", index == 1))
	var auto_select := CheckButton.new(); auto_select.text = "Auto-select next ready unit"; auto_select.button_pressed = RescueSettings.battle_value("auto_select"); settings_box.add_child(auto_select)
	auto_select.toggled.connect(func(value: bool) -> void: RescueSettings.set_battle_value("auto_select", value))
	var menu := Button.new(); menu.text = "MAIN MENU"; menu.pressed.connect(func() -> void: g.get_node("/root/CampaignFlow").go("menu")); box.add_child(menu)
