extends SceneTree
const Mission = preload("res://scripts/combat_mission.gd")
const Base = preload("res://scripts/mission.gd")
const Shot = preload("res://scripts/shot.gd")
const Targeting = preload("res://scripts/combat_targeting.gd")
const InputControls = preload("res://scripts/input_controls.gd")
const HudControls = preload("res://scripts/hud_controls.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(reason)

func arena() -> RefCounted:
	var m := Mission.adopt(Base.new(7))
	for y in range(1, 25):
		for x in range(1, 25): m.set_tile(Vector2i(x,y), "_")
	var squad: Array = m.living("player")
	var enemy: Dictionary = m.living("enemy")[0]
	m.units.assign([squad[0], squad[1], squad[2], squad[3], enemy])
	for i in range(4): squad[i].x = 2; squad[i].y = 2 + i * 2
	enemy.x = 6; enemy.y = 6; enemy.awake = true; enemy.spotted = true
	return m

func run() -> void:
	var game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
	await process_frame
	game.demo_mode = true; game.set_process(false)
	var m: RefCounted = arena(); game.mission = m
	var actor: Dictionary = m.units[2]; var enemy: Dictionary = m.units[4]
	game.selected_id = int(actor.id); game.action = "move"; game._refresh()
	var expected: Array[String] = ["move"]
	for id in actor.get("kit", []):
		if m.abilities.has(id) and id not in expected: expected.append(id)
	for id in ["medpac", "revive"]:
		if m.abilities.has(id) and id not in expected: expected.append(id)
	for id in expected:
		check(game.action_buttons.has(id) and game.action_buttons[id].visible, "selected unit ability visible: " + id)
	var shoot: Button = game.action_buttons["shoot"]
	check(int(shoot.get("cost")) == int(m.abilities.shoot.ap), "button cost matches ability definition")
	actor.ap = 0; game._refresh()
	check(shoot.disabled and shoot.tooltip_text != "", "unusable ability has reason")
	actor.ap = 3; actor.cooldowns["shoot"] = m.turn + 2; game._refresh()
	check(int(shoot.get("cooldown")) == 2, "cooldown overlay has turns left")
	actor.cooldowns.erase("shoot")
	game.action = "shoot"; game.target_id = int(enemy.id); game._refresh()
	for fixture in ["open", "cover", "flank", "height"]:
		m.set_tile(Vector2i(5,6), "_"); actor.x = 2; actor.y = 6; enemy.x = 6; enemy.y = 6
		if fixture == "cover": m.set_tile(Vector2i(5,6), "c")
		if fixture == "flank": m.set_tile(Vector2i(5,6), "c"); actor.x = 9
		if fixture == "height": m.set_tile(Vector2i(2,6), "^")
		var data: Dictionary = Targeting.shot_breakdown(m, actor, enemy)
		var real: Dictionary = Shot.calculate(m, actor, enemy)
		var total := 0
		for item in data.aim_lines: total += int(item[1])
		game._show_shot()
		check(int(data.hit) == int(real.hit) and game.hit_big_label.text.begins_with("%d%%" % int(real.hit)), fixture + " displayed hit matches combat result")
		check(total == int(real.hit), fixture + " breakdown sums to hit chance")
		check(int(data.crit) == int(real.crit), fixture + " crit matches combat result")
	m.set_tile(Vector2i(2,6), "_"); m.set_tile(Vector2i(5,6), "_")
	actor.x = 2; actor.y = 2; enemy.x = 6; enemy.y = 6
	var other: Dictionary = enemy.duplicate(true); other.id = 100; other.x = 7; other.y = 6; m.units.append(other)
	game.target_id = -1; game._cycle_target(1)
	var first: int = game.target_id; game._cycle_target(1)
	check(first == int(enemy.id) and game.target_id == 100, "target cycle follows sorted visible enemy ids")
	game._cycle_target(-1); check(game.target_id == first, "reverse cycle returns to prior target")
	game.action = "move"; game.target_id = -1
	var walk: Dictionary = InputControls.move_preview(m, actor, Vector2i(3,2))
	var dash: Dictionary = InputControls.move_preview(m, actor, Vector2i(2 + int(actor.mob) + 1,2))
	check(int(walk.ap) == 1 and HudControls.move_color(int(walk.ap)) == Color("399ef2"), "one AP movement is blue")
	check(int(dash.ap) == 2 and HudControls.move_color(int(dash.ap)) == Color("f2ba47"), "dash movement is yellow")
	m.set_tile(Vector2i(4,3), "c"); enemy.x = 6; enemy.y = 4
	var exposed: Dictionary = InputControls.move_preview(m, actor, Vector2i(4,4))
	check(not exposed.is_empty() and not exposed.flanks.is_empty(), "visible enemy flanking destination triggers warning")
	check(int(exposed.shields.N) == 20, "destination shows half cover shield")
	m.phase = "enemy"; await process_frame
	check(game.hud_controls.night.phase_text.text == "ENEMY ACTIVITY", "enemy banner appears")
	m.phase = "player"; await process_frame
	check(game.hud_controls.night.phase_text.text == "JEDI TURN", "Jedi banner appears")
	actor.hunkered = true; game._refresh()
	check(game.hud_controls.night.status_row.get_child_count() > 0 and game.hud_controls.night.status_row.get_child(0).tooltip_text == "Hunkered", "status icon explains its effect")
	game._request_end_turn()
	check(game.end_turn_armed and game.warning_label.text.contains("still"), "end turn asks when actions remain")
	var esc := InputEventKey.new(); esc.keycode = KEY_ESCAPE; esc.pressed = true
	game.hud_controls.night._unhandled_input(esc)
	check(game.hud_controls.night.pause_back.visible, "Esc opens pause menu from idle")
	game.hud_controls.night._unhandled_input(esc)
	check(not game.hud_controls.night.pause_back.visible, "Esc resumes from pause menu")
	game.queue_free(); await process_frame
	print("HUD NIGHT1 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
