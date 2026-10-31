extends SceneTree

const Mission = preload("res://scripts/mission.gd")
const Shot = preload("res://scripts/shot.gd")
const AI = preload("res://scripts/ai.gd")
const Settings = preload("res://scripts/settings.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	_test_aim()
	_test_geometry()
	_test_actions()
	_test_mission_layout()
	_test_ai()
	_test_difficulty()
	if "--quick" in OS.get_cmdline_user_args():
		print("TEST RESULTS: %d checks, %d failures" % [checks, failures])
		quit(1 if failures > 0 else 0)
		return
	var wins := _test_bot()
	await _test_presentation_scene()
	print("TEST RESULTS: %d checks, %d failures; Normal rescue bot %d/20 wins (%.0f%%)" % [checks, failures, wins, wins * 5.0])
	quit(1 if failures > 0 else 0)

func _blank() -> RefCounted:
	var m = Mission.new(1)
	m.spec.width = 12; m.spec.height = 12
	m.board.clear()
	for y in range(12): m.board.append("............")
	m.units.clear()
	return m

func _test_presentation_scene() -> void:
	var packed: PackedScene = load("res://scenes/rescue.tscn")
	check(packed != null, "presentation scene loads")
	if packed == null: return
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	check(game.views.size() == 4, "four rigged squad views created")
	game._move_selected(Vector2i(4, 21))
	check(game.views[int(game.selected_id)].motion != null, "move starts visual path")
	check(game.views[int(game.selected_id)].position.z > 21.5, "rules move resolves before visual travel")
	game._demo("shot")
	for i in range(3): game._end_turn()
	await process_frame
	check(game.mission.turn == 4, "three turns advance with presentation enabled")
	game.sound.player.stop()
	game.sound.player.stream = null
	await create_timer(0.2).timeout
	game.queue_free()
	for i in range(3): await process_frame
	print("presentation: scene loaded, movement, shot and three enemy turns")

func _test_aim() -> void:
	var cases: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/aim_cases.json"))
	for c in cases:
		var m = _blank()
		for placement in c.tiles: m.set_tile(Vector2i(int(placement[0]), int(placement[1])), str(placement[2]))
		var a: Dictionary = c.attacker.duplicate(true)
		var t: Dictionary = c.target.duplicate(true)
		t.defense = int(c.defense)
		var result: Dictionary = Shot.calculate(m, a, t, bool(c.melee))
		check(int(result.hit) == int(c.expected), "aim %s: got %d, web expected %d" % [c.name, result.hit, c.expected])
	print("aim: %d web rules.js fixture cases" % cases.size())

func _test_geometry() -> void:
	var m = _blank()
	m.set_tile(Vector2i(4, 5), "c")
	check(Shot.cover(m, Vector2i(5, 5), Vector2i(2, 5)) == 20, "half cover front")
	check(Shot.cover(m, Vector2i(5, 5), Vector2i(8, 5)) == 0, "half cover flank")
	m.set_tile(Vector2i(4, 5), "#")
	check(Shot.cover(m, Vector2i(5, 5), Vector2i(2, 5)) == 40, "full cover front")
	m.set_tile(Vector2i(6, 6), "#")
	check(not Shot.los(m, Vector2i(3, 6), Vector2i(9, 6)), "full wall blocks LOS")
	m.set_tile(Vector2i(4, 5), ".")
	check(Shot.los(m, Vector2i(3, 6), Vector2i(9, 6)) == false, "middle wall still blocks")
	m.set_tile(Vector2i(6, 6), ".")
	check(Shot.los(m, Vector2i(3, 6), Vector2i(9, 6)), "clear LOS")
	m.set_tile(Vector2i(4, 6), "#")
	m.set_tile(Vector2i(5, 6), "#")
	check(Shot.los(m, Vector2i(3, 6), Vector2i(7, 6)), "corner peek around own wall")
	m.set_tile(Vector2i(4, 7), "#")
	m.set_tile(Vector2i(3, 7), "#")
	m.set_tile(Vector2i(3, 5), "#")
	check(not Shot.los(m, Vector2i(3, 6), Vector2i(7, 6)), "sealed peek blocked")
	print("geometry: directional cover, blockers, corner peeks")

func _test_actions() -> void:
	var m = Mission.new(1)
	var u: Dictionary = m.living("player")[0]
	var start_ap: int = int(u.ap)
	check(m.move(int(u.id), Vector2i(4, 20)), "move legal")
	check(int(u.ap) == start_ap - 1, "move costs 1 AP")
	check(m.move(int(u.id), Vector2i(4, 12)), "dash legal")
	check(int(u.ap) == 0, "dash costs 2 AP")
	check(not m.move(int(u.id), Vector2i(4, 11)), "zero AP blocks move")
	m.units = m.living("player")
	m.end_turn()
	check(int(u.ap) == 3, "turn restores 3 AP")
	var small = _blank()
	small._spawn("soldier", 2, 2, -1)
	small._spawn("trooper", 5, 2, -1)
	var shooter: Dictionary = small.units[0]
	var target: Dictionary = small.units[1]
	check(small.shot(int(shooter.id), int(target.id)), "rifle shot legal")
	check(int(shooter.ap) == 1, "rifle shot costs 2 AP")
	check(not small.shot(int(shooter.id), int(target.id)), "second shot blocked at 1 AP")
	var fail = Mission.new(1)
	for i in range(int(fail.spec.turn_limit)): fail.end_turn()
	check(fail.result == "loss", "clock loss path")
	var win = Mission.new(1)
	win.prisoner.freed = true
	win.prisoner.x = 5; win.prisoner.y = 23
	win._check_win()
	check(win.result == "win", "evac win path")
	print("actions: AP, shot spending, win/lose")

func _test_mission_layout() -> void:
	var m = Mission.new(1)
	check(int(m.spec.width) >= 24 and int(m.spec.height) >= 24, "rescue map size")
	check(m.spec.groups.size() == 3, "three staged groups")
	var proxy: Dictionary = {"id": -99, "x": 10, "y": 15, "mob": 100}
	m.units.clear()
	for gap in [Vector2i(12, 9), Vector2i(12, 17)]:
		m.set_tile(gap, "#")
		check(m.paths(proxy, 100).costs.has(Vector2i(14, 15)), "second route survives closed gap %s" % gap)
		m.set_tile(gap, ".")
	var wave = Mission.new(1)
	for i in range(3): wave.end_turn()
	check(wave.reinforcement_announced and not wave.reinforcement_dropped, "drop announced one turn ahead")
	wave.end_turn()
	check(wave.reinforcement_dropped, "drop arrives next turn")
	var push = _blank()
	push._spawn("guardian", 2, 2, -1)
	push._spawn("trooper", 4, 2, -1)
	push.set_tile(Vector2i(5, 2), "c")
	check(push.push(int(push.units[0].id), int(push.units[1].id)), "Force Push legal")
	check(push.tile(Vector2i(5, 2)) == "r", "Force Push destroys cover")
	check(int(push.units[0].ap) == 2 and int(push.units[0].focus_left) == 2, "Force Push AP and Focus")
	print("mission: 26x26, two routes, staged groups, announced drop, cover break")

func _test_ai() -> void:
	var cover = _blank()
	cover._spawn("trooper", 4, 5, -1)
	cover._spawn("soldier", 8, 5, -1)
	cover.set_tile(Vector2i(6, 5), "c")
	var e: Dictionary = cover.units[0]
	var protected := Vector2i(5, 5)
	check(AI.destination_score(cover, e, protected) > AI.destination_score(cover, e, Vector2i(5, 4)), "AI favors directional cover")
	check(AI.choose_destination(cover, e, 1) == protected, "AI picks cover over open ground")
	var flank = _blank()
	flank._spawn("agent", 5, 5, -1)
	flank._spawn("soldier", 8, 5, -1)
	flank.set_tile(Vector2i(7, 5), "c")
	var sniper: Dictionary = flank.units[0]
	var open_score: float = AI.destination_score(flank, sniper, Vector2i(6, 5))
	var flank_score: float = AI.destination_score(flank, sniper, Vector2i(8, 7))
	check(flank_score > open_score, "AI values a flank")
	var sith = _blank()
	sith._spawn("acolyte", 4, 5, -1)
	sith._spawn("soldier", 5, 5, -1)
	sith._spawn("guardian", 4, 6, -1)
	check(str(AI.choose_target(sith, sith.units[0]).class_name) == "Guardian", "Sith targets Jedi")
	var throttle = Mission.new(3)
	throttle.difficulty.active_cap = 2
	for foe in throttle.living("enemy"): foe.spotted = true
	throttle._wake_groups()
	var active := 0
	for foe in throttle.living("enemy"):
		if bool(foe.awake): active += 1
	check(active == 2, "throttle holds later groups")
	var reveal = _blank()
	reveal._spawn("trooper", 4, 5, 0)
	reveal._spawn("soldier", 8, 5, -1)
	reveal.difficulty.active_cap = 4
	reveal.phase = "enemy"
	reveal._wake_groups()
	var hp_before: int = int(reveal.units[1].hp)
	AI.act(reveal, reveal.units[0], {})
	check(int(reveal.units[1].hp) == hp_before, "enemy turn reveal has no shot")
	print("AI: cover, flank, Jedi priority, engagement throttle")

func _test_difficulty() -> void:
	var choices := Settings.all()
	check(choices.size() == 4, "four difficulty settings")
	var menu_scene: PackedScene = load("res://scenes/menu.tscn")
	check(menu_scene != null, "menu scene loads")
	if menu_scene != null:
		var menu: Control = menu_scene.instantiate()
		root.add_child(menu)
		check(menu.buttons.size() == 4, "menu shows four choices")
		menu._pick("hard")
		check(menu.picked == "hard" and menu.buttons.hard.button_pressed, "menu selects difficulty")
		menu.queue_free()
	for id in ["story", "normal", "hard", "legend"]:
		Settings.difficulty = id
		var m = Mission.new(1)
		check(not m.difficulty.is_empty() and int(m.spec.turn_limit) == int(choices[id].turn_clock), "%s difficulty loads" % id)
	Settings.difficulty = "legend"
	check(int(Mission.new(4).difficulty.active_cap) == 99, "difficulty survives mission recreation")
	Settings.difficulty = "normal"

func _distance_field(m: RefCounted, goal: Vector2i) -> Dictionary:
	var field: Dictionary = {goal: 0}
	var queue: Array[Vector2i] = [goal]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		for d in Shot.DIRS:
			var q: Vector2i = p + d
			if not m.passable(q) or field.has(q): continue
			field[q] = int(field[p]) + 1
			queue.append(q)
	return field

func _bot_move_toward(m: RefCounted, u: Dictionary, goal: Vector2i) -> bool:
	var reach: Dictionary = m.paths(u, int(u.mob) * (2 if int(u.ap) >= 2 else 1))
	var field := _distance_field(m, goal)
	var best: Vector2i = Shot.pos(u)
	var best_score: float = float(field.get(best, 999))
	for q in reach.costs:
		if q == Shot.pos(u): continue
		var cost: int = int(reach.costs[q])
		if cost > int(u.mob) and int(u.ap) < 2: continue
		var score: float = float(field.get(q, 999)) + float(cost) * 0.01
		if score < best_score: best = q; best_score = score
	if best != Shot.pos(u): return m.move(int(u.id), best)
	return false

func _bot_turn(m: RefCounted) -> void:
	var objective := Vector2i(int(m.prisoner.x), int(m.prisoner.y)) if not bool(m.prisoner.freed) else Vector2i(5, 23)
	var squad: Array[Dictionary] = m.living("player")
	for u in squad:
		if m.result != "": return
		if int(u.hp) <= 0: continue
		var cycles := 0
		while int(u.ap) > 0 and cycles < 4 and m.result == "":
			cycles += 1
			if not bool(m.prisoner.freed) and max(abs(int(u.x) - int(m.prisoner.x)), abs(int(u.y) - int(m.prisoner.y))) <= 1:
				if m.free_prisoner(int(u.id)): continue
			var target: Dictionary = {}
			for e in m.living("enemy"):
				if not bool(e.awake): continue
				var info: Dictionary = Shot.calculate(m, u, e)
				if bool(info.los) and bool(info.range_ok) and int(info.hit) >= 45 and (target.is_empty() or int(e.hp) < int(target.hp)): target = e
			if not target.is_empty() and int(u.ap) >= 2 and str(u.class_name) not in ["Guardian", "Consular"]:
				m.shot(int(u.id), int(target.id)); continue
			if not target.is_empty() and str(u.class_name) in ["Guardian", "Consular"] and max(abs(int(u.x)-int(target.x)), abs(int(u.y)-int(target.y))) <= 1:
				m.shot(int(u.id), int(target.id), "strike"); continue
			if not _bot_move_toward(m, u, objective): break
	m.end_turn()

func _test_bot() -> int:
	var normal_wins := 0
	for id in ["story", "normal", "hard", "legend"]:
		Settings.difficulty = id
		var wins := 0
		var losses_by_clock := 0
		for seed_value in range(1, 21):
			var m = Mission.new(seed_value)
			var guard := 0
			while m.result == "" and guard < 24:
				_bot_turn(m)
				guard += 1
			if m.result == "win": wins += 1
			if m.turn > int(m.spec.turn_limit): losses_by_clock += 1
			check(m.result != "", "%s bot %d terminates" % [id, seed_value])
		print("rescue bot %s: %d/20 wins (%.0f%%), %d clock losses" % [id, wins, wins * 5.0, losses_by_clock])
		if id == "normal": normal_wins = wins
	Settings.difficulty = "normal"
	return normal_wins
