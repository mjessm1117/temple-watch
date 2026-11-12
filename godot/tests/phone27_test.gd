extends SceneTree
const Phone = preload("res://scripts/phone_layout.gd")
const Touch = preload("res://scripts/touch_input.gd")
const Preview = preload("res://scripts/w27c_phone_preview.gd")
const Shot = preload("res://scripts/shot.gd")
const OUT := "/home/jess/projects/tw-logs/w27/phone/captures/"
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PHONE27: " + label)

func frames(count := 5) -> void:
	for i in count: await process_frame

func rect(button: Control) -> Rect2:
	var result := button.get_global_rect()
	var parent := button.get_parent()
	while parent is Control:
		if parent.clip_contents or parent is ScrollContainer: result = result.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return result

func buttons(node: Node, found: Array[BaseButton]) -> void:
	if node is BaseButton and node.is_visible_in_tree() and node.mouse_filter != Control.MOUSE_FILTER_IGNORE: found.append(node)
	for child in node.get_children(): buttons(child, found)

func capture(view: SubViewport, name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	DirAccess.make_dir_recursive_absolute(OUT)
	await frames(2)
	await RenderingServer.frame_post_draw
	check(view.get_texture().get_image().save_png(OUT + name + ".png") == OK, "capture " + name)

func scenario(size: Vector2i) -> void:
	DisplayServer.window_set_size(size)
	root.content_scale_size = size
	await frames(2)
	Phone.test_window_size = size
	Phone.test_touch = 1
	Phone.test_mobile = 1
	var view := SubViewport.new()
	view.size = size
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var game = load("res://scenes/rescue.tscn").instantiate()
	view.add_child(game)
	await frames(15)
	var hud = game.hud_controls.phone
	check(hud != null, str(size) + " phone HUD")
	if hud == null:
		view.queue_free(); return
	game._refresh()
	await frames(4)
	var menu: Control = hud.overlay.find_child("PhoneMenu", true, false)
	var end_rect := rect(hud.end_button)
	var menu_rect := rect(menu)
	print("PHONE27 GEOMETRY ", size, " end=", end_rect, " menu=", menu_rect)
	check(not end_rect.intersects(menu_rect) and end_rect.position.y - menu_rect.end.y >= 8.0, str(size) + " End Turn/menu separated vertically")
	check(Touch.UNIT_PICK_RADIUS27 > 28.0, "unit pick radius above 28")
	check(Touch.is_tap(17.0) and not Touch.is_tap(19.0), "18px tap/drag boundary")
	var picker := Touch.new(); picker.g = game
	var pick_unit: Dictionary = game.mission.living("player")[0]
	var pick_tile := Shot.pos(pick_unit)
	var pick_point: Vector2 = game.camera.unproject_position(Vector3(pick_tile.x, Shot.elevation(game.mission, pick_tile) * 0.7 + 1.0, pick_tile.y))
	game.action = "free"
	check(picker._pick_unit27(pick_point + Vector2(33, 0)), str(size) + " unit picks at 33px")
	if size.y > size.x:
		var preview := Preview.move_text({"cover":"full", "height":1, "flank":2, "events":[{"kind":"overwatch", "tile":Vector2i(4, 5), "source_name":"Trooper"}]})
		check(preview.contains("FULL COVER") and preview.contains("HEIGHT +1") and preview.contains("FLANK +2") and preview.contains("OVERWATCH Trooper"), "B preview facts fit one route card")
	var found: Array[BaseButton] = []
	buttons(hud.overlay, found)
	for i in found.size():
		var a := rect(found[i])
		if not a.has_area(): continue
		check(a.size.x >= 44 and a.size.y >= 44, str(size) + " >=44 " + found[i].name)
		for j in range(i + 1, found.size()):
			var b := rect(found[j])
			if b.has_area(): check(not a.intersects(b), str(size) + " nonoverlap " + found[i].name + "/" + found[j].name)
	await capture(view, "after-%dx%d-low-initial" % [size.x, size.y])
	var actor: Dictionary = {}
	for ally in game.mission.living("player"):
		if "shoot" in ally.get("kit", []): actor = ally; break
	var target: Dictionary = game.mission.living("enemy")[0]
	target.awake = true; target.spotted = true
	game.selected_id = int(actor.id); game.target_id = int(target.id); game.action = "shoot"
	game._refresh()
	await frames(6)
	check(hud.odds_plate.visible, str(size) + " single odds card visible")
	check(not game.hud_controls.preview_card26.visible, str(size) + " duplicate preview hidden")
	if hud.alerts != null: check(not hud.alerts.card.visible, "aim alert suppressed")
	var aim_buttons: Array[BaseButton] = []
	buttons(hud.overlay, aim_buttons)
	buttons(game.hud_controls.aim_ui.panel, aim_buttons)
	buttons(game.hud_controls.aim_ui.target_row, aim_buttons)
	for i in aim_buttons.size():
		var a := rect(aim_buttons[i])
		if not a.has_area(): continue
		check(a.size.x >= 44 and a.size.y >= 44, str(size) + " aim target >=44 " + aim_buttons[i].name)
		for j in range(i + 1, aim_buttons.size()):
			var b := rect(aim_buttons[j])
			if b.has_area(): check(not a.intersects(b), str(size) + " aim nonoverlap " + aim_buttons[i].name + "/" + aim_buttons[j].name)
	if size.y > size.x:
		check(not game.hud_controls.aim_ui.odds.get_parent().visible, "portrait inline odds hidden")
		check(hud.odds_scroll.visible, "portrait reasons visible")
		check(hud.odds_plate.get_global_rect().end.y < view.size.y * 0.43, "odds card stays above units")
		var phone_scale := float(size.x) / Phone.logical_size(size).x
		check(hud.odds_plate.get_global_rect().end.x * phone_scale < game.hud_controls.aim_ui.target_row.get_global_rect().position.x, "scaled portrait odds clears target selector")
	await capture(view, "after-%dx%d-low-aim" % [size.x, size.y])
	game.action = "free"; game.target_id = -1; game.mission.phase = "enemy"
	game.phase_banner.text = "Sith Trooper advances to cover"
	game.phase_banner.show()
	game._refresh(); await frames(2)
	hud._update_group_reveal()
	check(hud.enemy_card.visible, str(size) + " enemy card visible")
	check(not game.phase_banner.visible and not hud.alerts.card.visible if hud.alerts != null else not game.phase_banner.visible, str(size) + " only one enemy overlay")
	check(not hud.odds_plate.visible, str(size) + " no aim card on enemy turn")
	var visible_cards := int(hud.enemy_card.visible) + int(hud.odds_plate.visible)
	if hud.alerts != null: visible_cards += int(hud.alerts.card.visible)
	check(visible_cards <= 1, str(size) + " enemy overlay count <=1 plus objective strip")
	await capture(view, "after-%dx%d-low-enemy" % [size.x, size.y])
	view.queue_free()
	await frames(2)

func run() -> void:
	await scenario(Vector2i(390, 844))
	await scenario(Vector2i(844, 390))
	print("PHONE27: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
