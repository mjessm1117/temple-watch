extends SceneTree

const Mission = preload("res://scripts/mission.gd")
const Rules = preload("res://scripts/rules12_actions.gd")
const AI = preload("res://scripts/ai.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; print("FAIL: ", label)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if "--trace" in OS.get_cmdline_user_args():
		trace_families()
		return
	var m = Mission.new(1)
	var u: Dictionary = m.living("player")[0]
	check(int(u.ap) == 2, "player begins with two actions")
	var blue: Dictionary = m.reach_tiles(u, 1)
	var yellow: Dictionary = m.reach_tiles(u, 2)
	check(yellow.costs.size() > blue.costs.size(), "dash ring extends normal movement")
	var dash := Vector2i(-1, -1)
	for tile in yellow.costs:
		if int(yellow.costs[tile]) > int(u.mob): dash = tile; break
	check(dash.x >= 0 and m.move(int(u.id), dash) and int(u.ap) == 0, "dash uses both actions")
	check(not m.move(int(u.id), Vector2i(4, 20)), "dash prevents another move")
	var shot = Mission.new(1)
	shot.spec.width = 12; shot.spec.height = 12; shot.board.clear()
	for row in 12: shot.board.append("............")
	shot.units.clear(); shot.next_id = 0
	shot._spawn("soldier", 2, 2, -1); shot._spawn("trooper", 5, 2, -1)
	var shooter: Dictionary = shot.units[0]
	var target: Dictionary = shot.units[1]
	check(shot.move(int(shooter.id), Vector2i(3, 2)) and int(shooter.ap) == 1, "normal move spends one action")
	check(shot.shot(int(shooter.id), int(target.id)) and int(shooter.ap) == 0, "shot after move ends turn")
	var watch = Mission.new(1)
	var watcher: Dictionary = watch.living("player")[0]
	watcher.kit.append("overwatch")
	var watch_reach: Dictionary = watch.reach_tiles(watcher, 1)
	var watch_dest := Vector2i(-1,-1)
	for tile in watch_reach.costs:
		if tile != Vector2i(int(watcher.x), int(watcher.y)):
			watch_dest = tile; break
	check(watch_dest.x >= 0 and watch.move(int(watcher.id), watch_dest) and int(watcher.ap) == 1, "one action move leaves one action")
	check(watch.overwatch(int(watcher.id)) and bool(watcher.overwatch), "overwatch remains available after one action move")
	var reload = Mission.new(1)
	var r: Dictionary = reload.living("player")[0]
	r.ammo = 0; r.clip = 4; r.kit.append_array(["reload", "hunker"])
	check(reload.use_ability(int(r.id), "reload") and int(r.ap) == 1, "reload spends one action")
	check(reload.hunker(int(r.id)) and int(r.ap) == 0, "hunker spends remaining action")
	var enemy_turn = Mission.new(1)
	enemy_turn.spec.width = 14; enemy_turn.spec.height = 12; enemy_turn.board.clear()
	for row in 12: enemy_turn.board.append("..............")
	enemy_turn.units.clear(); enemy_turn.next_id = 0
	enemy_turn._spawn("soldier", 10, 2, -1); enemy_turn._spawn("trooper", 2, 2, -1)
	var enemy: Dictionary = enemy_turn.units[1]
	enemy_turn.phase = "enemy"; enemy.ap = 2; enemy.awake = true; enemy.range = 1.5
	AI.act(enemy_turn, enemy, {})
	check(int(enemy.ap) == 0 and int(enemy.x) > 2, "enemy dashes toward an out of range target")
	for id in m.abilities:
		var ability: Dictionary = m.abilities[id]
		check(ability.has("cost") and ability.has("ends_turn"), "%s declares both action fields" % id)
		check(int(ability.cost) >= 0 and int(ability.cost) <= 2, "%s fits two action economy" % id)
	print("RULES12 RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func trace_families() -> void:
	var Campaign = preload("res://scripts/campaign/state.gd")
	var Battle = preload("res://scripts/campaign/battle_bridge.gd")
	var Bot = preload("res://tests/campaign_bot.gd")
	for id in ["r_caves", "r_ravine", "r_seventh"]:
		var c = Campaign.new("normal")
		c.state.options = [{"mission":id,"map_variant":0,"adv":false}]
		c.select_mission(0)
		var m = Battle.create(c,1)
		for step in 60:
			if m.result != "": break
			Bot.turn(m)
		print("TRACE %s: result=%s turn=%d objective=%s status=%s log=%s" % [id,m.result,m.turn,JSON.stringify(m.objective_state),JSON.stringify(m.objective_status()),JSON.stringify(m.log_lines)])
	quit(0)
