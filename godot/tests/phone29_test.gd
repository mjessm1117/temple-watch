extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Mission = preload("res://scripts/mission.gd")
const Frame = preload("res://scripts/w29a_phone_frame.gd")
const Cue = preload("res://scripts/w29a_move_cue.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, name: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("PHONE29 FAIL ", name)

func run() -> void:
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1
	var flow: Node = root.get_node("CampaignFlow")
	var sizes := [Vector2i(956, 440), Vector2i(844, 390), Vector2i(390, 844)]
	for size in sizes:
		root.size = size; root.content_scale_size = size
		DisplayServer.window_set_size(size)
		flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
		flow.campaign.state.flow_stage = "battle"
		var squad: Array = flow.campaign.state.roster.slice(0, 5).map(func(member): return member.id)
		flow.campaign.state.pending_mission = {"mission_id": "relay", "squad": squad, "fewer": 0}
		var game: Node = load("res://scenes/rescue.tscn").instantiate()
		root.add_child(game)
		for i in 12: await process_frame
		var hud = game.hud_controls.phone
		check(hud != null, "%s HUD" % size)
		if hud != null:
			var safe: Rect2 = hud.hud_safe_rect28().grow(-1.0)
			var bounds: Rect2 = Frame.unit_bounds(game)
			check(bounds.has_area() and safe.encloses(bounds), "%s selected unit inside safe map: %s in %s" % [size, bounds, safe])
			for button in hud.ability_buttons + [hud.more_button, hud.end_button]:
				if not button.visible: continue
				var font: Font = button.get_theme_font("font")
				var size_px: int = button.get_theme_font_size("font_size")
				var width: float = font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
				check(width <= button.size.x - 8.0, "%s %s glyph width %.1f <= %.1f" % [size, button.text, width, button.size.x - 8.0])
				check(font.get_height(size_px) <= button.size.y - 4.0, "%s %s glyph height" % [size, button.text])
				if button in hud.ability_buttons:
					var caption: String = preload("res://scripts/hud_phone_action_art.gd").caption_for(button.display_name)
					var caption_width: float = preload("res://scripts/campaign/ui.gd").font("body").get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
					check(caption_width <= button.size.x - 2.0 and hud.action_art.get_global_rect().encloses(button.get_global_rect()), "%s %s rendered caption inside action track" % [size, caption])
			check(hud.end_button.size.x >= 44 and hud.end_button.size.y >= 44, "%s end target" % size)
			var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
			var route: Dictionary = game.mission.paths(actor, int(actor.mob) * 2)
			for tile in route.costs:
				if tile == Vector2i(int(actor.x), int(actor.y)): continue
				game.preview_tile = tile
				game._refresh_highlights()
				hud._refresh_odds()
				check(hud.odds_plate.visible and hud.odds_badge.text.contains(" "), "%s preview and confirm show shield cue" % size)
				break
			var resized: Vector2i = sizes[(sizes.find(size) + 1) % sizes.size()]
			root.size = resized; root.content_scale_size = resized
			DisplayServer.window_set_size(resized)
			for i in 6: await process_frame
			check(hud.hud_safe_rect28().grow(-1.0).encloses(Frame.unit_bounds(game)), "%s to %s reflow keeps unit visible" % [size, resized])
			hud._end_turn()
			check(hud.end_confirm and hud.end_button.text == "CONFIRM" and hud.end_button.button_pressed, "%s first end tap arms" % size)
			hud.end_confirm = false
			hud.end_button.button_pressed = false
			for member in game.mission.living("player"): member.ap = 0
			hud._end_turn()
			check(hud.end_confirm and hud.end_button.button_pressed and game.mission.phase == "player", "%s spent squad first tap still arms" % size)
			hud._end_turn()
			check(hud.end_confirm and game.mission.phase == "player", "%s duplicate touch cannot spend confirmation" % size)
			game.mission.phase = "enemy"
			hud._end_turn()
			check(not hud.end_confirm and not hud.end_button.button_pressed, "%s enemy phase clears duplicate touch" % size)
		game.queue_free()
		await process_frame
	var relay = Mission.new(17, "res://data/maps/relay.json")
	var art = preload("res://scripts/map_presentation.gd").new()
	root.add_child(art)
	art.build(relay)
	check(art.batch.records.filter(func(record): return record.get("kind", "") == "evac").is_empty(), "defense has no evac marker")
	check(art.marker_root.find_children("*", "Label3D", true, false).any(func(node): return node.text == "HOLD ZONE"), "defense has hold marker")
	art.queue_free()
	var rescue = Mission.new(17, "res://data/maps/rescue.json")
	var long_objective := str(rescue.objective_status().get("label", ""))
	print("PHONE29 LONGEST OBJECTIVE: ", long_objective)
	check(long_objective.length() > 30, "long objective captured")
	var rescue_art = preload("res://scripts/map_presentation.gd").new()
	root.add_child(rescue_art)
	rescue_art.build(rescue)
	check(rescue_art.batch.records.filter(func(record): return record.get("kind", "") == "evac").is_empty(), "primary phase hides evac")
	rescue.objective_state.phase = "evac"
	rescue_art.refresh_markers(rescue)
	check(not rescue_art.batch.records.filter(func(record): return record.get("kind", "") == "evac").is_empty(), "evac phase shows evac")
	rescue_art.queue_free()
	var actor: Dictionary = rescue.living("player")[0]
	var tile := Vector2i(int(actor.x), int(actor.y)) + Vector2i(1, 0)
	var cue: Dictionary = Cue.at(rescue, actor, tile)
	check(str(cue.get("label", "")) != "" and str(cue.get("detail", "")) != "", "destination shield cue")
	var inset_tray: Rect2 = preload("res://scripts/hud_phone_layout.gd").boxes(Vector2(390 - 59, 844 - 34)).tray
	check(inset_tray.size.x >= 4.0 * 67.0 + 3.0 * 8.0, "portrait inset fits three actions and MORE")
	Phone.test_touch = -1; Phone.test_mobile = -1; Phone.test_scale = 0
	print("PHONE29 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
