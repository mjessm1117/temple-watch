extends SceneTree
const Mission = preload("res://scripts/combat_mission.gd")
const Shot = preload("res://scripts/shot.gd")
const AI = preload("res://scripts/ai.gd")
const Cover = preload("res://scripts/w29c_cover.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func blank() -> RefCounted:
	var m = Mission.new(1, "res://data/maps/taris.json")
	m.spec.width = 12; m.spec.height = 12; m.board.clear(); m.units.clear(); m.cover_hp.clear()
	for y in range(12): m.board.append("............")
	return m

func run() -> void:
	var m = blank()
	m._spawn("soldier", 3, 5, -1); m._spawn("trooper", 6, 5, -1)
	var soldier: Dictionary = m.units[0]; var trooper: Dictionary = m.units[1]
	var level := Shot.calculate(m, soldier, trooper)
	m.set_tile(Vector2i(3, 5), "^")
	var above := Shot.calculate(m, soldier, trooper)
	check(int(above.hit) == mini(95, int(level.hit) + 20), "high attacker gains 20 aim")
	m.set_tile(Vector2i(3, 5), "."); m.set_tile(Vector2i(6, 5), "^")
	var below := Shot.calculate(m, soldier, trooper)
	check(int(below.hit) == maxi(5, int(level.hit) - 10), "one-tier high defender gains 10 defense")
	check(below.lines.any(func(item): return item[0] == "Target high ground defense"), "defense is explained in aim lines")
	m.set_tile(Vector2i(6, 5), ".")
	for x in range(2, 5): m.set_tile(Vector2i(x, 5), "^")
	check(not Shot.los(m, Vector2i(2, 5), Vector2i(5, 5)), "back from ledge cannot see directly below")
	check(Shot.los(m, Vector2i(4, 5), Vector2i(5, 5)), "unit at rim can see directly below")
	for x in range(2, 5): m.set_tile(Vector2i(x, 5), ".")
	m.set_tile(Vector2i(5, 5), "#")
	trooper.x = 6; soldier.x = 3
	check(Shot.cover(m, Shot.pos(trooper), Shot.pos(soldier)) == 40, "defender starts behind full cover")
	m.damage_cover(Vector2i(5, 5), 1, {"kind":"explosion", "actor":int(soldier.id)})
	check(m.tile(Vector2i(5, 5)) == "r" and Shot.cover(m, Shot.pos(trooper), Shot.pos(soldier)) == 0, "blast makes rubble and removes defense immediately")
	check(m.action_events.any(func(event): return event.kind == "cover_break" and event.to_tile == "r"), "cover break is emitted")
	m.set_tile(Vector2i(5, 5), "#")
	m.explode(Vector2i(5, 5), 1, 1, {"kind":"grenade", "actor":int(soldier.id)})
	check(m.tile(Vector2i(5, 5)) == "r", "grenade destroys cover within radius")
	m.set_tile(Vector2i(5, 5), "#")
	var heavy := soldier.duplicate(); heavy.class_name = "Heavy"
	Cover.shot_chip(m, heavy, trooper, "shoot", "hits")
	check(m.tile(Vector2i(5, 5)) == "r", "heavy hit can destroy full cover in one strike")
	m.set_tile(Vector2i(5, 5), "c")
	var front := Shot.calculate(m, soldier, trooper)
	soldier.x = 6; soldier.y = 8
	var flank := Shot.calculate(m, soldier, trooper)
	check(int(front.cover) == 20 and int(flank.cover) == 0 and bool(flank.flanked), "flank removes cover defense")
	check(int(flank.crit) >= int(front.crit) + 50, "flank adds critical chance")
	var ai = blank()
	ai._spawn("trooper", 2, 5, -1); ai._spawn("soldier", 5, 5, -1)
	ai.set_tile(Vector2i(4, 5), "c")
	var enemy: Dictionary = ai.units[0]
	enemy.ap = 2; ai.phase = "enemy"
	var route := AI._flank_route(ai, enemy, ai.units[1])
	check(route != Shot.pos(enemy), "reachable flank route exists")
	AI.act(ai, enemy, {})
	check(Shot.pos(enemy) == route, "AI takes flank route")
	check(ai.action_events.size() > 0 and ai.action_events.all(func(event): return str(event.get("reason24", "")) != "" and str(event.get("reason27", "")) != ""), "AI action events record both reason fields")
	var events_before: int = ai.action_events.size()
	var tactics: Dictionary = ai.w33b_tile_tactics(Vector2i(5, 5))
	check(ai.has_method("w33b_tile_tactics") and ai.action_events.size() == events_before, "guarded tactics API is read-only")
	check(tactics.has_all(["cover", "height_tier", "flanked_by", "overwatch_threat", "destructible"]), "tile tactics exposes every key")
	check(tactics.cover.has_all(["north", "east", "south", "west"]), "directional cover exposed")
	check(tactics.cover.west == "half" and int(tactics.flanked_by) == 1, "preview reports half cover and one flanker")
	enemy.overwatch = true
	check(bool(ai.w33b_tile_tactics(Vector2i(5, 5)).overwatch_threat), "preview reports Overwatch threat")
	check(bool(ai.w33b_tile_tactics(Vector2i(4, 5)).destructible), "preview marks cover as destructible")
	var high_score := AI.destination_score(ai, enemy, Vector2i(3, 5))
	ai.set_tile(Vector2i(3, 5), "^")
	check(AI.destination_score(ai, enemy, Vector2i(3, 5)) > high_score, "AI values high ground")
	var choke = blank()
	choke._spawn("trooper", 3, 5, -1); choke._spawn("soldier", 7, 5, -1)
	for y in range(1, 11): choke.set_tile(Vector2i(4, y), "#")
	choke.set_tile(Vector2i(2, 5), "#")
	choke.phase = "enemy"; choke.units[0].ap = 2
	AI.act(choke, choke.units[0], {})
	check(bool(choke.units[0].overwatch) and choke.action_events.any(func(event): return event.kind == "overwatch" and event.reason24 == "Chokepoint lane"), "AI holds chokepoint on Overwatch with reason")
	var actions = blank()
	actions._spawn("soldier", 2, 2, -1); actions._spawn("trooper", 5, 2, -1)
	actions.set_tile(Vector2i(3, 2), "M")
	check(int(actions.paths(actions.units[0], 2).costs[Vector2i(3, 2)]) == 2, "two-tier climb keeps two-move cost")
	check(int(actions.units[0].ap) == 2, "turn starts with two actions")
	check(actions.shot(int(actions.units[0].id), int(actions.units[1].id)) and int(actions.units[0].ap) == 0, "firing ends turn")
	print("TERRAIN33 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
