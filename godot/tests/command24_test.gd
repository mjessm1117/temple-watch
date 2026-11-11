extends SceneTree
const Controls = preload("res://scripts/input_controls.gd")
const Shot = preload("res://scripts/shot.gd")
const Grid = preload("res://scripts/map_art_grid.gd")
var checks := 0
var failures := 0

class BusyGame:
	extends RefCounted
	signal input_busy_changed24(busy: bool)
	var mission: RefCounted
	var selected_id: int
	var selected_calls := 0
	var busy := true
	var hit_tile := Vector2i(-1, -1)
	func is_input_busy24() -> bool: return busy
	func _select(id: int) -> void: selected_id = id; selected_calls += 1
	func _screen_tile(_point: Vector2) -> Vector2i: return hit_tile

class AimGame:
	extends Node
	var cycles := 0
	func _cycle_target(direction: int) -> void: cycles += direction

class KeyGame:
	extends RefCounted
	var mission: RefCounted
	var selected_id: int
	var chosen := ""
	func _choose_action(action: String) -> void: chosen = action

class MoveGame:
	extends Node
	var action := "move"
	var preview_tile := Vector2i(2, 3)
	var canceled := 0
	var moved := 0
	func _cancel_order() -> void: canceled += 1
	func _move_selected(_tile: Vector2i) -> void: moved += 1

func _initialize() -> void: run.call_deferred()

func check(ok: bool, name: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(name)

func key(game: Node, code: int) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.pressed = true
	game._unhandled_input(event)

func mouse(game: Node, code: int, position: Vector2) -> void:
	var event := InputEventMouseButton.new(); event.button_index = code; event.position = position; event.pressed = true
	game._unhandled_input(event)
	if code == MOUSE_BUTTON_RIGHT:
		event = InputEventMouseButton.new(); event.button_index = code; event.position = position; event.pressed = false
		game._unhandled_input(event)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game); await process_frame
	game.demo_mode = true; game.set_process(false)
	var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	var bindings: Dictionary = Controls.bindings24()
	check(KEY_R in bindings.reload and KEY_Y in bindings.overwatch, "R reload and Y overwatch defaults")
	check(KEY_END in bindings.end_turn and KEY_BACKSPACE in bindings.end_turn, "both end-turn keys")
	check(KEY_8 in bindings.ability8 and KEY_9 in bindings.ability9 and KEY_0 in bindings.ability10, "abilities 8-10 bindings")
	check(KEY_TAB in bindings.next_unit and KEY_ENTER in bindings.confirm and KEY_ESCAPE in bindings.cancel, "legacy keys retained")
	var cfg := ConfigFile.new(); cfg.set_value("controls", "keymap", {"reload": ["T"], "overwatch": ["U"]})
	check(cfg.save("user://controls24.cfg") == OK, "keymap fixture saved")
	bindings = Controls.bindings24()
	check(KEY_T in bindings.reload and KEY_R not in bindings.reload and KEY_U in bindings.overwatch, "keymap overrides defaults")
	var reload_unit: Dictionary = {}
	for unit in game.mission.living("player"):
		if "reload" in unit.get("kit", []): reload_unit = unit; break
	if not reload_unit.is_empty():
		var key_game := KeyGame.new(); key_game.mission = game.mission; key_game.selected_id = int(reload_unit.id)
		var key_controls := Controls.new(); key_controls.g = key_game
		var reload_key := InputEventKey.new(); reload_key.keycode = KEY_T; reload_key.pressed = true
		key_controls.handle_event(reload_key)
		check(key_game.chosen == "reload", "remapped reload executes without restart")
		cfg.set_value("controls", "keymap", {}); cfg.save("user://controls24.cfg")
		reload_key.keycode = KEY_R; key_game.chosen = ""
		key_controls.handle_event(reload_key)
		check(key_game.chosen == "reload", "R executes reload without scene restart")
		var extras := Controls.extra_abilities24(reload_unit)
		for i in range(mini(3, extras.size())):
			reload_key.keycode = [KEY_8, KEY_9, KEY_0][i]; key_game.chosen = ""
			key_controls.handle_event(reload_key)
			check(key_game.chosen == extras[i], "number key selects ability %d" % (i + 8))
	cfg.set_value("controls", "keymap", {}); cfg.set_value("controls", "confirm_move", true); cfg.save("user://controls24.cfg")
	check(Controls.confirm_move24(false), "confirm_move setting overrides mouse default")
	cfg.set_value("controls", "confirm_move", false); cfg.save("user://controls24.cfg")
	check(not Controls.confirm_move24(true), "confirm_move setting overrides touch default")
	var path: Dictionary = game.mission.paths(actor, int(actor.mob))
	var destination := Vector2i(-1, -1)
	for tile in path.costs:
		if tile != Shot.pos(actor): destination = tile; break
	check(destination.x >= 0, "reachable move fixture")
	if destination.x >= 0:
		var center: Vector2 = game.camera.unproject_position(Vector3(destination.x, Shot.elevation(game.mission, destination) * 0.7 + 0.15, destination.y))
		check(Controls.magnet_tile24(game, center + Vector2(10, 5), actor) == destination, "28 px destination magnet")
		mouse(game, MOUSE_BUTTON_LEFT, center)
		check(game.preview_tile == destination and Shot.pos(actor) != destination, "left click previews without moving")
		await process_frame
		check(game.overlay.find_child("MoveConfirm24", true, false) != null, "move preview controls exist")
		var marker_enlarged := false
		for node in game.hover_highlights.get_children():
			if node is MeshInstance3D and node.mesh is BoxMesh and node.mesh.size.x >= 0.6 and node.mesh.size.z >= 0.6: marker_enlarged = true
		check(marker_enlarged, "route destination marker enlarged")
		mouse(game, MOUSE_BUTTON_RIGHT, center)
		check(Shot.pos(actor) == destination, "right click commits a valid tile")
	check(game.overlay.find_child("MoveConfirm24", true, false) != null, "move has confirm and cancel controls")
	var grid: Node = game.highlights.find_child("RouteBatch24", true, false)
	check(grid != null, "route batch visual exists")
	var route: Array = [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
	var markers: Array = Grid.route_markers24({"overwatch_tiles": [{"tile": Vector2i(2, 1), "watchers": [2]}, {"tile": Vector2i(9, 9), "watchers": [3]}], "reveal_tiles": [{"tile": Vector2i(3, 1), "group": 1}]}, route)
	check(markers.size() == 2 and markers[0].tile == route[1] and markers[1].tile == route[2], "overwatch and reveal markers follow route tiles")
	var controls: Control = game.overlay.find_child("MoveConfirm24", true, false)
	if controls != null: check(controls is BaseButton and controls.custom_minimum_size.y >= 44 and controls.size.x >= 196, "move controls are touch-owned with two 44 px areas")
	if controls != null:
		check(game.cam.touch._control_at(game.get_viewport(), controls.get_global_rect().get_center()) == controls, "touch gesture owner recognizes move controls")
		var move_game := MoveGame.new(); root.add_child(move_game); controls.game = move_game
		var tap := InputEventScreenTouch.new(); tap.index = 0; tap.pressed = true; tap.position = Vector2(20, 20)
		controls._gui_input(tap)
		tap.position = Vector2(120, 20); controls._gui_input(tap)
		check(move_game.canceled == 1 and move_game.moved == 1, "move Cancel and Confirm execute separately")
		controls.game = game; move_game.queue_free()
	var detail_actor: Dictionary = game.mission.unit_by_id(game.selected_id)
	var target: Dictionary = game.mission.living("enemy")[0]
	game.hud_controls.targeting.g = game
	var details: Array = game.hud_controls.targeting.decision_details24(detail_actor, target)
	var labels: Array[String] = []
	for item in details: labels.append(str(item.label))
	check("Base aim" in labels and "High ground" in labels and "Ability" in labels and "Range" in labels and "Flanking critical chance" in labels, "full decision modifier categories")
	if "overwatch" in actor.get("kit", []):
		game._select(int(actor.id))
		key(game, KEY_Y)
		check(bool(actor.get("overwatch", false)), "Y executes overwatch")
	key(game, KEY_END)
	check(game.end_turn_armed, "End arms confirmation with AP remaining")
	key(game, KEY_BACKSPACE)
	check(not game.end_turn_armed, "Backspace confirms end turn")
	var busy_game := BusyGame.new(); busy_game.mission = game.mission; busy_game.selected_id = game.selected_id
	var busy_controls := Controls.new(); busy_controls.g = busy_game; busy_controls.connect_busy24()
	var tab := InputEventKey.new(); tab.keycode = KEY_TAB; tab.pressed = true
	busy_controls.handle_event(tab)
	check(busy_controls.queued_selection24 >= 0 and busy_game.selected_calls == 0, "busy queues unit selection")
	var pick: Dictionary = game.mission.living("player")[2]
	busy_game.hit_tile = Shot.pos(pick)
	var busy_click := InputEventMouseButton.new(); busy_click.button_index = MOUSE_BUTTON_LEFT; busy_click.pressed = true; busy_click.position = Vector2(50, 50)
	busy_controls.handle_event(busy_click)
	check(busy_controls.queued_selection24 == int(pick.id), "busy desktop click queues latest unit")
	busy_game.busy = false; busy_game.input_busy_changed24.emit(false)
	check(busy_game.selected_calls == 1, "queued selection applies on unlock")
	var aim_game := AimGame.new(); root.add_child(aim_game)
	var panel := Panel.new(); panel.position = Vector2(10, 10); panel.size = Vector2(300, 100); aim_game.add_child(panel)
	var swipe = preload("res://scripts/w24_command_aim_swipe.gd").new(); swipe.game = aim_game; swipe.panel = panel; aim_game.add_child(swipe)
	var down := InputEventScreenTouch.new(); down.index = 0; down.pressed = true; down.position = Vector2(170, 50); swipe._input(down)
	var drag := InputEventScreenDrag.new(); drag.index = 0; drag.position = Vector2(105, 54); swipe._input(drag)
	var up := InputEventScreenTouch.new(); up.index = 0; up.position = drag.position; swipe._input(up)
	check(aim_game.cycles == 1, "horizontal swipe cycles once without firing")
	game.sound.player.stop(); game.sound.player.stream = null; game.queue_free(); aim_game.queue_free()
	await create_timer(0.2).timeout
	for i in range(3): await process_frame
	cfg.set_value("controls", "keymap", {}); cfg.set_value("controls", "confirm_move", true); cfg.save("user://controls24.cfg")
	print("COMMAND24 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
