extends RefCounted
class_name RescueMission

const Shot = preload("res://scripts/shot.gd")
const AI = preload("res://scripts/ai.gd")
const Settings = preload("res://scripts/settings.gd")
var spec: Dictionary
var catalog: Dictionary
var abilities: Dictionary
var board: Array[String] = []
var units: Array[Dictionary] = []
var prisoner: Dictionary = {}
var turn: int = 1
var phase: String = "player"
var result: String = ""
var log_lines: Array[String] = []
var rng := RandomNumberGenerator.new()
var reinforcement_announced := false
var reinforcement_dropped := false
var next_id := 0
var difficulty: Dictionary = {}

func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value
	spec = _json("res://data/rescue.json")
	difficulty = Settings.selected()
	spec.turn_limit = int(difficulty.get("turn_clock", spec.turn_limit))
	catalog = _json("res://data/units.json")
	abilities = _json("res://data/abilities.json")
	for row in spec.rows: board.append(str(row))
	prisoner = spec.prisoner.duplicate(true)
	prisoner["freed"] = false
	for entry in spec.squad: _spawn(str(entry[0]), int(entry[1]), int(entry[2]), -1)
	for group_index in range(spec.groups.size()):
		for entry in spec.groups[group_index]: _spawn(str(entry[0]), int(entry[1]), int(entry[2]), group_index)
		for extra in range(int(difficulty.get("extra_per_group", 0))):
			var anchor: Array = spec.groups[group_index][extra % spec.groups[group_index].size()]
			_spawn_near("trooper", Vector2i(int(anchor[1]), int(anchor[2])), group_index)
	message("Rescue Aide Mira Tal, then escort her to the blue evac tiles before turn %d." % int(spec.turn_limit))

static func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _spawn(kind: String, x: int, y: int, group: int) -> void:
	var u: Dictionary = catalog[kind].duplicate(true)
	u["id"] = next_id
	next_id += 1
	u["kind"] = kind
	u["x"] = x
	u["y"] = y
	u["max_hp"] = int(u.hp)
	if str(u.side) == "enemy":
		u.hp = maxi(1, int(u.hp) + int(difficulty.get("enemy_hp", 0)))
		u.max_hp = int(u.hp)
		u.aim = int(u.aim) + int(difficulty.get("enemy_aim", 0))
	else: u.aim = int(u.aim) + int(difficulty.get("player_aim", 0))
	u["ap"] = 3 if str(u.side) == "player" else 0
	u["focus_left"] = int(u.get("focus", 0))
	u["group"] = group
	u["awake"] = group < 0
	u["spotted"] = group < 0
	u["overwatch"] = false
	units.append(u)

func _spawn_near(kind: String, anchor: Vector2i, group: int) -> void:
	for radius in range(1, 5):
		for y in range(anchor.y - radius, anchor.y + radius + 1):
			for x in range(anchor.x - radius, anchor.x + radius + 1):
				var q := Vector2i(x, y)
				if passable(q) and not occupied(q):
					_spawn(kind, x, y, group)
					return

func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < int(spec.width) and p.y < int(spec.height)

func tile(p: Vector2i) -> String:
	if not in_bounds(p): return "#"
	return board[p.y].substr(p.x, 1)

func set_tile(p: Vector2i, c: String) -> void:
	if not in_bounds(p): return
	board[p.y] = board[p.y].substr(0, p.x) + c + board[p.y].substr(p.x + 1)

func passable(p: Vector2i) -> bool:
	return in_bounds(p) and tile(p) not in ["#", "c", "h", "k"]

func occupied(p: Vector2i, except_id: int = -1) -> bool:
	for u in units:
		if int(u.hp) > 0 and int(u.id) != except_id and Shot.pos(u) == p: return true
	return Vector2i(int(prisoner.x), int(prisoner.y)) == p

func unit_by_id(id: int) -> Dictionary:
	for u in units:
		if int(u.id) == id: return u
	return {}

func living(side: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u in units:
		if str(u.side) == side and int(u.hp) > 0: out.append(u)
	return out

func message(value: String) -> void:
	log_lines.append(value)
	if log_lines.size() > 12: log_lines.pop_front()

func _neighbors(p: Vector2i, ignore_id: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in Shot.DIRS:
		var q: Vector2i = p + d
		if passable(q) and not occupied(q, ignore_id) and abs(Shot.elevation(self, q) - Shot.elevation(self, p)) <= 2: out.append(q)
	return out

func paths(u: Dictionary, budget: int = 10) -> Dictionary:
	var start: Vector2i = Shot.pos(u)
	var costs: Dictionary = {start: 0}
	var prev: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		for q in _neighbors(p, int(u.id)):
			var step: int = 2 if abs(Shot.elevation(self, q) - Shot.elevation(self, p)) == 2 else 1
			var cost: int = int(costs[p]) + step
			if cost > budget or (costs.has(q) and int(costs[q]) <= cost): continue
			costs[q] = cost
			prev[q] = p
			queue.append(q)
	return {"costs": costs, "prev": prev}

func move(id: int, dest: Vector2i) -> bool:
	var u := unit_by_id(id)
	if u.is_empty() or result != "" or phase != str(u.side) or int(u.ap) < 1: return false
	var reach := paths(u, int(u.mob) * 2)
	if not reach.costs.has(dest) or dest == Shot.pos(u): return false
	var cost: int = int(reach.costs[dest])
	var ap_cost: int = 1 if cost <= int(u.mob) else 2
	if int(u.ap) < ap_cost: return false
	u.ap = int(u.ap) - ap_cost
	var old: Vector2i = Shot.pos(u)
	u.x = dest.x
	u.y = dest.y
	message("%s moves %d tiles (%d AP)." % [u.name, cost, ap_cost])
	if str(u.side) == "player":
		if bool(prisoner.freed):
			var escort: Dictionary = unit_by_id(int(prisoner.get("escort_id", -1)))
			if escort.is_empty() or int(escort.hp) <= 0:
				if Shot.distance(old, Vector2i(int(prisoner.x), int(prisoner.y))) <= 3.0:
					prisoner.escort_id = id
					message("%s takes over the escort." % u.name)
			if int(prisoner.get("escort_id", -1)) == id: _follow_prisoner(old, dest)
		_wake_groups()
		_enemy_reaction_fire(u)
		_check_win()
	else: _reaction_fire(u)
	return true

func _follow_prisoner(old: Vector2i, dest: Vector2i) -> void:
	var p := Vector2i(int(prisoner.x), int(prisoner.y))
	var delta := dest - p
	if abs(delta.x) + abs(delta.y) <= 1: return
	# The rescued civilian retraces the escort's route to their previous position.
	var proxy: Dictionary = {"id": -99, "x": p.x, "y": p.y, "mob": 10}
	var reach := paths(proxy, 40)
	var target := old
	if not reach.costs.has(target):
		var best := 999
		for q in reach.costs:
			var score: int = abs(q.x - dest.x) + abs(q.y - dest.y)
			if score < best: best = score; target = q
	var route: Array[Vector2i] = []
	while target != p and reach.prev.has(target):
		route.push_front(target)
		target = reach.prev[target]
	for i in range(route.size()):
		prisoner.x = route[i].x
		prisoner.y = route[i].y

func shot(id: int, target_id: int, mode: String = "shoot") -> bool:
	var a := unit_by_id(id)
	var t := unit_by_id(target_id)
	if a.is_empty() or t.is_empty() or int(t.hp) <= 0 or a.side == t.side or result != "" or phase != str(a.side): return false
	var melee := mode == "strike"
	var ap_cost := int(abilities[mode].ap)
	if int(a.ap) < ap_cost: return false
	if melee and str(a.get("class_name", "")) not in ["Guardian", "Consular", "Sith Warrior"]: return false
	if melee and max(abs(int(a.x) - int(t.x)), abs(int(a.y) - int(t.y))) > 1: return false
	var info: Dictionary = Shot.calculate(self, a, t, melee)
	if not bool(info.los) or not bool(info.range_ok): return false
	a.ap = int(a.ap) - ap_cost
	_apply_attack(a, t, info, mode)
	if str(a.side) == "player": _wake_groups()
	_check_lose()
	return true

func _apply_attack(a: Dictionary, t: Dictionary, info: Dictionary, mode: String) -> void:
	var roll := rng.randf_range(0.0, 100.0)
	var damage := 0
	var outcome := "misses"
	if roll < int(info.hit):
		damage = rng.randi_range(int(a.damage[0]), int(a.damage[1]))
		if rng.randf_range(0.0, 100.0) < int(info.crit): damage += 2; outcome = "crits"
		else: outcome = "hits"
	elif mode == "shoot" and roll < int(info.hit) + Shot.GRAZE:
		damage = ceili(float(rng.randi_range(int(a.damage[0]), int(a.damage[1]))) / 2.0)
		outcome = "grazes"
	if damage > 0:
		var armor: int = int(t.get("armor", 0))
		damage = max(1, damage - armor)
		t.hp = max(0, int(t.hp) - damage)
		if armor > 0: t.armor = armor - 1
	message("%s %s %s%s" % [a.name, outcome, t.name, " for %d." % damage if damage > 0 else "."])
	if int(t.hp) <= 0: message("%s is down." % t.name)

func push(id: int, target_id: int) -> bool:
	var a := unit_by_id(id)
	var t := unit_by_id(target_id)
	if a.is_empty() or t.is_empty() or result != "" or phase != str(a.side) or a.side == t.side: return false
	if str(a.get("class_name", "")) not in ["Guardian", "Consular", "Sith Warrior"]: return false
	if int(a.ap) < int(abilities.push.ap) or int(a.focus_left) < int(abilities.push.focus): return false
	if Shot.distance(Shot.pos(a), Shot.pos(t)) > float(abilities.push.range) or not Shot.los(self, Shot.pos(a), Shot.pos(t)): return false
	a.ap = int(a.ap) - int(abilities.push.ap)
	a.focus_left = int(a.focus_left) - int(abilities.push.focus)
	var delta := Shot.pos(t) - Shot.pos(a)
	var step := Vector2i(signi(delta.x), signi(delta.y))
	for i in range(int(abilities.push.distance)):
		var q: Vector2i = Shot.pos(t) + step
		if not passable(q) or occupied(q, int(t.id)):
			t.hp = max(0, int(t.hp) - int(abilities.push.collision_damage))
			message("%s slams %s into cover for 3." % [a.name, t.name])
			if in_bounds(q) and tile(q) in ["#", "c", "h"]:
				set_tile(q, "r")
				message("Cover breaks into rubble.")
			break
		t.x = q.x; t.y = q.y
	message("%s pushes %s out of position." % [a.name, t.name])
	_check_lose()
	return true

func free_prisoner(id: int) -> bool:
	var u := unit_by_id(id)
	if u.is_empty() or u.side != "player" or phase != "player" or result != "" or bool(prisoner.freed) or int(u.ap) < 1: return false
	if max(abs(int(u.x) - int(prisoner.x)), abs(int(u.y) - int(prisoner.y))) > 1: return false
	u.ap = int(u.ap) - 1
	prisoner.freed = true
	prisoner.escort_id = id
	message("%s frees Aide Mira Tal. Escort her to evac!" % u.name)
	return true

func _wake_groups() -> void:
	var groups: Dictionary = {}
	for u in living("enemy"):
		if int(u.group) < 0 or bool(u.awake): continue
		if not groups.has(int(u.group)): groups[int(u.group)] = []
		groups[int(u.group)].append(u)
		for p in living("player"):
			if Shot.distance(Shot.pos(p), Shot.pos(u)) <= 8.0 and Shot.los(self, Shot.pos(p), Shot.pos(u)):
				u.spotted = true
	for group in groups:
		var members: Array = groups[group]
		var seen := false
		for u in members:
			if bool(u.spotted): seen = true
		if not seen: continue
		var active := 0
		for u in living("enemy"):
			if bool(u.awake): active += 1
		if active + members.size() > int(difficulty.get("active_cap", 6)): continue
		message("Enemy group %d spotted and activated!" % (int(group) + 1))
		for u in members: u.awake = true
		for u in members: AI.scamper(self, u)

func _reaction_fire(mover: Dictionary) -> void:
	for p in living("player"):
		if not bool(p.overwatch): continue
		var info: Dictionary = Shot.calculate(self, p, mover, false, -15)
		if bool(info.los) and bool(info.range_ok):
			p.overwatch = false
			_apply_attack(p, mover, info, "shoot")

func _enemy_reaction_fire(mover: Dictionary) -> void:
	for e in living("enemy"):
		if not bool(e.awake) or not bool(e.overwatch): continue
		var info: Dictionary = Shot.calculate(self, e, mover, false, -15)
		if bool(info.los) and bool(info.range_ok):
			e.overwatch = false
			_apply_attack(e, mover, info, "shoot")

func overwatch(id: int) -> bool:
	var u := unit_by_id(id)
	if u.is_empty() or u.side != "player" or phase != "player" or int(u.ap) <= 0 or result != "": return false
	u.ap = 0
	u.overwatch = true
	message("%s watches the lane." % u.name)
	return true

func end_turn() -> void:
	if result != "" or phase != "player": return
	if bool(prisoner.freed): _civilian_advance()
	_check_win()
	if result != "": return
	phase = "enemy"
	_wake_groups()
	for u in living("enemy"): u.ap = 3; u.overwatch = false
	var fired: Dictionary = {}
	for e in living("enemy"):
		if bool(e.awake): AI.act(self, e, fired)
	_check_lose()
	if result != "": return
	turn += 1
	if turn > int(spec.turn_limit):
		result = "loss"
		message("The evacuation window closes. Mission failed.")
		return
	phase = "player"
	for p in living("player"): p.ap = 3; p.overwatch = false
	if turn == int(spec.reinforcement.announce_turn) and int(difficulty.get("reinforcement_size", 2)) > 0:
		reinforcement_announced = true
		message("INBOUND: Sith reinforcements approaching from the east next turn!")
	if turn == int(spec.reinforcement.drop_turn) and int(difficulty.get("reinforcement_size", 2)) > 0:
		reinforcement_dropped = true
		for i in range(int(difficulty.get("reinforcement_size", 2))):
			var entry: Array = spec.reinforcement.units[i % spec.reinforcement.units.size()]
			_spawn_near(str(entry[0]), Vector2i(int(entry[1]), int(entry[2])), 99)
			units.back().spotted = true
		message("Sith reinforcements land on the eastern road.")
	_wake_groups()

func _civilian_advance() -> void:
	var escort: Dictionary = unit_by_id(int(prisoner.get("escort_id", -1)))
	if escort.is_empty() or int(escort.hp) <= 0: return
	var p := Vector2i(int(prisoner.x), int(prisoner.y))
	if Shot.distance(Shot.pos(escort), p) > 6.0: return
	var proxy: Dictionary = {"id": -99, "x": p.x, "y": p.y, "mob": 5}
	var reach := paths(proxy, 5)
	var evac := Vector2i(5, 23)
	var best := p
	for q in reach.costs:
		if Shot.distance(q, evac) < Shot.distance(best, evac): best = q
	if best != p:
		prisoner.x = best.x; prisoner.y = best.y
		message("Mira follows the squad toward evac.")

func _check_win() -> void:
	if not bool(prisoner.freed): return
	var p := Vector2i(int(prisoner.x), int(prisoner.y))
	if tile(p) == "E" or (abs(p.x - 5) + abs(p.y - 23) <= 2 and living("player").any(func(u: Dictionary) -> bool: return Shot.distance(Shot.pos(u), p) <= 2.0)):
		result = "win"
		message("Aide Mira Tal reaches evac. Mission complete!")

func _check_lose() -> void:
	if living("player").is_empty():
		result = "loss"
		message("The squad is lost. Mission failed.")
