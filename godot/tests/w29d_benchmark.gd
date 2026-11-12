extends SceneTree
## Canonical W29 balance benchmark. Seed, mission, difficulty and bot are explicit.
const Campaign = preload("res://scripts/campaign/state.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const OldBot = preload("res://tests/campaign_bot.gd")
const NewBot = preload("res://tests/w29d_cover_bot.gd")
const Settings = preload("res://scripts/settings.gd")
const Mission = preload("res://scripts/mission.gd")
const FixtureBot = preload("res://tests/loop_bot.gd")

func _initialize() -> void: run.call_deferred()

static func mission(id: String, diff: String, seed_value: int):
	var c = Campaign.new(diff)
	c.state.options = [{"mission":id,"map_variant":0,"adv":false}]
	c.select_mission(0)
	return Battle.create(c, seed_value)

static func play(id: String, diff: String, seed_value: int, bot: String, trace: bool = false, evac_limit: int = -1, vip_hp: int = -1, evac_y: int = -1) -> Dictionary:
	var m
	if id == "fixture":
		Settings.difficulty = diff
		m = Mission.new(seed_value)
	else: m = mission(id, diff, seed_value)
	if m == null: return {"result":"setup_error", "injuries":-1}
	if evac_limit > 0: m.spec.evac_turn_limit = evac_limit
	if vip_hp > 0: m.prisoner.hp = vip_hp
	if evac_y > 0:
		var shifted: Array = []
		for tile in m.spec.evac: shifted.append([tile[0],evac_y])
		m.spec.evac = shifted
	for step in 60:
		if m.result != "": break
		if trace:
			var players: Array = m.living("player")
			print("TRACE,%s,%s,%d,turn=%d,phase=%s,done=%d,gate_hp=%d,at=%s,targets=%s" % [id,diff,seed_value,m.turn,m.objective_state.get("phase",""),m.objective_state.get("done",{}).size(),int(m.objective_state.get("relay_hp",0)),JSON.stringify(players.map(func(u): return [u.x,u.y,u.ap])),JSON.stringify(m.interactables())])
		if id == "fixture": FixtureBot._bot_turn(m)
		elif bot == "old": OldBot.turn(m)
		else: NewBot.turn(m)
	var injured := 0
	for u in m.units:
		if str(u.get("side","")) == "player" and (int(u.hp) < int(u.max_hp) or bool(u.get("wounded",false))): injured += 1
	if trace: print("TRACE_END,%s,%s,%d,%s,turn=%d,injuries=%d,last=%s" % [id,diff,seed_value,m.result,m.turn,injured,m.log_lines[-1]])
	return {"result":m.result,"injuries":injured,"turn":m.turn,"phase":m.objective_state.get("phase",""),"reason":m.log_lines[-1] if not m.log_lines.is_empty() else ""}

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var trace := "--trace" in args
	var bot := "old" if "--old" in args else "new"
	var count := 3 if trace else 20
	var missions := ["archive"] if trace else ["relay","rescue","archive","envoy","fixture"]
	var mission_filter := ""
	var diff_filter := ""
	var evac_limit := -1
	var vip_hp := -1
	var evac_y := -1
	for arg in args:
		if arg.begins_with("--mission="): mission_filter = arg.trim_prefix("--mission=")
		if arg.begins_with("--diff="): diff_filter = arg.trim_prefix("--diff=")
		if arg.begins_with("--evac-limit="): evac_limit = int(arg.trim_prefix("--evac-limit="))
		if arg.begins_with("--vip-hp="): vip_hp = int(arg.trim_prefix("--vip-hp="))
		if arg.begins_with("--evac-y="): evac_y = int(arg.trim_prefix("--evac-y="))
	if trace and mission_filter != "": missions = [mission_filter]
	for id in missions:
		if mission_filter != "" and id != mission_filter: continue
		for diff in ["normal","hard"]:
			if diff_filter != "" and diff != diff_filter: continue
			if trace and diff == "hard": continue
			var wins := 0
			for seed_value in range(1,count+1):
				var row := play(id,diff,seed_value,bot,trace,evac_limit,vip_hp,evac_y)
				if row.result == "win": wins += 1
				print("BENCH,%s,%s,%s,%d,%s,%d,%d,%s" % [id,diff,bot,seed_value,row.result,row.injuries,row.turn,str(row.reason).replace(",",";")])
			print("TOTAL,%s,%s,%s,%d/%d" % [id,diff,bot,wins,count])
	quit()
