extends SceneTree
## W19 aim framing, cover visibility, phone geometry, touch scrolling, and captures.
const Campaign = preload("res://scripts/campaign/state.gd")
const Camera = preload("res://scripts/cam_combat.gd")
const Art = preload("res://scripts/hud_phone_action_art.gd")
const Shot = preload("res://scripts/shot.gd")
const InputControls = preload("res://scripts/input_controls.gd")
const OUT := "/home/jess/projects/tw-logs/w19/battle/"
var checks := 0
var failures := 0
var capture := false

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("BATTLE19: " + label)

func resize(value: Vector2i) -> void:
	DisplayServer.window_set_size(value)
	root.size = value; root.content_scale_size = value
	await process_frame

func game_new():
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://battle19-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 8: await process_frame
	game.demo_mode = true; game.set_process(false)
	game.phase_banner.visible = false
	return game

func save(name: String, game = null) -> void:
	if not capture: return
	var night_was_processing := false
	if game != null:
		night_was_processing = game.hud_controls.night.is_processing()
		game.hud_controls.night.set_process(false)
		game.phase_banner.visible = false
		game.hud_controls.night.phase_plate.visible = false
		game.hud_controls.night.phase_plate.modulate.a = 0.0
	await create_timer(0.1).timeout
	check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK, "save " + name)
	if game != null: game.hud_controls.night.set_process(night_was_processing)

func clear_ray(m: RefCounted, eye: Vector3, target: Vector3) -> bool:
	# Independent fine-step ray against the map's drawn cover heights.
	for i in range(1, maxi(2, ceili(eye.distance_to(target) * 12.0))):
		var point := eye.lerp(target, float(i) / float(maxi(2, ceili(eye.distance_to(target) * 12.0))))
		var tile := Vector2i(roundi(point.x), roundi(point.z))
		var kind: String = m.tile(tile)
		var top := float(Shot.elevation(m, tile)) * 0.7 + (1.9 if kind == "#" else 0.8 if kind in ["c", "h", "k"] else 0.0)
		if kind in ["#", "c", "h", "k"] and point.y < top: return false
	return true

func body_rect(game, unit: Dictionary) -> Rect2:
	var at: Vector3 = game.views[int(unit.id)].global_position
	var result := Rect2()
	var first := true
	for x in [-0.3, 0.3]:
		for y in [0.0, 2.1]:
			for z in [-0.3, 0.3]:
				var screen: Vector2 = game.camera.unproject_position(at + Vector3(x, y, z))
				if first: result = Rect2(screen, Vector2.ZERO); first = false
				else: result = result.expand(screen)
	return result

func target_for(game, actor: Dictionary, offset: Vector2i) -> Dictionary:
	var target: Dictionary = game.mission.living("enemy")[0]
	target.x = int(actor.x) + offset.x; target.y = int(actor.y) + offset.y
	target.awake = true; target.spotted = true
	game._refresh_figures()
	return target

func aim_case(game, mode: String, actor: Dictionary, offset: Vector2i, label: String, image_name: String = "") -> void:
	game._select(int(actor.id))
	if game.camera_tween != null and game.camera_tween.is_running(): game.camera_tween.kill()
	game.pivot = Vector3(actor.x, 0, actor.y)
	game.zoom = preload("res://scripts/battle11_camera.gd").selected_zoom(game.mission)
	game._update_camera()
	var battle_height: float = game.camera.position.y
	var target := target_for(game, actor, offset)
	game.action = mode; game.target_id = int(target.id)
	game._frame_target(); game._refresh()
	for i in 32: await process_frame
	var eye: Vector3 = game.camera.position
	var from := Vector3(float(actor.x), Shot.elevation(game.mission, Shot.pos(actor)) * 0.7, float(actor.y))
	var to := Vector3(float(target.x), Shot.elevation(game.mission, Shot.pos(target)) * 0.7, float(target.y))
	var forward := to - from; forward.y = 0; forward = forward.normalized()
	var aim = game.hud_controls.aim_ui
	var screen: Vector2 = game.camera.unproject_position(to + Vector3.UP * 1.25)
	var viewport := Rect2(Vector2.ZERO, root.size)
	check(eye.y < battle_height and eye.y <= from.y + 3.5, label + " lower than battle camera")
	check((eye - from).dot(forward) < -0.2, label + " behind shooter")
	check(viewport.has_point(screen) and not game.camera.is_position_behind(to + Vector3.UP * 1.25), label + " target on screen")
	check(not aim.panel.get_global_rect().has_point(screen) and (aim.target_row == null or not aim.target_row.get_global_rect().has_point(screen)), label + " target clears aim cards")
	check(not body_rect(game, target).intersects(aim.panel.get_global_rect()), label + " target body clears aim card: %s vs %s" % [body_rect(game, target), aim.panel.get_global_rect()])
	check(clear_ray(game.mission, eye, to + Vector3.UP * 1.25), label + " camera ray clear")
	check(aim.panel.visible and game.cam.preview_active, label + " aim preview active")
	await save(image_name)
	game._cancel_order(); await process_frame
	check(not game.cam.preview_active and not game.cinematic and not aim.panel.visible, label + " CANCEL returns battle camera")
	check(game.camera.position.y > eye.y + 1.0, label + " battle camera height restored")

func touch_scroll(phone, label: String) -> void:
	var actions = phone.ability_scroll
	var spacer := Control.new(); spacer.custom_minimum_size.x = 400
	actions.get_child(0).add_child(spacer)
	await process_frame
	var action_start: Vector2 = phone.ability_buttons[0].get_global_rect().get_center()
	check(phone.ability_buttons[0].mouse_filter == Control.MOUSE_FILTER_PASS, label + " ability button passes finger drag to scroll")
	var action_press := InputEventScreenTouch.new(); action_press.position = action_start; action_press.pressed = true
	actions._gui_input(action_press)
	var action_drag := InputEventScreenDrag.new(); action_drag.position = action_start + Vector2(-100, 0); action_drag.relative = Vector2(-100, 0)
	actions._gui_input(action_drag)
	check(actions.scroll_horizontal > 0, label + " ability scroll drags from button")
	var action_position: int = actions.scroll_horizontal
	phone.refresh(); await process_frame
	check(actions.scroll_horizontal == action_position, label + " ability scroll holds mid-drag")
	var action_release := InputEventScreenTouch.new(); action_release.position = action_drag.position; action_release.pressed = false
	actions._gui_input(action_release)
	spacer.queue_free()
	actions.scroll_horizontal = 0
	phone._show_menu()
	await process_frame
	var scroll = phone.detail_scroll
	check(scroll != null and scroll.visible and scroll.get_v_scroll_bar().max_value > scroll.size.y, label + " more list scrollable")
	var button: Button = null
	for child in phone.popup_body.get_children():
		if child is Button: button = child; break
	if button == null: check(false, label + " scroll button exists"); return
	check(button.mouse_filter == Control.MOUSE_FILTER_PASS, label + " popup button passes finger drag to scroll")
	var at: Vector2 = button.get_global_rect().get_center()
	var press := InputEventScreenTouch.new(); press.position = at; press.pressed = true
	scroll._gui_input(press)
	var moved := at
	for step in 10:
		var next := at + Vector2(0, -14.0 * float(step + 1))
		var drag := InputEventScreenDrag.new(); drag.position = next; drag.relative = next - moved
		scroll._gui_input(drag); moved = next
		phone.refresh()
		await process_frame
	var after: int = scroll.scroll_vertical
	check(after > 0, label + " drag from button scrolls")
	phone.refresh(); await process_frame
	check(scroll.scroll_vertical == after, label + " refresh preserves mid-drag scroll")
	var release := InputEventScreenTouch.new(); release.position = moved; release.pressed = false
	scroll._gui_input(release)
	phone._close()

func phone_case(size: Vector2i) -> void:
	await resize(size)
	var game = await game_new()
	var phone = game.hud_controls.phone
	check(phone != null, "%s phone HUD" % size)
	game.mission.chain_momentum = 3; game._refresh()
	for i in 4: await process_frame
	var pips: Rect2 = phone.momentum_pips.get_global_rect()
	var hint: Rect2 = phone.action_name.get_global_rect()
	check(not pips.intersects(hint), "%s Momentum clears MOVE hint" % size)
	check(phone.unit_portrait.size.x >= 52 and phone.unit_portrait.size.y >= 52 and phone.unit_portrait.texture != null, "%s larger existing portrait" % size)
	check(not phone.unit_portrait.get_global_rect().intersects(phone.unit_card.get_global_rect()), "%s portrait clears unit text" % size)
	check(not phone.unit_plate.get_global_rect().intersects(phone.ability_tray.get_global_rect()), "%s plate clears tray: %s %s" % [size, phone.unit_plate.get_global_rect(), phone.ability_tray.get_global_rect()])
	for button in phone.ability_buttons:
		if button.display_name == "": continue
		var caption: String = Art.caption_for(button.display_name)
		check(not caption.contains("…"), "%s %s label not ellipsized" % [size, button.ability_id])
		if button.display_name.to_upper().begins_with("SABER "):
			check(caption == "SABER", "%s Saber full short label" % size)
		var font := ThemeDB.fallback_font
		check(font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x <= button.size.x - 4, "%s %s '%s' width %.1f fits in %s" % [size, button.ability_id, caption, font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x, button.size])
	await save("hud-%dx%d" % [size.x, size.y], game)
	if "--hud-only" in OS.get_cmdline_user_args():
		game.queue_free(); await process_frame
		return
	await touch_scroll(phone, str(size))
	var soldier: Dictionary = {}
	var jedi: Dictionary = {}
	for unit in game.mission.living("player"):
		if soldier.is_empty() and "shoot" in unit.get("kit", []): soldier = unit
		if jedi.is_empty() and "push" in unit.get("kit", []): jedi = unit
	check(not soldier.is_empty() and not jedi.is_empty(), "%s rifle and Jedi available" % size)
	if not soldier.is_empty():
		await aim_case(game, "shoot", soldier, Vector2i(2, -2), str(size) + " rifle", "aim-rifle-844x390" if size.x == 844 else "")
		if size.x == 844:
			var first_target := target_for(game, soldier, Vector2i(2, -2))
			var second_target: Dictionary = game.mission.living("enemy")[1]
			second_target.x = int(soldier.x) + 2; second_target.y = int(soldier.y) + 1
			second_target.awake = true; second_target.spotted = true
			game._refresh_figures()
			game.action = "shoot"; game.target_id = int(first_target.id); game._frame_target(); game._refresh()
			for i in 24: await process_frame
			var first_eye: Vector3 = game.camera.position
			var first_id: int = game.target_id
			game._cycle_target(1); game._refresh()
			for i in 24: await process_frame
			check(game.target_id != first_id and game.camera.position.distance_to(first_eye) > 0.1, "cycling target reframes aim")
			game._cancel_order()
		var target := target_for(game, soldier, Vector2i(3, -1))
		game.action = "shoot"; game.target_id = int(target.id); game._frame_target(); game._refresh()
		for i in 32: await process_frame
		await game._attack(game.target_id, "shoot")
		for i in 4: await process_frame
		check(not game.cam.preview_active and not game.cinematic and game.action == "move", "%s shot returns battle camera" % size)
	if size.x == 844 and not jedi.is_empty():
		await aim_case(game, "push", jedi, Vector2i(2, -1), "Jedi Force", "aim-jedi-force-844x390")
		if game.mission.abilities.has("saberThrow"):
			await aim_case(game, "saberThrow", jedi, Vector2i(2, -1), "thrown saber")
		# Place full cover close to the shooter and verify the chosen ray remains clear.
		var cover := Vector2i(int(soldier.x) + 1, int(soldier.y) - 1)
		game.mission.set_tile(cover, "#"); game._build_terrain()
		await aim_case(game, "shoot", soldier, Vector2i(3, -2), "cramped cover", "aim-cramped-cover-844x390")
	game.queue_free(); await process_frame

func desktop_case() -> void:
	await resize(Vector2i(1366, 768))
	var game = await game_new()
	var soldier: Dictionary = {}
	for unit in game.mission.living("player"):
		if "shoot" in unit.get("kit", []): soldier = unit; break
	if not soldier.is_empty(): await aim_case(game, "shoot", soldier, Vector2i(2, -2), "desktop rifle")
	game.queue_free(); await process_frame

func run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	if capture: DirAccess.make_dir_recursive_absolute(OUT)
	await phone_case(Vector2i(667, 375))
	await phone_case(Vector2i(844, 390))
	if "--hud-only" not in OS.get_cmdline_user_args(): await desktop_case()
	print("BATTLE19 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
