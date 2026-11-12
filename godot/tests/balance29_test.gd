extends SceneTree
## Focused mission contract; the 20-seed rates live in w29d_benchmark.gd.
const Campaign = preload("res://scripts/campaign/state.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Mission = preload("res://scripts/mission.gd")
const Objectives = preload("res://scripts/mission_objectives.gd")
const Pressure = preload("res://scripts/mission_pressure.gd")
const Shot = preload("res://scripts/shot.gd")
const LoopBot = preload("res://tests/loop_bot.gd")

var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; print("BALANCE29 FAIL: ", label)

func mission(id: String, diff: String = "normal"):
	var c = Campaign.new(diff)
	c.state.options = [{"mission":id,"map_variant":0,"adv":false}]
	c.select_mission(0)
	return Battle.create(c,1)

func _plan_guard() -> void:
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/data-story.json"))
	var core: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign/core.json"))
	var live: Array = story.records.PLAN
	check(live[0].story == "relay" and live[1].crises == ["rescue","archive"] and live[2].story == "envoy", "runtime's first three steps are relay, rescue/archive, envoy")
	var state_source := FileAccess.get_file_as_string("res://scripts/campaign/state.gd")
	var live_source := state_source.contains("story.data[[\"data-story\", \"data-era2\", \"data-era3\"]")
	var stale_mismatch: bool = core.PLAN.slice(0,3) != live.slice(0,3)
	if stale_mismatch: print("BALANCE29 PLAN MISMATCH: core.json is stale; data-story.json drives campaign")
	check(not stale_mismatch or live_source, "a divergent core PLAN cannot drive the campaign")
	check(live_source, "campaign reads story PLAN")

func _reinforcement_contract() -> void:
	var relay = mission("relay")
	check(relay != null and relay.spec.family == "defend" and not relay.spec.concealed, "open Temple gate defense")
	var front := true
	for enemy in relay.living("enemy"):
		if int(enemy.y) >= int(relay.living("player")[0].y): front = false
	for entry in relay.spec.entries:
		if int(entry[1]) >= int(relay.living("player")[0].y): front = false
	check(front, "all gate enemies and entry points start in front")
	check(int(relay.pressure_state.pending[0].turn) >= 3, "first gate reinforcement arrives later")
	var waves := int(relay.pressure_state.waves)
	relay.turn = 2
	Pressure.player_start(relay)
	check(int(relay.pressure_state.waves) == waves, "clock alone cannot call the next gate wave")
	relay.objective_state.held = 1
	Pressure.player_start(relay)
	check(int(relay.pressure_state.waves) == waves+1 and relay.pressure_state.pending.size() >= 2, "holding the gate calls and telegraphs the next wave")
	var archive = mission("archive")
	archive.turn = 3
	for enemy in archive.living("enemy"): enemy.spotted = false; enemy.awake = false
	Pressure.player_start(archive)
	check(archive.pressure_state.pending.is_empty(), "clock alone cannot call patrol support")
	archive.objective_state.done[Vector2i(15,4)] = true
	Pressure.player_start(archive)
	check(not archive.pressure_state.pending.is_empty() and int(archive.pressure_state.pending[0].turn) > archive.turn, "objective progress calls warned patrol support")

func _objective_contract() -> void:
	var archive = mission("archive")
	check(int(archive.spec.turn_limit) == 9 and int(archive.spec.evac_turn_limit) > 0, "archive hack has a distinct extraction window")
	archive.objective_state.phase = "evac"; archive.objective_state.evac_start = 9
	archive.objective_state.done[Vector2i(15,4)] = true
	check(archive.interactables().size() == 2, "archive retains optional terminal intel during extraction")
	archive.turn = 10
	Objectives.player_start(archive)
	check(archive.result == "", "hack deadline stops after completed objective")
	archive.turn = 9 + int(archive.spec.evac_turn_limit)
	Objectives.player_start(archive)
	check(archive.result == "loss", "extraction window still expires")
	var envoy = Mission.new(1,"res://data/maps/envoy.json")
	check(int(envoy.spec.objective.required) == 1 and bool(envoy.spec.get("envoy_extract",false)), "envoy has one intercept and an escort beat")
	check(bool(envoy.prisoner.active), "envoy begins on the map")
	var actor: Dictionary = envoy.living("player")[0]
	actor.x = 12; actor.y = 4
	check(envoy.use_ability(int(actor.id),"interact",-1,Vector2i(13,4)), "intercept is usable")
	check(envoy.objective_state.phase == "evac" and bool(envoy.prisoner.freed), "intercept opens escort escape")
	check(str(envoy.objective_status().label).contains("Escort"), "new beat is visible in objective text")
	check(envoy.interactables().is_empty(), "inactive terminals vanish after intercept")

func _legacy_rescue() -> void:
	var wins := 0
	for seed_value in range(1,21):
		var m = Mission.new(seed_value,"res://data/rescue.json")
		for step in 60:
			if m.result != "": break
			LoopBot._bot_turn(m)
		if m.result == "win": wins += 1
	check(wins >= 9 and wins <= 11, "legacy rescue remains 9–11/20 (got %d/20)" % wins)
	print("BALANCE29 LEGACY RESCUE: ", wins, "/20")

func run() -> void:
	_plan_guard()
	_reinforcement_contract()
	_objective_contract()
	_legacy_rescue()
	print("BALANCE29 RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
