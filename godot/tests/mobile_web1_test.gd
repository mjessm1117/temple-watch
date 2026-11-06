extends SceneTree
const Touch = preload("res://scripts/touch_input.gd")
const Quality = preload("res://scripts/graphics_settings.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	check(Touch.should_click(Vector2.ZERO, Vector2(12,0), false, false), "tap becomes click")
	check(not Touch.should_click(Vector2.ZERO, Vector2(12.1,0), true, false), "drag threshold suppresses click")
	check(not Touch.should_click(Vector2.ZERO, Vector2.ZERO, false, true), "pinch suppresses click")
	check(Touch.pinched_zoom(20.0, 100.0, 500.0) == 9.0, "pinch clamps near")
	check(Touch.pinched_zoom(20.0, 500.0, 10.0) == 65.0, "pinch clamps far")
	check(Quality.default_tier("Linux", true, false, false) == "low", "web defaults Low")
	check(Quality.default_tier("Linux", false, false, false) == "high", "desktop defaults High")
	check(Quality.phone_ui_scale(Vector2i(844,390)) > 1.0, "phone UI enlarged")
	check(Quality.phone_ui_scale(Vector2i(1366,900)) == 1.0, "desktop UI unchanged")
	check(Phone.narrow(Vector2i(844,390)) and Phone.narrow(Vector2i(390,844)), "phone orientations use compact layout")
	check(not Phone.narrow(Vector2i(1366,768)) and not Phone.narrow(Vector2i(1920,1080)), "desktop sizes keep original layout")
	check(not Phone.narrow(Vector2i(900,900)) and Phone.narrow(Vector2i(899,1199)), "compact boundary uses short narrow screens")
	check(Phone.battle_board_fraction(Vector2(844,390)) >= 0.60, "compact HUD leaves at least 60 percent of battle view")
	DisplayServer.window_set_size(Vector2i(844,390))
	root.size = Vector2i(844,390)
	await process_frame
	var game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
	await process_frame
	check(game.hud_controls.phone != null, "battle creates compact HUD on phone")
	if game.hud_controls.phone != null:
		var hud = game.hud_controls.phone
		var end_button: Button = hud.overlay.find_child("PhoneEndTurn", true, false)
		check(end_button != null, "phone HUD has a dedicated End Turn button")
		if end_button != null:
			var bounds := end_button.get_global_rect()
			var visible: Rect2 = hud.overlay.get_global_rect()
			check(visible.encloses(bounds) and bounds.size.x >= 44 and bounds.size.y >= 38, "End Turn fits and is tappable in landscape")
		for member in game.mission.living("player"):
			if member.has("ammo"): game.selected_id = int(member.id); break
		game._refresh()
		check(hud.unit_card != null and hud.target_card != null and hud.action_name != null, "compact cards and ability name are available")
		check(hud.unit_card.custom_minimum_size.y >= 38 and hud.target_card.custom_minimum_size.y >= 38, "compact cards have touch targets")
		var night = game.hud_controls.night
		for field in ["FOCUS", "MEDPACS", "AMMO", "MOMENTUM"]:
			check(night.vitals_label.text.contains(field), "compact unit detail keeps " + field)
		var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
		var enemy: Dictionary = game.mission.living("enemy")[0]
		game.action = "shoot"; game.target_id = int(enemy.id); game._refresh()
		night.detail_open = true; night.refresh_target()
		for field in ["TOTAL", "CRIT", "GRAZE", "SHRED"]:
			check(night.target_details.text.contains(field) or game.hit_big_label.text.contains(field), "compact target detail keeps " + field)
		hud._toggle("target")
		check(hud.popup.visible and hud.popup_body.get_child_count() > 2, "target card expands to full details")
		hud._toggle("unit")
		check(hud.popup.visible and hud.popup_body.get_child_count() > 2, "unit card expands to full details and squad")
		var unit_text: String = hud._unit_details(game.mission.unit_by_id(game.selected_id))
		for field in ["HP ", "AP ", "FOCUS", "MEDPACS", "AMMO", "MOMENTUM", "BOND"]:
			check(unit_text.contains(field), "compact card shows readable " + field)
		check(not actor.is_empty(), "selected actor remains available")
	game.queue_free(); await process_frame
	root.size = Vector2i(390,844); await process_frame
	var portrait = load("res://scenes/rescue.tscn").instantiate(); root.add_child(portrait)
	await process_frame
	if portrait.hud_controls.phone != null:
		var end_portrait: Button = portrait.hud_controls.phone.overlay.find_child("PhoneEndTurn", true, false)
		check(end_portrait != null and portrait.hud_controls.phone.overlay.get_global_rect().encloses(end_portrait.get_global_rect()), "End Turn fits in portrait")
	portrait.queue_free(); await process_frame
	root.size = Vector2i(1366,768); await process_frame
	var desktop = load("res://scenes/rescue.tscn").instantiate(); root.add_child(desktop)
	await process_frame
	check(desktop.hud_controls.phone == null, "desktop battle keeps original HUD")
	desktop.queue_free(); await process_frame
	print("Mobile Web 1: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
