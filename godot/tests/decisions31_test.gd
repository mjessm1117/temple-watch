extends SceneTree
## Opening, reinforcement cue, campaign rates, and live enemy actor timing.
const Mission = preload("res://scripts/mission.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const CampaignBot = preload("res://tests/campaign_bot.gd")
const LoopBot = preload("res://tests/loop_bot.gd")
const Pressure = preload("res://scripts/mission_pressure.gd")
const Opening = preload("res://scripts/w27a_opening.gd")
const AI = preload("res://scripts/ai.gd")
const Combat = preload("res://scripts/combat_mission.gd")
const Shot = preload("res://scripts/shot.gd")

var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func gate(seed_value: int):
	var c = Campaign.new("normal")
	c.state.options = [{"mission":"relay", "map_variant":0, "adv":false}]
	c.select_mission(0)
	return Battle.create(c, seed_value)

func _balance29_contract() -> void:
	var output: Array = []
	var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", "tests/balance29_test.gd", "--", "--graphics=low"])
	var exit_code := OS.execute(OS.get_executable_path(), args, output, true)
	var transcript := "\n".join(output)
	check(exit_code == 0 and transcript.contains("BALANCE29 RESULTS:") and transcript.contains("0 failures"), "balance29_test passes without failures")

func _opening_and_cue() -> void:
	var m = gate(1)
	check(not bool(m.spec.concealed) and str(m.spec.family) == "defend", "Temple gate remains open")
	var front := true
	for enemy in m.living("enemy"):
		if int(enemy.y) >= int(m.living("player")[0].y): front = false
	check(front, "initial enemies remain in front")
	var exposed: int = Pressure.threat_summary(m).exposed_units.size()
	print("DECISIONS31 TURN 1 EXPOSED: %d allies" % exposed)
	check(exposed < 5, "opening reduces turn 1 sight pressure")
	var choices: Dictionary = Opening.choices(m)
	check(choices.get("options", []).size() >= 2 and int(choices.get("decision_turns_left", 0)) == 2, "turn 1 offers hold and flank setup")
	var wave: Dictionary = m.pressure_state.pending[0]
	var entry := Vector2i(int(wave.at[0]), int(wave.at[1]))
	check(int(wave.turn) >= 3 and m.reinforcement_marker == entry, "first reinforcement entry is marked ahead of arrival")
	var pressure_script: Script = Pressure
	check(pressure_script.has_method("entry_marker31") and Pressure.entry_marker31(m) == entry, "board marker follows the earliest pending wave")
	var actor: Dictionary = m.living("enemy")[0]
	var first: int = m.action_events.size()
	m.action_events.append({"kind":"move", "actor":int(actor.id), "from":Shot.pos(actor), "to":Shot.pos(actor)})
	AI._reason24(m, first, actor, "Flank setup")
	check(str(m.action_events[first].get("reason27", "")).contains("Flanking"), "flank move telegraphs its intent")
	m.action_events[first] = {"kind":"attack", "actor":int(actor.id)}
	AI._reason24(m, first, actor, "Holding cover")
	check(str(m.action_events[first].get("reason27", "")).contains("Holding cover"), "cover shot telegraphs a hold")
	check(str(m.intent_explain27({"kind":"overwatch", "actor":int(actor.id)})).contains("Overwatch"), "Overwatch has a distinct tell")
	m.end_turn()
	check(m.turn == 2 and Opening.choices(m).get("options", []).size() >= 2, "turn 2 retains setup choices")
	check(m.reinforcement_marker == entry, "opening contact does not erase the reinforcement cue")
	var cue_source := FileAccess.get_file_as_string("res://scripts/reinforcement_marker.gd")
	check(cue_source.contains("edge_arrow") and cue_source.contains("emission_enabled"), "existing board marker renders a glowing direction cue")

func _rates() -> void:
	var gate_wins := 0
	for seed_value in range(1, 21):
		var m = gate(seed_value)
		for step in 60:
			if m.result != "": break
			CampaignBot.turn(m)
		if m.result == "win": gate_wins += 1
	print("DECISIONS31 NORMAL GATE BOT: %d/20" % gate_wins)
	check(gate_wins >= 12, "Normal gate bot wins at least 12/20")
	var rescue_wins := 0
	for seed_value in range(1, 21):
		var m = Mission.new(seed_value, "res://data/rescue.json")
		for step in 60:
			if m.result != "": break
			LoopBot._bot_turn(m)
		if m.result == "win": rescue_wins += 1
	print("DECISIONS31 NORMAL RESCUE BOT: %d/20" % rescue_wins)
	check(rescue_wins >= 9 and rescue_wins <= 11, "Normal rescue bot remains 9–11/20")

func _actor_gap() -> void:
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.animate_headless = true
	game.set_process(false)
	game.action_camera = true
	game.mission = Combat.adopt(Mission.new(2201))
	game.mission.rng.seed = 2201
	var kept: Array[Dictionary] = []
	var enemies: Array[Dictionary] = []
	for unit in game.mission.units:
		if str(unit.side) == "enemy":
			if enemies.size() >= 4: continue
			enemies.append(unit)
		kept.append(unit)
	game.mission.units = kept
	var player: Dictionary = game.mission.living("player")[0]
	var shooter: Dictionary = enemies[0]
	for tile in game.mission.paths(player, 5).costs:
		if Shot.distance(tile, Shot.pos(player)) < 2.0 or Shot.distance(tile, Shot.pos(player)) > 5.0: continue
		if not game.mission.passable(tile) or game.mission.occupied(tile): continue
		if not Shot.los(game.mission, tile, Shot.pos(player)): continue
		shooter.x = tile.x; shooter.y = tile.y
		break
	shooter.aim = 200; shooter.range = 8.0
	for i in range(4):
		var enemy: Dictionary = enemies[i]
		enemy.awake = true; enemy.spotted = true
		if i > 0: enemy.disarmed = true; enemy.range = 1.0
	game._build_terrain(); game._refresh_figures()
	var started := Time.get_ticks_msec()
	var trace_index := 0
	var actor_times: Array[int] = []
	game._end_turn()
	while game.playing_enemy_events or game.mission.phase == "enemy":
		for i in range(trace_index, game.cam.trace.size()):
			if game.cam.trace[i].begins_with("actor_"): actor_times.append(Time.get_ticks_msec())
		trace_index = game.cam.trace.size()
		if Time.get_ticks_msec() - started > 20000: break
		await process_frame
	var max_gap := 0
	for i in range(1, actor_times.size()): max_gap = maxi(max_gap, actor_times[i] - actor_times[i - 1])
	print("DECISIONS31 LONGEST ACTOR GAP: %d ms (%d actors)" % [max_gap, actor_times.size()])
	check(actor_times.size() == 4 and max_gap <= 1100, "scripted enemy actor gap at most 1.1 seconds")
	game.queue_free()
	for i in 4: await process_frame

func run() -> void:
	_balance29_contract()
	_opening_and_cue()
	_rates()
	await _actor_gap()
	print("DECISIONS31 RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
