extends SceneTree

const Mission = preload("res://scripts/mission.gd")
const Shot = preload("res://scripts/shot.gd")
const AI = preload("res://scripts/ai.gd")
const Settings = preload("res://scripts/settings.gd")
const ControlsTest = preload("res://tests/controls_test.gd")
const FxTest = preload("res://tests/fx_test.gd")
const SkillsTest = preload("res://tests/skills_test.gd")
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
	_test_wave4_rules()
	SkillsTest.run_checks(self, check)
	_test_bot_medical()
	await ControlsTest.run_checks(self, check)
	await FxTest.run_checks(self, check)
	await load("res://tests/map_test.gd").run_checks(self, check)
	if "--quick" in OS.get_cmdline_user_args():
		print("TEST RESULTS: %d checks, %d failures" % [checks, failures])
		quit(1 if failures > 0 else 0)
		return
	if "--balance" in OS.get_cmdline_user_args():
		_test_bot()
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
	check(game.views.size() == game.mission.living("player").size(), "rigged views created for the squad")
	var patient: Dictionary = game.mission.living("player")[3]
	var healer: Dictionary = game.mission.living("player")[1]
	game.mission.apply_damage(patient, 99)
	game._refresh()
	check(game.views.has(int(patient.id)) and bool(game.views[int(patient.id)].downed), "downed soldier remains visible on the floor")
	check(game.mission.use_ability(int(healer.id), "forceHeal", int(patient.id)), "scene can revive a downed soldier")
	game._refresh()
	check(not bool(game.views[int(patient.id)].downed) and bool(patient.wounded), "revived view gets up and remains Wounded")
	game._move_selected(Vector2i(4, 21))
	check(game.views[int(game.selected_id)].motion != null, "move starts visual path")
	check(game.views[int(game.selected_id)].position.z > 21.5, "rules move resolves before visual travel")
	game._demo("shot")
	for i in range(3): game._end_turn()
	await process_frame
	check(game.mission.turn == 4, "three turns advance with presentation enabled")
	game.mission.units[0].wounded = true
	game.mission.result = "win"
	game._refresh()
	check(game.result_label.text.contains("Wounded:") and game.result_label.text.contains(str(game.mission.units[0].name)), "result panel names Wounded soldiers")
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
		check(int(result.hit) == int(c.expected), "aim %s: got %d, expected %d" % [c.name, result.hit, c.expected])
	print("aim: %d geometry and WotC height fixture cases" % cases.size())

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
	var spread = _blank()
	spread._spawn("trooper", 5, 5, -1)
	spread._spawn("soldier", 8, 4, -1)
	spread._spawn("soldier", 8, 6, -1)
	check(int(AI.choose_target(spread, spread.units[0], {int(spread.units[1].id): 2}).id) == int(spread.units[2].id), "AI spreads fire across equal targets")
	var healers = _blank()
	healers._spawn("trooper", 5, 5, -1)
	healers._spawn("soldier", 8, 4, -1)
	healers._spawn("medic", 8, 6, -1)
	check(int(AI.choose_target(healers, healers.units[0]).id) == int(healers.units[2].id), "AI may prioritize a healer")
	healers.units[2].hp = 0; healers.units[2].status = "down"
	check(int(AI.choose_target(healers, healers.units[0]).id) == int(healers.units[1].id), "AI ignores downed healer")
	var throttle = Mission.new(3)
	var first_group_size := 0
	for foe in throttle.living("enemy"):
		if int(foe.group) == 0: first_group_size += 1
	throttle.difficulty.active_cap = first_group_size
	for foe in throttle.living("enemy"): foe.spotted = true
	throttle._wake_groups()
	var active := 0
	for foe in throttle.living("enemy"):
		if bool(foe.awake): active += 1
	check(active == first_group_size, "throttle holds later groups")
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
		check(abs(int(m.difficulty.enemy_aim) - int(m.difficulty.web_diff.enemy_aim)) <= 10 and abs(int(m.difficulty.player_aim) - int(m.difficulty.web_diff.player_aim)) <= 10, "%s aim stays within web difficulty table" % id)
	Settings.difficulty = "legend"
	check(int(Mission.new(4).difficulty.active_cap) == 99, "difficulty survives mission recreation")
	Settings.difficulty = "normal"

func _test_wave4_rules() -> void:
	var m = _blank()
	m._spawn("soldier", 2, 5, -1)
	m._spawn("trooper", 5, 5, -1)
	var a: Dictionary = m.units[0]
	var t: Dictionary = m.units[1]
	m.set_tile(Vector2i(4, 5), "#")
	check(Shot.cover(m, Shot.pos(t), Shot.pos(a)) == 40, "full cover faces shooter")
	check(Shot.cover(m, Shot.pos(t), Vector2i(8, 5)) == 0, "full cover has open flank")
	var flank: Dictionary = Shot.calculate(m, {"x": 8, "y": 5, "aim": 70, "range": 9}, t)
	check(bool(flank.flanked) and int(flank.crit) == 50 and flank.lines.any(func(line: Array) -> bool: return line[0] == "Flanking critical chance"), "flank crit visible in breakdown")
	m.damage_cover(Vector2i(4, 5), 4)
	check(m.tile(Vector2i(4, 5)) == "c" and Shot.cover(m, Shot.pos(t), Shot.pos(a)) == 20, "heavy impact reduces full to half")
	m.damage_cover(Vector2i(4, 5), 4)
	check(m.tile(Vector2i(4, 5)) == "r" and Shot.cover(m, Shot.pos(t), Shot.pos(a)) == 0, "second impact destroys cover")
	m.set_tile(Vector2i(4, 5), "c")
	m.explode(Vector2i(4, 5), 4)
	check(m.tile(Vector2i(4, 5)) == "r", "explosion destroys cover")
	var heavy = _blank()
	heavy._spawn("heavy", 2, 5, -1)
	heavy._spawn("soldier", 5, 5, -1)
	heavy.set_tile(Vector2i(4, 5), "c")
	heavy._apply_attack(heavy.units[0], heavy.units[1], {"hit": 100, "crit": 0}, "shoot")
	check(int(heavy.cover_hp[Vector2i(4, 5)]) == 1, "heavy hit damages adjacent cover")
	check(m.hunker(int(a.id)) and int(a.ap) == 0, "hunker ends action")
	check(Shot.calculate(m, t, a).lines.any(func(line: Array) -> bool: return line[0] == "Defense" and int(line[1]) == -30), "hunker grants 30 defense")
	m.set_tile(Vector2i(3, 5), "c")
	var hunker_flank: Dictionary = Shot.calculate(m, {"x": 1, "y": 5, "aim": 70, "range": 9}, a)
	check(bool(hunker_flank.flanked) and int(hunker_flank.crit) == 0, "hunker blocks flank critical")
	m.end_turn()
	check(not bool(a.hunkered), "hunker expires at next player turn")
	var map = Mission.new(1)
	check(map.tile(Vector2i(16, 9)) == "^" and map.paths({"id": -99, "x": 14, "y": 9, "mob": 10}, 10).costs.has(Vector2i(17, 9)), "eastern high ground is reachable")
	for i in range(3): map.end_turn()
	check(map.reinforcement_marker.x >= 0 and map.reinforcement_announced, "entry marker set on announcement")
	check(map.reinforcement_marker.x > int(map.spec.groups[0][0][1]) + 10, "reinforcements enter east of first contact")
	map.end_turn()
	check(map.reinforcement_marker.x < 0 and map.reinforcement_dropped, "entry marker clears on arrival")

func _bot_turn(m: RefCounted) -> void:
	preload("res://tests/loop_bot.gd")._bot_turn(m)

func _test_bot_medical() -> void:
	var m = _blank()
	m._spawn("soldier", 2, 2, -1)
	m._spawn("soldier", 2, 3, -1)
	m.apply_damage(m.units[1], 99)
	_bot_turn(m)
	check(int(m.units[1].hp) > 0 and int(m.ability_uses.get("revive", 0)) >= 1, "bot revives adjacent downed ally")
	var heal = _blank()
	heal._spawn("consular", 2, 2, -1)
	heal._spawn("soldier", 2, 3, -1)
	heal.units[1].hp -= 4
	_bot_turn(heal)
	check(int(heal.ability_uses.get("forceHeal", 0)) >= 1 and int(heal.units[1].hp) == int(heal.units[1].max_hp), "bot heals injured ally")

	var advance = _blank()
	advance.prisoner = {"x": 10, "y": 2, "freed": false}
	advance._spawn("consular", 2, 2, -1)
	advance._spawn("soldier", 2, 3, -1)
	advance._spawn("soldier", 3, 3, -1)
	for ally in advance.units.slice(1):
		ally.hp -= 4
		ally.ap = 0
	_bot_turn(advance)
	check(int(advance.ability_uses.get("forceHeal", 0)) == 1, "bot limits treatment to one per actor per turn")
	check(int(advance.units[0].x) > 2, "bot advances after treatment with multiple injured allies")
	var escort = Mission.new(1)
	escort.units.clear()
	escort.prisoner = {"x": 5, "y": 18, "freed": false}
	escort._spawn("soldier", 5, 19, -1)
	_bot_turn(escort)
	check(bool(escort.prisoner.freed) and int(escort.units[0].y) > 19, "bot frees prisoner and heads toward evac in the same turn")

	var takeover = Mission.new(1)
	takeover.units.clear()
	takeover.prisoner = {"x": 5, "y": 18, "freed": true}
	takeover._spawn("soldier", 5, 19, -1)
	takeover._spawn("soldier", 5, 14, -1)
	takeover.prisoner.escort_id = takeover.units[0].id
	takeover.apply_damage(takeover.units[0], 99)
	for i in 3:
		if takeover.result == "": _bot_turn(takeover)
	check(int(takeover.prisoner.escort_id) == int(takeover.units[1].id), "bot takes over when the civilian's escort is down")
	check(takeover.result == "win", "replacement escort brings abandoned civilian to evac")

func _test_bot() -> int:
	var normal_wins := 0
	var requested := ""
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("--difficulty="): requested = str(arg).trim_prefix("--difficulty=")
	for id in ["story", "normal", "hard", "legend"]:
		if requested != "" and id != requested: continue
		Settings.difficulty = id
		var wins := 0
		var losses_by_clock := 0
		var freed := 0
		var medical_uses := 0
		for seed_value in range(1, 21):
			var m = Mission.new(seed_value)
			var guard := 0
			while m.result == "" and guard < 24:
				_bot_turn(m)
				guard += 1
			if m.result == "win": wins += 1
			if bool(m.prisoner.freed): freed += 1
			for medical_id in ["forceHeal", "heal", "medpac", "revive", "reviveStim", "forceRevive"]: medical_uses += int(m.ability_uses.get(medical_id, 0))
			if m.turn > int(m.spec.turn_limit): losses_by_clock += 1
			check(m.result != "", "%s bot %d terminates" % [id, seed_value])
		print("rescue bot %s: %d/20 wins (%.0f%%), %d freed, %d clock losses, %d medical uses" % [id, wins, wins * 5.0, freed, losses_by_clock, medical_uses])
		var minimum: int = {"story": 14, "normal": 9, "hard": 4, "legend": 1}[id]
		var maximum: int = {"story": 20, "normal": 12, "hard": 7, "legend": 3}[id]
		check(wins >= minimum and wins <= maximum, "%s bot win band %d-%d, got %d" % [id, minimum, maximum, wins])
		if id == "normal": normal_wins = wins
	Settings.difficulty = "normal"
	return normal_wins
