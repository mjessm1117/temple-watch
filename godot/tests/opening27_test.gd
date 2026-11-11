extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Bot = preload("res://tests/campaign_bot.gd")
const Shot = preload("res://scripts/shot.gd")
const Objectives = preload("res://scripts/mission_objectives.gd")
const Pressure = preload("res://scripts/mission_pressure.gd")

var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func play(m) -> void:
	for step in 60:
		if m.result != "": break
		Bot.turn(m)

func validate_setup() -> void:
	var c = Campaign.new("normal")
	c.select_mission(0)
	var m = Battle.create(c, 1)
	check(m.spec.id == "relay" and m.spec.family == "defend" and not bool(m.spec.concealed), "Temple gate stays open defense")
	var players: Array = m.living("player")
	var clear := true
	for u in players:
		for e in m.living("enemy"):
			if int(e.group) == 0 and Shot.distance(Shot.pos(e), Shot.pos(u)) <= 8 and Shot.los(m, Shot.pos(e), Shot.pos(u)): clear = false
	check(players.size() == 5 and clear, "five campaign allies begin out of west pod sight")
	check(players.all(func(u): return Shot.in_cover(m, Shot.pos(u))), "five campaign allies begin behind gate cover")
	var front := true
	for e in m.living("enemy"):
		if int(e.y) >= int(players[0].y): front = false
	for entry in m.spec.entries:
		if int(entry[1]) >= int(players[0].y): front = false
	check(front, "all enemy starts and reinforcement entries are in front")
	var spawn_m = Battle.create(c, 2)
	spawn_m.turn = 3
	Pressure.player_start(spawn_m)
	var landed_in_front := true
	for e in spawn_m.living("enemy"):
		if int(e.group) >= 1000 and int(e.y) >= int(players[0].y): landed_in_front = false
	check(landed_in_front and spawn_m.living("enemy").any(func(e): return int(e.group) >= 1000), "first wave actually lands in front of the squad")
	var wave: Dictionary = m.wave_entry27(m)
	check(wave.has_all(["turns_left", "count", "entry_tiles", "side"]) and int(wave.turns_left) == 2 and int(wave.count) == 2 and wave.entry_tiles.size() > 0, "wave warning gives countdown, count, entry and side")
	var choices: Dictionary = m.opening_choices27(m)
	check(choices.has("options") and choices.options.size() == 2 and choices.options[0].has_all(["id", "label", "tiles", "purpose"]), "gate exposes two setup choices")
	for option in choices.get("options", []):
		check(option.tiles.all(func(p): return m.passable(p)), "setup choice %s names reachable ground" % str(option.id))
	# Two bad holds still leave a player turn; clearing the contest resets the counter.
	m.objective_state.overrun = 1
	var gate: Vector2i = Vector2i(13, 13)
	for e in m.living("enemy").slice(0, 2): e.x = gate.x; e.y = gate.y
	Objectives.enemy_end(m)
	check(m.result == "" and int(m.objective_state.overrun) == 2, "second contested hold grants one recovery turn")
	for e in m.living("enemy").slice(0, 2): e.x = 2; e.y = 13
	Objectives.enemy_end(m)
	check(m.result == "" and int(m.objective_state.overrun) == 0, "clearing the gate restores the line")

func run() -> void:
	validate_setup()
	var wins := {"relay":0, "rescue":0, "envoy":0}
	var turns := {"relay":0, "rescue":0, "envoy":0}
	var win_turns := {"relay":0, "rescue":0, "envoy":0}
	var loss_turns := {"relay":[], "rescue":[], "envoy":[]}
	var seed_count := 1 if "--quick" in OS.get_cmdline_user_args() else 20
	for seed_value in range(1, seed_count + 1):
		var c = Campaign.new("normal")
		for mission_id in ["relay", "rescue", "envoy"]:
			var rest_weeks := 0
			while c.default_squad().size() < 2 and rest_weeks < 8:
				c.advance_days(7)
				rest_weeks += 1
			check(c.default_squad().size() >= 2, "seed %d has a ready squad for %s" % [seed_value, mission_id])
			var option_index := -1
			for i in c.state.options.size():
				if str(c.state.options[i].get("mission", "")) == mission_id: option_index = i; break
			check(option_index >= 0, "seed %d offers %s on actual route" % [seed_value, mission_id])
			if option_index < 0: break
			var selected: Dictionary = c.select_mission(option_index)
			if selected.is_empty():
				print("SELECT FAILED seed=", seed_value, " mission=", mission_id, " step=", c.state.step, " roster=", c.state.roster.map(func(r): return [r.id, r.status, r.wound, r.fatigue]))
				failures += 1
				break
			var m = Battle.create(c, seed_value)
			check(m != null, "seed %d builds %s" % [seed_value, mission_id])
			if m == null: break
			var family: String = {"relay":"defend", "rescue":"rescue", "envoy":"hack_terminal"}[mission_id]
			check(str(m.spec.family) == family, "seed %d %s has distinct objective" % [seed_value, mission_id])
			play(m)
			turns[mission_id] += int(m.turn)
			if m.result == "win":
				wins[mission_id] += 1
				win_turns[mission_id] += int(m.turn)
			else: loss_turns[mission_id].append(int(m.turn))
			c.apply_mission_result(Battle.result(c, m))
	for mission_id in ["relay", "rescue", "envoy"]:
		print("OPENING27 %s: %d/20 wins; mean win turn %.1f; mean all turn %.1f; loss turns %s" % [mission_id, int(wins[mission_id]), float(win_turns[mission_id])/maxi(1,int(wins[mission_id])), float(turns[mission_id])/20.0, str(loss_turns[mission_id])])
	check(int(wins.relay) >= 13 and int(wins.relay) <= 16, "gate bot wins 13-16/20")
	check(not loss_turns.relay.has(2), "gate has no turn-2 overrun losses")
	check(int(wins.envoy) > 0, "envoy victory reachable on campaign route")
	print("OPENING27 RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
