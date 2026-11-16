extends SceneTree
const Phone = preload("res://scripts/phone_layout.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("W34A: " + label)

func frames(count: int = 5) -> void:
	for i in count: await process_frame

func tap(at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0; event.position = at; event.pressed = true
	root.push_input(event, true)
	event = InputEventScreenTouch.new()
	event.index = 0; event.position = at; event.pressed = false
	root.push_input(event, true)
	await process_frame

func run() -> void:
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1
	var inset_area := Vector2(690, 285)
	var inset_plate := Rect2(8, inset_area.y - 52, 220, 52)
	var inset_column: Rect2 = preload("res://scripts/w34a_action_column.gd").box(inset_area, inset_plate)
	check(inset_column.end.y <= inset_plate.position.y - 8 and inset_column.size.y >= 4 * 44, "landscape safe insets keep four targets above unit card")
	for size in [Vector2i(390, 844), Vector2i(956, 440), Vector2i(844, 390)]:
		root.size = size; root.content_scale_size = size
		DisplayServer.window_set_size(size)
		var flow: Node = root.get_node("CampaignFlow")
		flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
		flow.campaign.state.flow_stage = "battle"
		var squad: Array = flow.campaign.state.roster.slice(0, 5).map(func(member): return member.id)
		flow.campaign.state.pending_mission = {"mission_id": "relay", "squad": squad, "fewer": 0}
		var game: Node = load("res://scenes/rescue.tscn").instantiate()
		root.add_child(game)
		await frames(14)
		for member in game.mission.living("player"):
			if "shoot" in member.get("kit", []) and "overwatch" in member.get("kit", []):
				game._select(int(member.id)); break
		await frames(5)
		var hud = game.hud_controls.phone
		check(hud != null, "%s HUD" % size)
		if hud != null:
			var column: Rect2 = hud.ability_tray.get_global_rect()
			check(hud.ability_scroll.mouse_filter == Control.MOUSE_FILTER_IGNORE and not hud.ability_scroll.is_processing_input(), "%s column scroll cannot capture touch" % size)
			check(not hud.more_button.gui_input.is_connected(hud.ability_scroll._gui_input), "%s More has no scroll gesture handler" % size)
			check(column.position.x < size.x * 0.2, "%s column on left" % size)
			check(not column.intersects(hud.unit_plate.get_global_rect()), "%s clear of unit card" % size)
			check(not column.intersects(hud.threat_chip.get_global_rect()), "%s clear of threat chip" % size)
			check(not column.intersects(hud.end_button.get_global_rect()), "%s clear of End Turn" % size)
			check(not column.intersects(hud.odds_plate.get_global_rect()) and not column.intersects(hud.enemy_card.get_global_rect()), "%s odds and enemy card clear" % size)
			for control in hud.overlay.find_children("*", "Button", true, false):
				if not control.is_visible_in_tree(): continue
				var target: Vector2 = control.get_global_rect().size * hud.hud_scale28()
				check(target.x >= 52.8 and target.y >= 52.8, "%s %s touch target" % [size, control.name])
			var order: Array[String] = []
			for child in hud.ability_scroll.get_node("ActionColumn").get_children():
				if child is Button and child.visible:
					if child in hud.ability_buttons: order.append(child.ability_id)
					elif child == hud.more_button: order.append("more")
					check(child.get_global_rect().size.x * hud.hud_scale28() >= 52.8 and child.get_global_rect().size.y * hud.hud_scale28() >= 52.8, "%s %s target" % [size, child.name])
			check(order.size() >= 4 and order.slice(0, 3) == ["move", "shoot", "overwatch"] and order.back() == "more", "%s action order %s" % [size, order])
			for button in hud.ability_buttons:
				if not button.visible: continue
				var caption: String = preload("res://scripts/hud_phone_action_art.gd").caption_for(button.display_name)
				var width: float = preload("res://scripts/campaign/ui.gd").font("body").get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
				check(width <= button.size.x - 44 and hud.action_art.get_global_rect().encloses(button.get_global_rect()), "%s %s full caption" % [size, caption])
			var shoot: Button = null
			var move: Button = null
			for button in hud.ability_buttons:
				if button.ability_id == "shoot": shoot = button
				if button.ability_id == "move": move = button
			check(shoot != null and shoot.visible, "%s Shoot exposed" % size)
			check(move != null and not move.disabled, "%s Move enabled" % size)
			if shoot != null and shoot.visible:
				var before: int = int(shoot.get_meta("w28d_touch_count", 0))
				await tap(shoot.get_global_rect().get_center())
				check(int(shoot.get_meta("w28d_touch_count", 0)) > before, "%s Shoot receives touch" % size)
				game.action = "shoot"; game._refresh()
				await tap(move.get_global_rect().get_center())
				check(game.action == "move", "%s Move changes game action" % size)
				hud.ability_scroll.finger_down = true
				hud.ability_scroll.touch_dragging = true
				game.action = "shoot"; game._refresh()
				await tap(move.get_global_rect().get_center())
				check(game.action == "move", "%s stranded scroll gesture cannot lock actions" % size)
				hud.ability_scroll.finger_down = false
				hud.ability_scroll.touch_dragging = false
				root.size = size - Vector2i(0, 35); root.content_scale_size = root.size
				DisplayServer.window_set_size(root.size)
				await frames(8)
				game.action = "shoot"; game._refresh()
				before = int(shoot.get_meta("w28d_touch_count", 0))
				await tap(shoot.get_global_rect().get_center())
				check(int(shoot.get_meta("w28d_touch_count", 0)) > before, "%s touch after viewport resize" % size)
				await tap(move.get_global_rect().get_center())
				check(game.action == "move", "%s action works after viewport resize" % size)
				game.mission.phase = "enemy"; game.playing_enemy_events = true
				game._refresh(); await frames(3)
				game.mission.phase = "player"; game.playing_enemy_events = false
				game._refresh(); await frames(5)
				game.action = "shoot"; game._refresh()
				before = int(shoot.get_meta("w28d_touch_count", 0))
				await tap(shoot.get_global_rect().get_center())
				check(int(shoot.get_meta("w28d_touch_count", 0)) > before, "%s touch after enemy turn" % size)
				await tap(move.get_global_rect().get_center())
				check(game.action == "move", "%s action works after enemy turn" % size)
				game.player_attack_pending = true
				game.playing_enemy_events = true
				await create_timer(1.5).timeout
				check(not game.player_attack_pending and not game.playing_enemy_events, "%s idle player lock recovers" % size)
				await tap(hud.more_button.get_global_rect().get_center())
				check(hud.open_card == "more", "%s More opens by touch" % size)
				hud._close(); await frames(2)
				var turn: int = game.mission.turn
				await tap(hud.end_button.get_global_rect().get_center())
				check(hud.end_confirm, "%s End Turn arms by touch" % size)
				await create_timer(0.55).timeout
				await tap(hud.end_button.get_global_rect().get_center())
				await frames(5)
				check(game.mission.turn > turn and game.mission.phase == "player", "%s real enemy turn returns control" % size)
				if move != null:
					before = int(move.get_meta("w28d_touch_count", 0))
					await tap(move.get_global_rect().get_center())
					check(int(move.get_meta("w28d_touch_count", 0)) > before, "%s touch after real enemy turn" % size)
				var overwatch: Button = null
				for button in hud.ability_buttons:
					if button.ability_id == "overwatch": overwatch = button
				if overwatch != null and not overwatch.disabled:
					await tap(overwatch.get_global_rect().get_center())
					check(bool(game.mission.unit_by_id(game.selected_id).get("overwatch", false)), "%s Overwatch works by touch" % size)
		game.queue_free(); await frames(4)
	print("W34A: %d checks, %d failures" % [checks, failures])
	quit(failures)
