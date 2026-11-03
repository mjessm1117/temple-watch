extends SceneTree

const CameraRules = preload("res://scripts/battle11_camera.gd")
const AbilityButton = preload("res://scripts/hud_ability_button.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(reason)

func run() -> void:
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true; game.set_process(false)
	var abilities: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
	for width in [1366, 1920]:
		root.size = Vector2i(width, 768 if width == 1366 else 1080)
		await process_frame
		for id in abilities:
			var name: String = str(abilities[id].get("name", id))
			var layout: Dictionary = AbilityButton.name_layout(name, 126.0)
			check(layout.lines.size() <= 2, "%d %s uses at most two lines" % [width, name])
			for line in layout.lines:
				var measured := ThemeDB.fallback_font.get_string_size(str(line), HORIZONTAL_ALIGNMENT_LEFT, -1, int(layout.size)).x
				check(measured <= 77.0, "%d %s label fits button: %s" % [width, name, line])
		for id in game.action_buttons:
			var button: Button = game.action_buttons[id]
			if button.visible: check(button.get_global_rect().end.x <= width + 1.0, "%d %s button inside viewport" % [width, id])
	var m: RefCounted = game.mission
	check(CameraRules.start_zoom(m) < maxf(float(m.spec.width), float(m.spec.height)) * 1.3, "default camera zoom is tighter")
	game.pivot = Vector3(-500, 12, 500); game._update_camera()
	check(game.pivot.x >= 1 and game.pivot.z <= float(m.spec.height) - 2 and game.pivot.y == 0, "camera pivot stays on board")
	check(game.camera.position.x >= 0.5 and game.camera.position.x <= float(m.spec.width) - 1.5 and game.camera.position.z >= 0.5 and game.camera.position.z <= float(m.spec.height) - 1.5 and game.camera.position.y >= 5.0, "camera stays above geometry and inside board")
	game.zoom = 500; game._update_camera()
	check(game.zoom == 65.0, "zoom out still reaches whole map")
	check(RescueSettings.battle_value("fast_enemy") and RescueSettings.enemy_speed() == 2.0, "fast enemy turn is default")
	check(RescueSettings.set_battle_value("fast_enemy", false) and RescueSettings.enemy_speed() == 1.0, "normal enemy speed persists")
	check(RescueSettings.set_battle_value("fast_enemy", true) and RescueSettings.battle_value("fast_enemy"), "fast enemy speed persists")
	check(RescueSettings.set_battle_value("auto_select", true), "auto select enabled")
	var squad: Array = m.living("player")
	game.selected_id = int(squad[0].id)
	for u in squad: u.ap = 1
	game._after_action()
	await process_frame
	check(game.selected_id == int(squad[1].id), "action selects next ready unit")
	RescueSettings.set_battle_value("auto_select", false)
	game._after_action()
	check(game.selected_id == int(squad[1].id), "auto select toggle disables cycling")
	RescueSettings.set_battle_value("auto_select", true)
	game._request_end_turn()
	check(game.end_turn_armed and game.warning_label.text.contains("End turn?"), "end turn confirms when actions remain")
	game._cancel_order()
	for u in squad: u.ap = 0
	game._request_end_turn()
	check(not game.end_turn_armed, "end turn skips confirmation when no actions remain")
	game.queue_free(); await process_frame
	print("BATTLE11 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
