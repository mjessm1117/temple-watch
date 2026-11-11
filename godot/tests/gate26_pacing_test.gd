extends SceneTree
## Regression checks for the paced opening of the Temple Outer Gate defense.
const Mission = preload("res://scripts/mission.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const CampaignBot = preload("res://tests/campaign_bot.gd")
const LoopBot = preload("res://tests/loop_bot.gd")
const Shot = preload("res://scripts/shot.gd")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func gate_campaign(seed_value: int):
	var campaign = Campaign.new("normal")
	campaign.state.options = [{"mission":"relay", "map_variant":0, "adv":false}]
	campaign.select_mission(0)
	return Battle.create(campaign, seed_value)

func _opening_contract_and_trigger() -> void:
	var m = gate_campaign(1)
	check(str(m.spec.family) == "defend" and str(m.spec.id) == "relay", "campaign route starts Temple Outer Gate defense")
	var contact: Dictionary = m.opening_contact26()
	check(str(contact.get("status", "")) == "inactive", "east opening contact starts inactive")
	check(str(contact.get("pod", "")) == "east", "opening contact identifies east pod")
	check(str(m.spec.get("opening_contact26", {}).get("status", "")) == "inactive", "east pod is inactive in authored mission data")
	var west_awake := false
	var east_asleep := false
	for enemy in m.living("enemy"):
		if int(enemy.get("group", -1)) == 0 and bool(enemy.awake): west_awake = true
		if int(enemy.get("group", -1)) == 1 and not bool(enemy.awake): east_asleep = true
	check(west_awake, "west group is awake at mission start")
	check(east_asleep, "east group waits at mission start")
	var wave: Dictionary = m.next_wave26()
	check(int(wave.get("turn", 0)) >= 3, "first scheduled reinforcement arrives no earlier than turn 3")
	check(int(wave.get("count", 0)) > 0 and wave.get("entry_tile", Vector2i(-1, -1)) is Vector2i, "next wave reports count and entry tile")

	# Exercise contact from player movement. Find an actually reachable destination
	# with LOS to an inactive east pod member, then move through the game API.
	var east: Dictionary = {}
	for enemy in m.living("enemy"):
		if int(enemy.get("group", -1)) == 1 and not bool(enemy.awake): east = enemy; break
	var activated_by_move := false
	if not east.is_empty():
		for actor in m.living("player"):
			var reach: Dictionary = m.paths(actor, int(actor.mob))
			for tile in reach.costs:
				if tile == Shot.pos(actor) or Shot.distance(tile, Shot.pos(east)) > 8.0: continue
				if not Shot.los(m, tile, Shot.pos(east)): continue
				if m.move(int(actor.id), tile):
					activated_by_move = str(m.opening_contact26().get("status", "")) == "active"
					break
			if activated_by_move: break
	check(activated_by_move, "moving into sight activates the east pod")

	# A separate battle proves the other contact route without inheriting movement
	# or activation state from the sight fixture above.
	var shot_m = gate_campaign(1)
	var fired := false
	for actor in shot_m.living("player"):
		if "shoot" not in actor.get("kit", []): continue
		for target in shot_m.living("enemy"):
			if not bool(target.awake): continue
			var info: Dictionary = Shot.calculate(shot_m, actor, target)
			if not bool(info.los) or not bool(info.range_ok): continue
			if shot_m.shot(int(actor.id), int(target.id)):
				fired = true
				break
		if fired: break
	check(fired, "shot fixture finds a legal opening attack")
	check(str(shot_m.opening_contact26().get("activation_trigger", "")) == "shot", "a player shot activates the east pod")

	var turn_m = gate_campaign(1)
	turn_m.end_turn()
	check(int(turn_m.turn) == 2 and str(turn_m.opening_contact26().get("activation_trigger", "")) == "turn_2", "east pod activates when turn 2 begins")

func _campaign_bot_regression() -> void:
	var wins := 0
	for seed_value in range(1, 21):
		var m = gate_campaign(seed_value)
		for step in 60:
			if m.result != "": break
			CampaignBot.turn(m)
		if m.result == "win": wins += 1
	check(wins >= 13 and wins <= 16, "Normal gate campaign bot wins 13–16/20 (got %d/20)" % wins)
	print("GATE26 CAMPAIGN BOT: %d/20 wins" % wins)

func _legacy_rescue_guard() -> void:
	var wins := 0
	for seed_value in range(1, 21):
		var m = Mission.new(seed_value, "res://data/rescue.json")
		for step in 60:
			if m.result != "": break
			LoopBot._bot_turn(m)
		if m.result == "win": wins += 1
	check(wins >= 9 and wins <= 11, "legacy Normal rescue guard stays 9–11/20 (got %d/20)" % wins)
	print("GATE26 LEGACY RESCUE GUARD: %d/20 wins" % wins)

func run() -> void:
	_opening_contract_and_trigger()
	_campaign_bot_regression()
	_legacy_rescue_guard()
	print("GATE26 PACING RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
