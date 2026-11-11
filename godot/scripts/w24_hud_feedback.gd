extends RefCounted
## Small battle notices stay in the map margin and never consume map input.
var game
var hud_ref: WeakRef
var reinforcement: Label
var busy: Label
var ability_reason: Label
var details_button: Button
var details_open := false
var last_safe_rect := Rect2()

func setup(owner, battle, layer: Control) -> void:
	hud_ref = weakref(owner); game = battle
	var hud = hud_ref.get_ref()
	reinforcement = _label(layer, "ReinforcementCue", Color("f2d99a"))
	busy = _label(layer, "BattleBusyCue", Color("dbe7e4"))
	ability_reason = _label(layer, "AbilityReasonCue", Color("f2d99a"))
	ability_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_button = Button.new(); details_button.name = "OddsReasonsToggle"
	details_button.text = "REASONS ▾"; details_button.custom_minimum_size = Vector2(100, 44)
	details_button.flat = true
	details_button.pressed.connect(func() -> void:
		var current = hud_ref.get_ref()
		if current != null: details_open = not details_open; current._relayout())
	hud.odds_plate.get_child(0).add_child(details_button)
	details_button.hide()
	if game.has_signal("input_busy_changed24"):
		game.connect("input_busy_changed24", _busy_changed)
	if game.has_method("is_input_busy24"):
		_busy_changed(bool(game.call("is_input_busy24")))

func _label(layer: Control, title: String, color: Color) -> Label:
	var label := Label.new(); label.name = title
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.hide(); layer.add_child(label)
	return label

func _busy_changed(value: bool) -> void:
	busy.text = "CAMERA BUSY" if value else ""
	busy.visible = value

func relayout(area: Vector2) -> void:
	var hud = hud_ref.get_ref()
	if hud == null: return
	var portrait := area.y > area.x
	var layout = preload("res://scripts/hud_phone_layout.gd")
	layout.place(busy, Rect2(maxf(12, area.x - 190) if portrait else 12, 210 if portrait else 158, 140, 24))
	layout.place(reinforcement, Rect2(12, 154 if portrait else 112, minf(250, area.x - 76), 48))
	layout.place(ability_reason, Rect2(12, area.y - (202 if portrait else 144), minf(280, area.x - 24), 54))
	refresh_odds()

func refresh_pressure(forecast: Dictionary) -> void:
	var hud = hud_ref.get_ref()
	if hud == null: return
	var groups: Array = forecast.get("pending_groups", [])
	if groups.is_empty():
		reinforcement.text = ""; reinforcement.hide(); return
	var wave: Dictionary = groups[0]
	var entry: Vector2i = wave.get("entry_pos", Vector2i(-1, -1))
	reinforcement.text = "INBOUND %d · %d TURN%s\nENTRY %d, %d" % [int(wave.get("count", 0)), int(wave.get("turns", 0)), "S" if int(wave.get("turns", 0)) != 1 else "", entry.x, entry.y]
	reinforcement.visible = not hud.odds_plate.visible and hud.open_card == ""

func show_ability(button: Button) -> void:
	var hud = hud_ref.get_ref()
	if hud == null: return
	if not button.disabled: return
	ability_reason.text = button.tooltip_text
	ability_reason.visible = hud.open_card == ""
	hud.action_name.text = button.tooltip_text

func refresh_odds() -> void:
	var hud = hud_ref.get_ref()
	if hud == null: return
	if hud.odds_plate == null: return
	var portrait: bool = hud.overlay.size.y > hud.overlay.size.x
	details_button.visible = portrait and hud.odds_plate.visible and game.action in ["shoot", "strike"] and hud.odds_modifiers.text != ""
	details_button.text = "REASONS ▴" if details_open else "REASONS ▾"
	hud.odds_scroll.visible = hud.odds_plate.visible and (not portrait or details_open)
	if game.cam != null and game.cam.has_method("set_battle_safe_rect24"):
		var safe_rect: Rect2 = hud.odds_plate.get_global_rect() if hud.odds_plate.visible else Rect2()
		if safe_rect != last_safe_rect:
			last_safe_rect = safe_rect
			game.cam.call("set_battle_safe_rect24", safe_rect)
	reinforcement.visible = reinforcement.text != "" and not hud.odds_plate.visible and hud.open_card == ""
