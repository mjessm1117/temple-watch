extends RefCounted
class_name RescueMission
const Maps = preload("res://scripts/map_catalog.gd")
const Objectives = preload("res://scripts/mission_objectives.gd")
const Pressure = preload("res://scripts/mission_pressure.gd")
const Hack = preload("res://scripts/mission_hack.gd")
const Telemetry = preload("res://scripts/mission_metrics.gd")
const Families11 = preload("res://scripts/mission11_families.gd")
const Enemy11 = preload("res://scripts/enemy11_tactics.gd")
var objective_state: Dictionary = {}
var pressure_state: Dictionary = {}
var hack_state: Dictionary = {}
var metrics: Dictionary = {}
var modern := false
const Shot = preload("res://scripts/shot.gd")
const AI = preload("res://scripts/ai.gd")
const Settings = preload("res://scripts/settings.gd")
const Ability = preload("res://scripts/abilities_engine.gd")
const Rules12 = preload("res://scripts/rules12_actions.gd")
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
var cover_hp: Dictionary = {}
var reinforcement_marker: Vector2i = Vector2i(-1, -1)
var terrain_revision := 0
var action_events: Array[Dictionary] = []
var ability_uses: Dictionary = {}
var chain_momentum := 0
var chain_strike_used_turn := -1
var clues := 0
var saved_by: Dictionary = {}
func _init(seed_value: int = 1, data_path: String = "res://data/rescue.json") -> void:
	rng.seed = seed_value
	spec = Maps.load_map(data_path)
	assert(not spec.is_empty(), "Mission map missing: " + data_path)
	modern = spec.has("family")
	difficulty = Settings.selected()
	if not modern: spec.turn_limit = int(difficulty.get("turn_clock", spec.turn_limit))
	else:
		var tuning: Dictionary = Maps.read("res://data/maps/balance.json").get(Settings.difficulty,{}).get(str(spec.family),{})
		for key in tuning:
			if key == "objective": spec.objective.merge(tuning.objective,true)
			else: spec[key] = tuning[key]
		if int(spec.objective.get("hold_turns",0)) > 0: spec.objective.hp = maxi(int(spec.objective.hp),int(spec.objective.get("hold_hp",0)))
	catalog = _json("res://data/units.json")
	abilities = preload("res://scripts/class_registry.gd").ability_catalog()
	preload("res://scripts/class_registry.gd").apply_to_units(catalog)
	if modern: Pressure.setup(self)
	if _is_opening_defense26(): pressure_state.opening_contact26 = {"status":"inactive", "activation_trigger":"none"}
	for row in spec.rows: board.append(str(row))
	for y in range(board.size()):
		for x in range(board[y].length()):
			var p := Vector2i(x, y)
			if _destructible(p): cover_hp[p] = 8 if tile(p) == "#" else 4
	prisoner = spec.prisoner.duplicate(true)
	prisoner["freed"] = false
	for entry in spec.squad: _spawn(str(entry[0]), int(entry[1]), int(entry[2]), -1)
	for group_index in range(spec.groups.size()):
		for entry in spec.groups[group_index]: _spawn(str(entry[0]), int(entry[1]), int(entry[2]), group_index)
		for extra in range(int(difficulty.get("extra_per_group", 0))):
			var anchor: Array = spec.groups[group_index][extra % spec.groups[group_index].size()]
			var kinds: Array = difficulty.get("extra_kinds", ["trooper", "trooper", "trooper"])
			_spawn_near(str(kinds[group_index % kinds.size()]), Vector2i(int(anchor[1]), int(anchor[2])), group_index)
	if modern:
		Telemetry.setup(self)
		Objectives.setup(self)
		return
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
		var penalty := int(difficulty.get("enemy_damage", 0))
		u.damage = [maxi(1, int(u.damage[0]) + penalty), maxi(2, int(u.damage[1]) + penalty)]
	else:
		u.aim = int(u.aim) + int(difficulty.get("player_aim", 0))
		u.mob = int(u.mob) + int(difficulty.get("player_mob", 0))
		u.hp = int(u.hp) + int(difficulty.get("player_hp", 0))
		u.max_hp = int(u.hp)
	u["ap"] = Rules12.ACTIONS_PER_TURN if str(u.side) == "player" else 0
	u["focus_left"] = int(u.get("focus", 0))
	u["group"] = group
	u["awake"] = group < 0
	u["spotted"] = group < 0
	u["overwatch"] = false
	u["hunkered"] = false
	u["status"] = "ok"
	u["wounded"] = false
	u["cooldowns"] = {}
	u["medpacs"] = int(u.get("medpacs", 0))
	u["force_revive"] = 1 if kind == "consular" else 0
	u["smoke"] = 1 if kind == "medic" else 0
	u["shield_drone"] = 1 if kind == "medic" else 0
	if modern and str(u.side) == "player": u.concealed = bool(spec.get("concealed",false))
	units.append(u)
func _spawn_near(kind: String, anchor: Vector2i, group: int, max_radius: int = 4) -> void:
	for radius in range(1, max_radius+1):
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
	cover_hp.erase(p)
	if _destructible(p): cover_hp[p] = 8 if c == "#" else 4
func _destructible(p: Vector2i) -> bool:
	if not in_bounds(p) or p.x == 0 or p.y == 0 or p.x == int(spec.width) - 1 or p.y == int(spec.height) - 1: return false
	return tile(p) in ["#", "c", "h", "k"]
func damage_cover(p: Vector2i, damage: int, cause: Dictionary = {}) -> String:
	if not _destructible(p) or damage <= 0: return tile(p)
	var before := tile(p)
	if not cover_hp.has(p): cover_hp[p] = 8 if tile(p) == "#" else 4
	var remaining: int = int(cover_hp[p]) - damage
	if remaining <= 0:
		set_tile(p, "r")
		message("Cover collapses into rubble.")
	elif tile(p) == "#" and remaining <= 4:
		set_tile(p, "c")
		cover_hp[p] = remaining
		message("Full cover cracks into half cover.")
	else: cover_hp[p] = remaining
	if tile(p) != before:
		terrain_revision += 1
		action_events.append({"kind":"cover_break", "at":p, "from_tile":before, "to_tile":tile(p), "cause":cause.get("kind", "environment"), "actor":int(cause.get("actor", -1))})
	return tile(p)
func explode(center: Vector2i, damage: int, radius: int = 1, cause: Dictionary = {}) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var p := Vector2i(x, y)
			if center.distance_to(p) <= float(radius): damage_cover(p, damage, cause)

func passable(p: Vector2i) -> bool:
	return in_bounds(p) and tile(p) not in ["#", "c", "h", "k"] and (not modern or tile(p) != "w")

func occupied(p: Vector2i, except_id: int = -1) -> bool:
	for u in units:
		if (int(u.hp) > 0 or str(u.get("status", "")) == "down") and int(u.id) != except_id and Shot.pos(u) == p: return true
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

func use_ability(id: int, ability_id: String, target_id: int = -1, target_tile: Vector2i = Vector2i(-1, -1)) -> bool:
	var ok: bool = Ability.use(self, id, ability_id, target_id, target_tile)
	if modern and ok:
		if ability_id not in ["hide", "ghost", "meditate", "scout_concealment", "scout_vanish"]: break_concealment("Ability used")
		if ability_id == "beastCalm" and bool(unit_by_id(target_id).get("stunned",false)): pressure_state.calm_turn = turn
		_check_win()
	return ok

func ability_reason(id: int, ability_id: String) -> String:
	return Ability.reason(self, unit_by_id(id), ability_id)

func apply_damage(target: Dictionary, amount: int, _source: Dictionary = {}) -> int:
	if int(target.hp) <= 0: return 0
	amount = preload("res://scripts/ability_chains.gd").damage_amount(self, target, amount, _source)
	if modern: amount = Enemy11.intercept_damage(self,target,amount,_source)
	if modern and bool(_source.get("horror",false)) and str(target.side) == "player" and str(target.class_name) not in ["Guardian","Consular"]: return 0
	var shield: int = int(target.get("shield", 0))
	var absorbed: int = mini(shield, amount)
	target.shield = shield - absorbed
	var actual: int = mini(int(target.hp), maxi(0, amount - absorbed))
	target.hp = int(target.hp) - actual
	if modern: Families11.damage(self,target)
	if int(target.hp) <= 0 and str(target.side) == "player":
		target.status = "down"; target.wounded = true; target.ap = 0; target.overwatch = false; target.hunkered = false
		message("%s is Downed. Revive them this mission." % target.name)
	elif int(target.hp) <= 0:
		message("%s is down." % target.name)
		if _source.get("side", "") == "player": _source.kills = int(_source.get("kills", 0)) + 1
	if actual > 0 and int(target.get("battle_med_source", -1)) == int(target.get("id", -2)):
		for member in units:
			if int(member.get("battle_med_source", -1)) == int(target.id): member.erase("buff_aim"); member.erase("battle_med_source")
			if str(member.get("side", "")) == "enemy": member.erase("debuff_aim")
	if modern and int(target.hp) <= 0: Pressure.on_kill(self,target,_source)
	_check_lose()
	if modern: _check_win()
	return actual

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
func reach_tiles(unit: Dictionary, actions: int) -> Dictionary:
	return Rules12.reach(self, unit, actions)
func move(id: int, dest: Vector2i) -> bool:
	var u := unit_by_id(id)
	if preload("res://scripts/ability_chains.gd").has_tag(u, "PINNED") or preload("res://scripts/ability_chains.gd").has_tag(u, "LIFTED"): return false
	if u.is_empty() or result != "" or phase != str(u.side) or int(u.ap) < 1 or str(u.get("status", "ok")) == "down": return false
	var reach := reach_tiles(u, 2)
	if not reach.costs.has(dest) or dest == Shot.pos(u): return false
	var cost: int = int(reach.costs[dest])
	var ap_cost: int = 1 if cost <= int(u.mob) else 2
	if int(u.ap) < ap_cost: return false
	Rules12.spend_move(u, ap_cost)
	var old: Vector2i = Shot.pos(u)
	if modern: Telemetry.travel(self,u,dest,reach.prev)
	u.x = dest.x
	u.y = dest.y
	if str(u.side) == "player" and turn == 1 and _opening_sight26(dest): _activate_opening_contact26("sight")
	if phase == "enemy": action_events.append({"kind": "move", "actor": id, "from": old, "to": dest})
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
	if preload("res://scripts/ability_chains.gd").has_tag(a, "LIFTED"): return false
	if preload("res://scripts/ability_chains.gd").has_tag(a, "TAUNTED") and int(preload("res://scripts/ability_chains.gd").tags(a).get("TAUNTED", -1)) != target_id: return false
	if a.is_empty() or t.is_empty() or int(t.hp) <= 0 or a.side == t.side or result != "" or phase != str(a.side) or str(a.get("status", "ok")) == "down": return false
	if modern and str(a.side) == "player" and Enemy11.hidden(self,t): return false
	if str(a.side) == "player" and mode not in a.get("kit", []): return false
	var melee := mode == "strike"
	var ap_cost := Rules12.cost(abilities[mode], a)
	if int(a.ap) < ap_cost: return false
	if melee and "strike" not in a.get("kit", []) and str(a.get("side", "")) == "player": return false
	if melee and max(abs(int(a.x) - int(t.x)), abs(int(a.y) - int(t.y))) > 1: return false
	var info: Dictionary = Shot.calculate(self, a, t, melee, int(a.get("leap_aim", 0)) if melee else 0)
	if not bool(info.los) or not bool(info.range_ok): return false
	Rules12.spend(a, abilities[mode])
	_apply_attack(a, t, info, mode)
	if melee: a.leap_aim = 0
	if str(a.side) == "player": _wake_groups()
	_check_lose()
	return true

func _apply_attack(a: Dictionary, t: Dictionary, info: Dictionary, mode: String) -> void:
	if str(a.side) == "player" and mode != "strike": _activate_opening_contact26("shot")
	if modern and str(a.side) == "player": break_concealment("Attack")
	var before_hp := int(t.hp)
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
	if damage > 0 and str(a.side) == "enemy" and str(t.side) == "player" and str(t.get("class_name", "")) in ["Guardian", "Consular"]:
		var deflect_chance := int(t.get("guard_deflect", 0)) if bool(t.get("guard", false)) else int(t.get("deflect", 0))
		if rng.randi_range(1, 100) <= deflect_chance:
			damage = 0; outcome = "is deflected by"
			if bool(t.get("guard", false)) and "reflectM" in t.get("passives", []) and rng.randi_range(1, 100) <= 65:
				var weakest: Dictionary = {}
				for e in living("enemy"):
					if Shot.distance(Shot.pos(t), Shot.pos(e)) <= 6.0 and (weakest.is_empty() or int(e.hp) < int(weakest.hp)): weakest = e
				if not weakest.is_empty(): apply_damage(weakest, 2, t)
	if damage > 0:
		var armor: int = int(t.get("armor", 0))
		damage = max(1, damage - armor)
		apply_damage(t, damage, a)
		if armor > 0: t.armor = armor - 1
		if str(a.get("class_name", "")) == "Heavy" and mode == "shoot":
			var direction := Vector2i(signi(int(a.x) - int(t.x)), signi(int(a.y) - int(t.y)))
			for q in [Shot.pos(t) + Vector2i(direction.x, 0), Shot.pos(t) + Vector2i(0, direction.y)]: damage_cover(q, 3, {"kind":"heavy_shot", "actor":int(a.id)})
	message("%s %s %s%s" % [a.name, outcome, t.name, " for %d." % damage if damage > 0 else "."])
	if phase == "enemy": action_events.append({"kind": "attack", "actor": int(a.id), "target": int(t.id), "from": Shot.pos(a), "to": Shot.pos(t), "mode": mode, "enemy": str(a.side) == "enemy", "outcome": outcome, "damage": before_hp - int(t.hp), "killed": int(t.hp) <= 0})
	if int(t.hp) <= 0 and str(t.side) == "player": t.wounded = true
	if int(t.hp) <= 0 and str(a.side) == "player" and "ghost" in a.get("passives", []) and not bool(a.get("ghost_used", false)):
		a.concealed = true; a.ghost_used = true

func push(id: int, target_id: int) -> bool:
	var a := unit_by_id(id)
	var t := unit_by_id(target_id)
	if a.is_empty() or t.is_empty() or result != "" or phase != str(a.side) or a.side == t.side: return false
	if str(a.get("class_name", "")) not in ["Guardian", "Consular", "Sith Warrior"]: return false
	if int(a.ap) < int(abilities.push.ap) or int(a.focus_left) < int(abilities.push.focus): return false
	if Shot.distance(Shot.pos(a), Shot.pos(t)) > float(abilities.push.range) or not Shot.los(self, Shot.pos(a), Shot.pos(t)): return false
	Rules12.spend(a, abilities.push)
	a.focus_left = int(a.focus_left) - int(abilities.push.focus)
	if modern and str(a.side) == "player": break_concealment("Force push")
	var old_target := Shot.pos(t)
	var before_hp := int(t.hp)
	var delta := Shot.pos(t) - Shot.pos(a)
	var step := Vector2i(signi(delta.x), signi(delta.y))
	for i in range(int(abilities.push.distance)):
		var q: Vector2i = Shot.pos(t) + step
		if not passable(q) or occupied(q, int(t.id)):
			apply_damage(t, int(abilities.push.collision_damage), a)
			message("%s slams %s into cover for 3." % [a.name, t.name])
			if in_bounds(q): damage_cover(q, 4, {"kind":"force_push", "actor":id})
			break
		t.x = q.x; t.y = q.y
	message("%s pushes %s out of position." % [a.name, t.name])
	if phase == "enemy": action_events.append({"kind": "push", "actor": id, "target": target_id, "from": Shot.pos(a), "to": old_target, "destination": Shot.pos(t), "damage": before_hp - int(t.hp), "killed": int(t.hp) <= 0})
	_check_lose()
	return true

func free_prisoner(id: int) -> bool:
	var u := unit_by_id(id)
	if modern: return bool(interact(u,Shot.pos(prisoner)).get("ok",false))
	if u.is_empty() or u.side != "player" or phase != "player" or result != "" or bool(prisoner.freed) or int(u.ap) < 1: return false
	if max(abs(int(u.x) - int(prisoner.x)), abs(int(u.y) - int(prisoner.y))) > 1: return false
	u.ap = int(u.ap) - 1
	prisoner.freed = true
	prisoner.escort_id = id
	message("%s frees Aide Mira Tal. Escort her to evac!" % u.name)
	return true

func _wake_groups() -> void:
	if modern:
		for e in living("enemy"): Enemy11.hidden(self,e)
	var groups: Dictionary = {}
	for u in living("enemy"):
		if int(u.group) < 0 or bool(u.awake): continue
		if _is_opening_defense26() and int(u.group) == int(spec.opening_contact26.group) and str(pressure_state.opening_contact26.status) == "inactive": continue
		if modern and Enemy11.hidden(self,u): continue
		if not groups.has(int(u.group)): groups[int(u.group)] = []
		groups[int(u.group)].append(u)
		for p in living("player"):
			if Shot.distance(Shot.pos(p), Shot.pos(u)) <= 8.0 and Shot.los(self, Shot.pos(p), Shot.pos(u)):
				u.spotted = true
				if modern and (not bool(p.get("concealed",false)) or Shot.distance(Shot.pos(p),Shot.pos(u)) <= 2.0): u.detected = true
	for group in groups:
		var members: Array = groups[group]
		var seen := false
		for u in members:
			if bool(u.spotted) and (not modern or bool(u.get("detected",false))): seen = true
		if not seen: continue
		var active := 0
		for u in living("enemy"):
			if bool(u.awake): active += 1
		if active + members.size() > int(difficulty.get("active_cap", 6)): continue
		if modern: break_concealment("Enemy contact"); Telemetry.contact(self)
		message("Enemy group %d spotted and activated!" % (int(group) + 1))
		if phase == "enemy": action_events.append({"kind": "activation", "actor": int(members[0].id), "at": Shot.pos(members[0])})
		for u in members: u.awake = true
		for u in members: AI.scamper(self, u)

func _reaction_fire(mover: Dictionary) -> void:
	for p in living("player"):
		if int(mover.get("suppressed_by", -1)) == int(p.id):
			var pinned_info: Dictionary = Shot.calculate(self, p, mover, false, -15)
			if bool(pinned_info.los) and bool(pinned_info.range_ok): _apply_attack(p, mover, pinned_info, "shoot")
			mover.erase("suppressed_by")
		if not bool(p.overwatch): continue
		var info: Dictionary = Shot.calculate(self, p, mover, false, -15)
		if bool(info.los) and bool(info.range_ok):
			p.overwatch = false
			if modern: message("OVERWATCH: %s fires." % p.name)
			_apply_attack(p, mover, info, "shoot")

func _enemy_reaction_fire(mover: Dictionary) -> void:
	for e in living("enemy"):
		if not bool(e.awake) or not bool(e.overwatch): continue
		var info: Dictionary = Shot.calculate(self, e, mover, false, -15)
		if bool(info.los) and bool(info.range_ok):
			e.overwatch = false
			if modern: message("OVERWATCH: %s fires." % e.name)
			_apply_attack(e, mover, info, "shoot")

func overwatch(id: int) -> bool:
	var u := unit_by_id(id)
	if u.is_empty() or u.side != "player" or phase != "player" or int(u.ap) <= 0 or result != "": return false
	if "overwatch" not in u.get("kit", []): return false
	u.ap = 0
	u.overwatch = true
	message("%s watches the lane." % u.name)
	return true

func hunker(id: int) -> bool:
	var u := unit_by_id(id)
	if u.is_empty() or u.side != "player" or phase != "player" or int(u.ap) <= 0 or result != "": return false
	if "hunker" not in u.get("kit", []): return false
	u.ap = int(u.ap) - 1
	u.hunkered = true
	u.overwatch = false
	message("%s hunkers down (+30 defense; flank critical blocked)." % u.name)
	return true

func end_turn() -> void:
	if result != "" or phase != "player": return
	begin_enemy_turn()
	var fired: Dictionary = {}
	for e in living("enemy"):
		if result != "": break
		enemy_actor(e, fired)
	finish_enemy_turn()

func begin_enemy_turn() -> void:
	if result != "" or phase != "player": return
	action_events.clear()
	if bool(prisoner.freed): _civilian_advance()
	_check_win()
	if result != "": return
	phase = "enemy"
	_wake_groups()
	for u in living("enemy"): u.ap = Rules12.ACTIONS_PER_TURN; u.overwatch = false
	if modern: Pressure.brood(self)

func enemy_actor(e: Dictionary, fired: Dictionary) -> void:
	if result != "" or phase != "enemy": return
	if modern and Enemy11.act(self,e,fired): return
	if modern and Objectives.runner_turn(self,e): return
	if modern and Hack.controlled_turn(self,e): return
	if modern and bool(e.awake) and Pressure.horror_turn(self,e): return
	if modern and bool(e.awake) and Rules12.defense_turn(self,e): return
	if bool(e.awake): AI.act(self,e,fired)

func finish_enemy_turn() -> void:
	if result != "" or phase != "enemy": return
	_check_lose()
	if result != "": return
	if modern: Objectives.enemy_end(self)
	if result != "": return
	turn += 1
	if not modern and turn > int(spec.turn_limit):
		result = "loss"
		message("The evacuation window closes. Mission failed.")
		return
	phase = "player"
	for p in living("player"):
		if modern and bool(p.overwatch): message("Overwatch held: nothing crossed %s's sight." % p.name)
		p.ap = Rules12.ACTIONS_PER_TURN; p.overwatch = false; p.hunkered = false
		if int(p.get("buff_until", 0)) <= turn: p.erase("buff_defense"); p.erase("buff_aim")
		if int(p.get("guard_until", 0)) <= turn: p.erase("guard")
	for e in living("enemy"):
		if int(e.get("debuff_until", 0)) <= turn: e.erase("debuff_aim")
		if int(e.get("stunned_until", 0)) < turn: e.erase("stunned")
		if int(e.get("marked_until", 0)) <= turn: e.erase("marked_aim"); e.erase("marked")
		if int(e.get("suppressed_until", 0)) <= turn: e.erase("suppressed_by"); e.erase("suppressed")
	if modern:
		if turn == 2: _activate_opening_contact26("turn_2")
		Objectives.player_start(self)
		if result != "": return
		Pressure.player_start(self); Hack.player_start(self); Telemetry.sample(self); _wake_groups()
		return
	if turn == int(spec.reinforcement.announce_turn) and int(difficulty.get("reinforcement_size", 2)) > 0:
		reinforcement_announced = true
		reinforcement_marker = Vector2i(int(spec.reinforcement.units[0][1]), int(spec.reinforcement.units[0][2]))
		message("INBOUND: Sith reinforcements at (%d,%d) next turn!" % [reinforcement_marker.x, reinforcement_marker.y])
	if turn == int(spec.reinforcement.drop_turn) and int(difficulty.get("reinforcement_size", 2)) > 0:
		reinforcement_dropped = true
		reinforcement_marker = Vector2i(-1, -1)
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
	var evac := Maps.point(spec.evac[0]) if modern else Vector2i(5, 23)
	var best := p
	for q in reach.costs:
		if modern:
			var distance := INF; var best_distance := INF
			for at in spec.evac:
				distance = minf(distance,Shot.distance(q,Maps.point(at)))
				best_distance = minf(best_distance,Shot.distance(best,Maps.point(at)))
			if distance < best_distance: best = q
		elif Shot.distance(q, evac) < Shot.distance(best, evac): best = q
	if best != p:
		prisoner.x = best.x; prisoner.y = best.y
		message("%s follows the squad toward evac." % str(prisoner.get("name","Mira")))

func _check_win() -> void:
	if modern:
		Telemetry.sample(self); Objectives.check(self)
		return
	if not bool(prisoner.freed): return
	var p := Vector2i(int(prisoner.x), int(prisoner.y))
	if tile(p) == "E" or (abs(p.x - 5) + abs(p.y - 23) <= 2 and living("player").any(func(u: Dictionary) -> bool: return Shot.distance(Shot.pos(u), p) <= 2.0)):
		result = "win"
		message("Aide Mira Tal reaches evac. Mission complete!")

func _check_lose() -> void:
	if living("player").is_empty():
		result = "loss"
		message("The squad is lost. Mission failed.")

func interact(unit: Dictionary, at: Vector2i) -> Dictionary:
	if modern: return Objectives.interact(self,unit,at)
	return {"ok":free_prisoner(int(unit.get("id",-1))) if at == Shot.pos(prisoner) else false}

func interactables() -> Array[Vector2i]:
	if modern: return Objectives.targets(self)
	var out: Array[Vector2i] = []
	if not bool(prisoner.freed) and result == "": out.append(Shot.pos(prisoner))
	return out

func objective_status() -> Dictionary:
	return Objectives.status(self) if modern else {"label":"Rescue Mira and escort to evac","turns_left":int(spec.turn_limit)-turn+1,"phase":"evac" if prisoner.freed else "primary"}

func break_concealment(reason: String) -> void:
	if not modern: return
	var hidden := false
	for u in living("player"):
		hidden = hidden or bool(u.get("concealed",false)); u.concealed = false
	if int(objective_state.get("clock_start",0)) == 0: objective_state.clock_start = turn
	if hidden: message("Concealment broken: " + reason)

func queue_reinforcement(kinds: Array, delay: int = 1, reason: String = "Reinforcements") -> void:
	if modern: Pressure.queue(self,kinds,delay,reason)

func _is_opening_defense26() -> bool:
	return modern and str(spec.get("family", "")) == "defend" and bool(spec.get("first_mission", false)) and spec.has("opening_contact26")

func _opening_sight26(at: Vector2i) -> bool:
	if not _is_opening_defense26() or str(pressure_state.opening_contact26.status) != "inactive": return false
	for enemy in living("enemy"):
		if int(enemy.group) != int(spec.opening_contact26.group): continue
		if Shot.distance(Shot.pos(enemy), at) <= 8.0 and Shot.los(self, Shot.pos(enemy), at): return true
	return false

func _activate_opening_contact26(trigger: String) -> void:
	if not _is_opening_defense26() or str(pressure_state.opening_contact26.status) != "inactive": return
	pressure_state.opening_contact26 = {"status":"active", "activation_trigger":trigger}
	var marker := Vector2i(-1, -1)
	var actor_id := -1
	for enemy in living("enemy"):
		if int(enemy.group) != int(spec.opening_contact26.group): continue
		enemy.awake = true; enemy.spotted = true; enemy.detected = true
		if marker.x < 0: marker = Shot.pos(enemy); actor_id = int(enemy.id)
	if marker.x >= 0:
		reinforcement_marker = marker
		action_events.append({"kind":"activation", "actor":actor_id, "at":marker})
	message("ENEMY REINFORCEMENT APPROACHING — east pod activated.")

func opening_contact26() -> Dictionary:
	if not _is_opening_defense26(): return {}
	return {"pod":"east", "status":str(pressure_state.opening_contact26.status), "activation_trigger":str(pressure_state.opening_contact26.activation_trigger)}

func next_wave26() -> Dictionary:
	return Pressure.next_wave26(self) if modern else {}

func hack(unit: Dictionary, at: Vector2i, mode: String = "safe") -> Dictionary:
	return Hack.use(self,unit,at,mode) if modern else {"ok":false,"reason":"Use the existing Hack ability"}

func damage_objective(amount: int) -> void:
	if modern and amount > 0 and spec.family == "destroy_relay": break_concealment("Relay damaged")
	if modern: Objectives.damage_relay(self,amount)
