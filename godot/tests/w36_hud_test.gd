extends SceneTree
const Card = preload("res://scripts/w31e_enemy_card.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const OUT := "/home/jess/projects/tw-logs/w36/lane-hud/"
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1

func capture(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var err := image.save_png(OUT + name + ".png")
	check(err == OK, "capture " + name)

func run() -> void:
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1
	Phone.test_window_size = Vector2i(844, 390)
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 8: await process_frame
	game.demo_mode = true
	game.set_process(false)
	var hud = game.hud_controls.phone
	check(hud != null, "phone HUD at 844x390")
	var enemy: Dictionary = game.mission.living("enemy")[0]
	enemy.awake = true; enemy.spotted = true
	game._refresh_figures()
	game.playing_enemy_events = true
	game.phase_banner.text = "ALERT!"
	var card: PanelContainer = Card.show_actor(game, enemy, "Flanking the squad")
	hud._update_group_reveal()
	await process_frame
	var count := int(card.visible) + int(hud.enemy_card.visible) + int(hud.group_reveal.visible)
	print("W36 card visibility: ", card.visible, " ", hud.enemy_card.visible, " ", hud.group_reveal.visible)
	check(count == 1, "one enemy card or alert visible")
	var view: Node3D = game.views.get(int(enemy.id))
	check(view != null, "acting enemy view exists")
	var actor: Vector2 = game.camera.unproject_position(view.global_position + Vector3.UP) if view != null else Vector2(-10000, -10000)
	check(not card.get_global_rect().has_point(actor), "enemy card clears acting unit")
	check(card.get_global_rect().position.x >= 140 and card.get_global_rect().end.x <= 844, "enemy card in safe corner")
	hud.w36_show_enemy_callout(str(enemy.name), "Flanking", "MISS")
	check(card.get_node("CardLines/ActionResult").text == "MISS" and not hud.enemy_card.visible, "callout hook reuses actor card")
	var notes = game.get_node_or_null("ThreatNotes11")
	if notes != null:
		notes.reveal_text = "GROUP 2 REVEALED · 3 enemies: alert"
		notes.reveal_until = Time.get_ticks_msec() + 2000
		hud._update_group_reveal()
		check(card.get_node("CardLines/RevealLine").text.begins_with("GROUP 2") and not hud.group_reveal.visible, "reveal folds into actor card")
	await capture("after-enemy-844x390")
	if view != null:
		var original: Vector3 = view.global_position
		view.global_position = game.camera.project_position(card.get_global_rect().get_center(), 10.0) - Vector3.UP
		preload("res://scripts/w36hud_enemy_card.gd").place(game, card, int(enemy.id))
		var moved_actor: Vector2 = game.camera.unproject_position(view.global_position + Vector3.UP)
		check(not card.get_global_rect().has_point(moved_actor), "card switches corners when actor enters it")
		check(not card.get_global_rect().intersects(hud.ability_tray.get_global_rect()), "left corner clears action column")
		view.global_position = original
	Card.clear(game, true)
	game.playing_enemy_events = false
	hud._update_group_reveal()
	hud._toggle("more")
	await process_frame
	check(hud.more_back_button.visible and Rect2(Vector2.ZERO, Vector2(844, 390)).encloses(hud.more_back_button.get_global_rect()), "Back to battle stays in viewport")
	var first_rows: Array[String] = []
	for child in hud.popup_body.get_children():
		if child is Button and child.has_meta("ability_id"): first_rows.append(str(child.get_meta("ability_id")))
	check(not first_rows.is_empty(), "More starts with abilities")
	var contextual := true
	for id in first_rows:
		var source: Button = null
		for button in hud.ability_buttons:
			if button.ability_id == id: source = button; break
		var objective := ["free", "rescue", "hack", "evac", "extract", "interact"].any(func(word: String) -> bool: return id.to_lower().contains(word))
		if source == null or (source.disabled and not objective): contextual = false
	check(contextual, "first More rows are usable or objective actions")
	var toggle: Button = hud.more_other_button
	check(toggle.visible and not hud.more_other_expanded, "Other is collapsed by default")
	print("W36 More geometry: ", hud.popup.get_global_rect(), " scroll ", hud.detail_scroll.get_global_rect(), " Other ", toggle.get_global_rect(), " Back ", hud.more_back_button.get_global_rect())
	check(Rect2(Vector2.ZERO, Vector2(844, 390)).encloses(toggle.get_global_rect()), "collapsed Other row visible without scrolling")
	await capture("after-more-844x390")
	toggle.pressed.emit()
	await process_frame
	check(hud.more_other_expanded, "Other expands")
	await capture("after-more-expanded-844x390")
	var scroll = hud.detail_scroll
	scroll.finger_down = true
	var old_count: int = hud.popup_body.get_child_count()
	hud.refresh()
	check(hud.popup_body.get_child_count() == old_count, "More does not rebuild during drag")
	scroll.finger_down = false
	game.queue_free()
	for i in 4: await process_frame
	DisplayServer.window_set_size(Vector2i(390, 844))
	Phone.test_window_size = Vector2i(390, 844)
	root.size = Vector2i(390, 844); root.content_scale_size = root.size
	var portrait_game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(portrait_game)
	for i in 8: await process_frame
	portrait_game.demo_mode = true; portrait_game.set_process(false)
	var portrait_hud = portrait_game.hud_controls.phone
	portrait_hud._toggle("more")
	for i in 4: await process_frame
	print("W36 portrait geometry: ", portrait_hud.popup.get_global_rect(), " Back ", portrait_hud.more_back_button.get_global_rect())
	check(Rect2(Vector2.ZERO, Vector2(390, 844)).encloses(portrait_hud.more_back_button.get_global_rect()), "portrait Back stays in viewport")
	portrait_game.queue_free()
	for i in 4: await process_frame
	Phone.test_touch = -1; Phone.test_mobile = -1; Phone.test_scale = 0; Phone.test_window_size = Vector2i.ZERO
	print("W36 HUD RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
