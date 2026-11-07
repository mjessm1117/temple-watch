extends SceneTree
## Landscape phone playtest: real HUD geometry, camera, action points and finger input.
const Campaign = preload("res://scripts/campaign/state.gd")
const InputControls = preload("res://scripts/input_controls.gd")
const Rules = preload("res://scripts/rules12_actions.gd")
const Shot = preload("res://scripts/shot.gd")
var checks := 0
var failures := 0
var capture := false
var before := false

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PHONE17: " + label)

func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0; event.position = at; event.pressed = pressed
	root.push_input(event, true)

func drag(from: Vector2, to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0; event.position = to; event.relative = to - from
	root.push_input(event, true)

func swipe(at: Vector2, delta: Vector2) -> void:
	touch(at, true)
	var previous := at
	for step in 8:
		var next := at + delta * float(step + 1) / 8.0
		drag(previous, next); previous = next
		await process_frame
	touch(previous, false)
	await process_frame

func visible_rect(control: Control) -> Rect2:
	var area := control.get_global_rect().intersection(Rect2(Vector2.ZERO, Vector2(root.size)))
	var parent := control.get_parent()
	while parent is Control:
		if parent.clip_contents or parent is ScrollContainer: area = area.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return area

func in_scroll(control: Control) -> bool:
	var parent := control.get_parent()
	while parent is Control:
		if parent is ScrollContainer: return true
		parent = parent.get_parent()
	return false

func controls(node: Node, result: Array[BaseButton]) -> void:
	if node is BaseButton and node.is_visible_in_tree() and not node.disabled and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		result.append(node)
	for child in node.get_children(): controls(child, result)

func geometry(game: Node, label: String) -> void:
	await process_frame
	var buttons: Array[BaseButton] = []
	controls(game.hud_controls.phone.overlay, buttons)
	controls(game.hud_controls.aim_ui.panel, buttons)
	var count := 0
	var minimum := Vector2(INF, INF)
	for i in buttons.size():
		var a := visible_rect(buttons[i])
		if not a.has_area(): continue
		count += 1
		minimum = Vector2(minf(minimum.x, a.size.x), minf(minimum.y, a.size.y))
		check(a.size.x >= 44.0 and a.size.y >= 44.0, "%s %s visible hit area %s" % [label, buttons[i].name, a])
		if not in_scroll(buttons[i]):
			check(a.position.distance_to(buttons[i].get_global_rect().position) < 0.1 and a.size.distance_to(buttons[i].get_global_rect().size) < 0.1, "%s %s not clipped %s / %s" % [label, buttons[i].name, a, buttons[i].get_global_rect()])
		for j in range(i + 1, buttons.size()):
			var b := visible_rect(buttons[j])
			if b.has_area(): check(not a.intersects(b), "%s %s overlaps %s" % [label, buttons[i].name, buttons[j].name])
	print("PHONE17 GEOMETRY %s controls=%d min_visible=%s" % [label, count, minimum])

func shot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	var path := "res://../docs/godot/shots/w17-phone-%s.png" % name
	if before: path = "/tmp/w17-phone-before-%s.png" % name
	check(root.get_texture().get_image().save_png(path) == OK, "save " + path)

func setup(size: Vector2i) -> Node:
	DisplayServer.window_set_size(size)
	root.size = size; root.content_scale_size = size
	await process_frame
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://phone17-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	RescueSettings.set_battle_value("auto_select", false)
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 6: await process_frame
	game.demo_mode = true
	return game

func exercise(size: Vector2i) -> void:
	var game = await setup(size)
	var tag := str(size.x)
	var phone = game.hud_controls.phone
	check(phone != null, tag + " phone HUD")
	check(game.action == "move" and game.range_highlights.get_child_count() > 0, tag + " move tiles light automatically")
	var unit: Dictionary = game.mission.living("player")[1]
	var yaw: float = game.yaw
	game._select(int(unit.id))
	await create_timer(0.42).timeout
	check(game.selected_id == int(unit.id), tag + " selected unit")
	check(is_equal_approx(game.yaw, yaw), tag + " selection has no camera spin")
	check(absf(game.zoom - game.BattleCamera.selected_zoom(game.mission)) < 0.2, tag + " selected zoom")
	check(Vector2(game.pivot.x, game.pivot.z).distance_to(Vector2(unit.x, unit.y)) < 2.0, "%s camera follows selected unit pivot=%s unit=%s" % [tag, game.pivot, Vector2(unit.x, unit.y)])
	await geometry(game, tag + " select")
	await create_timer(1.25).timeout
	await shot("select-" + tag)
	if "--aim-only" in OS.get_cmdline_user_args():
		var shooter: Dictionary = {}
		for member in game.mission.living("player"):
			if "shoot" in member.get("kit", []): shooter = member; break
		game._select(int(shooter.id))
		var target: Dictionary = game.mission.living("enemy")[0]
		target.x = int(shooter.x) + 2; target.y = int(shooter.y)
		target.awake = true; target.spotted = true
		game._refresh_figures(); game._choose_action("shoot")
		await create_timer(0.45).timeout
		await geometry(game, tag + " aim-only")
		await shot("aim-" + tag)
		game.queue_free(); await process_frame
		return
	# Move and capture before the gesture tests resize the ability tray.
	var route: Dictionary = game.mission.reach_tiles(unit, 1)
	var destination := Vector2i(-1, -1)
	for p in route.costs:
		if int(route.costs[p]) == 1: destination = p; break
	if destination.x >= 0:
		game._move_selected(destination)
		var movement_started := Time.get_ticks_msec()
		while game.player_attack_pending and Time.get_ticks_msec() - movement_started < 30000:
			await process_frame
		await create_timer(0.38).timeout
		check(not game.player_attack_pending, tag + " movement presentation completes")
		check(int(unit.ap) == 1, tag + " move spends one AP")
		check(phone.unit_card.text.contains("AP 1/2"), "%s AP pips update text=%s" % [tag, phone.unit_card.text])
		check(Vector2(game.pivot.x, game.pivot.z).distance_to(Vector2(unit.x, unit.y)) < 2.0, "%s camera stays with moved unit pivot=%s unit=%s" % [tag, game.pivot, Vector2(unit.x, unit.y)])
		await shot("move-" + tag)
	else: check(false, tag + " one-step move exists")
	# A non-scrolling card drag pans the board and cannot open the card.
	var card: Button = phone.unit_card
	var card_at := card.get_global_rect().get_center()
	var old_pivot: Vector3 = game.pivot
	var old_card: String = phone.open_card
	await swipe(card_at, Vector2(-100, 0))
	check(phone.open_card == old_card, "%s unit card drag does not activate card=%s" % [tag, phone.open_card])
	check(game.pivot.distance_to(old_pivot) > 0.03, "%s unit card drag pans from=%s to=%s" % [tag, old_pivot, game.pivot])
	# Battle ability buttons sit inside a horizontal scroll area.
	var scroll: ScrollContainer = phone.overlay.find_child("Abilities", true, false)
	var button: Button = phone.ability_buttons[0]
	var original_action: String = game.action
	phone.ability_tray.offset_left = -100; phone.ability_tray.offset_right = 100
	await process_frame
	await swipe(button.get_global_rect().get_center(), Vector2(-96, 0))
	check(scroll.scroll_horizontal > 0, tag + " button drag scrolls abilities")
	check(game.action == original_action, tag + " button drag does not activate")
	phone.ability_tray.offset_left = -minf(340.0, size.x * 0.47)
	phone.ability_tray.offset_right = minf(340.0, size.x * 0.47)
	scroll.scroll_horizontal = 0
	phone._toggle("unit")
	await process_frame
	var popup_scroll: ScrollContainer = phone.detail_scroll
	var member_button: Button = phone.popup_body.get_child(1).get_child(0)
	var selected_before: int = game.selected_id
	var member_at := member_button.get_global_rect().get_center()
	touch(member_at, true)
	var previous := member_at
	var last_scroll := popup_scroll.scroll_vertical
	for step in 8:
		var next := member_at + Vector2(0, -12 * (step + 1))
		drag(previous, next); previous = next
		phone.refresh()
		await process_frame
		check(popup_scroll.scroll_vertical >= last_scroll, tag + " detail scroll never resets mid-drag")
		last_scroll = popup_scroll.scroll_vertical
	touch(previous, false); await process_frame
	check(popup_scroll.scroll_vertical > 0, tag + " nested unit detail scroll moves")
	check(game.selected_id == selected_before, tag + " member button drag does not select")
	phone._close()
	# Board pan is never a tile tap, even if it ends over a valid destination.
	var tile := Vector2i(int(unit.x), int(unit.y))
	var at: Vector2 = game.camera.unproject_position(Vector3(tile.x, 1.0, tile.y))
	var ap_before: int = int(unit.ap)
	old_pivot = game.pivot
	await swipe(at + Vector2(75, 0), Vector2(-70, 30))
	check(game.pivot.distance_to(old_pivot) > 0.03, tag + " board drag pans")
	check(int(unit.ap) == ap_before and game.preview_tile.x < 0, tag + " board drag never moves or selects a tile")
	# Place visible enemies at distinct ranges to check nearest-first aiming.
	var actor: Dictionary = {}
	for member in game.mission.living("player"):
		if "shoot" in member.get("kit", []): actor = member; break
	check(not actor.is_empty(), tag + " shooter exists")
	if not actor.is_empty():
		game._select(int(actor.id))
		var enemies: Array[Dictionary] = game.mission.living("enemy")
		for i in mini(2, enemies.size()):
			enemies[i].x = int(actor.x) + 3 - i
			enemies[i].y = int(actor.y)
			enemies[i].awake = true; enemies[i].spotted = true
		game._refresh_figures()
		await create_timer(0.4).timeout
		var tapped: Dictionary = enemies[1] if enemies.size() > 1 else enemies[0]
		var tapped_at: Vector2 = game.camera.unproject_position(Vector3(tapped.x, 1.0, tapped.y))
		touch(tapped_at, true); touch(tapped_at, false)
		await process_frame
		check(game.action == "shoot" and game.target_id == int(tapped.id), tag + " enemy tap enters aim on tapped enemy")
		game._cancel_order()
		game._choose_action("shoot")
		await process_frame
		var options: Array[Dictionary] = InputControls.valid_targets(game.mission, actor, "shoot")
		if not options.is_empty():
			check(int(options[0].id) == int(tapped.id), tag + " nearer target sorts ahead of lower ID")
			check(game.target_id == int(options[0].id), tag + " Fire starts at nearest target")
			check(game.hud_controls.aim_ui.panel.visible, tag + " aim strip visible")
			var chip: Button = game.hud_controls.aim_ui.targets.get_child(0)
			check(chip.text.contains("% HIT"), tag + " hit chance shown on target")
			check(game.hud_controls.aim_ui.confirm.text.begins_with("CONFIRM"), tag + " single Confirm")
			await geometry(game, tag + " aim")
			await shot("aim-" + tag)
			game._cancel_order()
		else: check(false, tag + " legal target for aim")
	var following_enemy: Dictionary = game.mission.living("enemy")[0]
	var enemy_view = game.views[int(following_enemy.id)]
	var old_yaw: float = game.yaw
	var enemy_point := Vector3(enemy_view.position.x, 0.0, enemy_view.position.z)
	var old_distance: float = game.pivot.distance_to(enemy_point)
	enemy_view.travel([enemy_view.position + Vector3(1.0, 0.0, 0.0)])
	game.playing_enemy_events = true
	await process_frame
	game.cam._process(0.1)
	check(game.pivot.distance_to(enemy_point) < old_distance, tag + " enemy motion pulls camera toward actor")
	check(is_equal_approx(game.yaw, old_yaw), tag + " enemy follow does not spin")
	game.playing_enemy_events = false
	if enemy_view.motion != null and enemy_view.motion.is_running(): enemy_view.motion.kill()
	game.queue_free(); await process_frame
	var squad = load("res://scenes/squad.tscn").instantiate()
	root.add_child(squad); await process_frame
	squad.inspect(0); await process_frame
	var roster: ScrollContainer = squad.card_scroll
	roster.size.x = 300
	await process_frame
	var portrait: Button = squad.card_row.get_child(1).get_child(0).get_child(0)
	var focus_before: int = squad.focus_index
	await swipe(portrait.get_global_rect().get_center(), Vector2(-96, 0))
	check(roster.scroll_horizontal > 0, tag + " portrait card drag scrolls roster")
	check(squad.focus_index == focus_before, tag + " portrait card drag does not select")
	var arsenal: ScrollContainer = squad.arsenal.get_parent()
	var slot: Button = squad.arsenal.slot_row.get_node("Slot_armor")
	var active_before: String = squad.arsenal.active_slot
	var arsenal_overflows: bool = arsenal.get_v_scroll_bar().max_value > arsenal.get_v_scroll_bar().page + 1.0
	await swipe(slot.get_global_rect().get_center(), Vector2(0, -96))
	check(arsenal.scroll_vertical > 0 if arsenal_overflows else arsenal.scroll_vertical == 0, tag + " nested arsenal scroll moves when content overflows")
	check(squad.arsenal.active_slot == active_before, tag + " arsenal button drag does not activate")
	squad.queue_free(); await process_frame

func rules() -> void:
	var game = await setup(Vector2i(844, 390))
	var m = game.mission
	var actor: Dictionary = m.living("player")[0]
	var origin := Shot.pos(actor)
	var one: Dictionary = m.reach_tiles(actor, 1)
	var first := Vector2i(-1, -1)
	for p in one.costs:
		if int(one.costs[p]) == 1: first = p; break
	check(first.x >= 0 and m.move(int(actor.id), first), "first move costs one action")
	check(int(actor.ap) == 1, "move leaves one action")
	one = m.reach_tiles(actor, 1)
	var second := Vector2i(-1, -1)
	for p in one.costs:
		if int(one.costs[p]) == 1 and p != origin: second = p; break
	check(second.x >= 0 and m.move(int(actor.id), second), "move plus move allowed")
	check(int(actor.ap) == 0, "second move spends last action")
	actor.ap = 2; actor.x = origin.x; actor.y = origin.y
	var dash: Dictionary = m.reach_tiles(actor, 2)
	var far := Vector2i(-1, -1)
	for p in dash.costs:
		if int(dash.costs[p]) > int(actor.mob): far = p; break
	check(far.x >= 0 and m.move(int(actor.id), far), "dash reachable")
	check(int(actor.ap) == 0, "dash spends both actions")
	actor.ap = 2; actor.x = origin.x; actor.y = origin.y
	var watcher: Dictionary = {}
	for u in m.living("player"):
		if "overwatch" in u.get("kit", []): watcher = u; break
	check(not watcher.is_empty(), "overwatch unit exists")
	if not watcher.is_empty():
		watcher.ap = 2
		check(m.overwatch(int(watcher.id)), "overwatch accepted")
		check(int(watcher.ap) == 0, "overwatch ends turn")
	var shooter: Dictionary = {}
	for u in m.living("player"):
		if "shoot" in u.get("kit", []): shooter = u; break
	if not shooter.is_empty():
		shooter.ap = 2; shooter.overwatch = false
		var steps: Dictionary = m.reach_tiles(shooter, 1)
		var firing_tile := Vector2i(-1, -1)
		for p in steps.costs:
			if int(steps.costs[p]) == 1: firing_tile = p; break
		check(firing_tile.x >= 0 and m.move(int(shooter.id), firing_tile), "move before fire accepted")
		check(int(shooter.ap) == 1, "move before fire leaves one action")
		var enemy: Dictionary = m.living("enemy")[0]
		enemy.awake = true; enemy.spotted = true
		var targets: Array[Dictionary] = []
		for delta in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2), Vector2i(3, 0), Vector2i(0, 3)]:
			var candidate: Vector2i = Shot.pos(shooter) + delta
			if not m.in_bounds(candidate): continue
			enemy.x = candidate.x; enemy.y = candidate.y
			targets = InputControls.valid_targets(m, shooter, "shoot")
			if not targets.is_empty(): break
		if not targets.is_empty():
			check(m.shot(int(shooter.id), int(targets[0].id)), "move plus fire allowed")
			check(int(shooter.ap) == 0, "fire ends turn")
		else: check(false, "legal shot for AP audit")
	for id in m.abilities:
		var def: Dictionary = m.abilities[id]
		var probe := {"ap": 2}
		var cost: int = Rules.cost(def, probe)
		Rules.spend(probe, def)
		check(int(probe.ap) == (0 if bool(def.get("ends_turn", false)) else maxi(0, 2 - cost)), "data AP cost " + str(id))
	for u in m.living("player"): u.ap = 0
	game._refresh()
	check(game.hud_controls.phone.end_pulse != null, "all-spent End Turn prompt pulses")
	game.queue_free(); await process_frame

func run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	before = "--before" in OS.get_cmdline_user_args()
	var shell := FileAccess.get_file_as_string("res://web/shell.html")
	check(shell.contains("overscroll-behavior: none") and shell.contains("body { position: fixed") and shell.contains("touch-action: none"), "web shell keeps document fixed against rubber-banding")
	check(shell.contains("addEventListener('touchmove'") and shell.contains("event.preventDefault()") and shell.contains("passive: false"), "web shell blocks Safari page touch scroll")
	var sizes: Array[Vector2i] = [Vector2i(844, 390), Vector2i(932, 430), Vector2i(667, 375)]
	if "--only844" in OS.get_cmdline_user_args(): sizes = [Vector2i(844, 390)]
	if "--only667" in OS.get_cmdline_user_args(): sizes = [Vector2i(667, 375)]
	for size in sizes:
		await exercise(size)
	if not before and not "--aim-only" in OS.get_cmdline_user_args(): await rules()
	print("PHONE17 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
