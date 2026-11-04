extends RefCounted
const Shot = preload("res://scripts/shot.gd")
const Bonds = preload("res://scripts/combat_bonds.gd")
const EFFECTS = ["relay_attack","reload", "breach", "blast", "stabilize", "shadow", "hold_line", "mass_heal", "wave", "handoff", "backup", "surge", "momentum_rally", "taunt", "bond_aid", "bond_strike"]

static func reason(m: RefCounted, u: Dictionary, id: String, def: Dictionary) -> String:
	if id in ["shoot", "overwatch", "holdLine"] or int(def.get("ammo_cost", 0)) > 0:
		if bool(u.get("disarmed", false)): return "Disarmed"
		if int(u.get("ammo", 99)) < int(def.get("ammo_cost", 1)): return "Reload first"
	if id == "reload" and (not u.has("ammo") or int(u.ammo) >= int(u.clip)): return "Ammo full"
	if str(def.get("effect")) == "interact" and interactables(m, u).is_empty(): return "Move adjacent to an objective"
	if bool(def.get("once_turn", false)) and int(u.get(id + "_turn", 0)) == m.turn: return "Used this turn"
	if bool(def.get("squad_once", false)) and m.get("squad_uses") != null and int(m.squad_uses.get(id, 0)) == m.turn: return "Squad used this turn"
	if int(def.get("momentum", 0)) > 0 and (m.get("momentum") == null or m.momentum < int(def.momentum)): return "Need %d Momentum" % int(def.momentum)
	if id == "bondAid":
		for p in Bonds.partners(m, u):
			if not bool(m.bond_pairs[u.bondmates[int(p.id)]].get("aid_used", false)) and int(p.ap) < 2: return ""
		return "No ready bondmate"
	if id == "bondStrike" and Bonds.partners(m, u).is_empty(): return "Bondmate unavailable"
	return ""

static func interactables(m: RefCounted, u: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not m.has_method("interactables") or not m.has_method("interact"): return out
	for p in m.interactables():
		if p is Vector2i and maxi(absi(p.x - int(u.x)), absi(p.y - int(u.y))) == 1: out.append(p)
	return out

static func interact(m: RefCounted, u: Dictionary, tile: Vector2i) -> bool:
	if tile not in interactables(m, u): return false
	var response: Dictionary = m.interact(u, tile)
	if not bool(response.get("ok", response.get("success", false))): return false
	# The mission owns objective mutation and the single AP charge.
	return true

static func effect(m: RefCounted, u: Dictionary, t: Dictionary, tile: Vector2i, id: String, def: Dictionary) -> void:
	u[id + "_turn"] = m.turn
	if m.get("squad_uses") != null and bool(def.get("squad_once", false)): m.squad_uses[id] = m.turn
	if int(def.get("momentum", 0)) > 0: m.momentum -= int(def.momentum)
	match str(def.effect):
		"relay_attack":
			m.damage_objective(m.rng.randi_range(int(u.damage[0]),int(u.damage[1])))
		"reload": u.ammo = int(u.clip)
		"breach": m.damage_cover(tile, int(def.get("cover_damage", 8)))
		"stabilize": t.stable = true; _save(m, u, t)
		"shadow":
			u.x = tile.x; u.y = tile.y; u.leap_aim = int(def.next_strike_aim); u.concealed = true
			if m.has_method("_enemy_reaction_fire"):
				m._wake_groups()
				for e in m.living("enemy"):
					if Shot.distance(Shot.pos(e), tile) <= 2 and Shot.los(m, Shot.pos(e), tile): u.concealed = false
		"hold_line": u.overwatch = true; u.hold_line = true; u.ow_hit = []
		"mass_heal":
			for ally in m.units:
				if str(ally.side) != "player" or Shot.distance(Shot.pos(u), Shot.pos(ally)) > float(def.range): continue
				if str(ally.get("status", "")) == "down": ally.stable = true; _save(m, u, ally)
				elif int(ally.hp) > 0: ally.hp = mini(int(ally.max_hp), int(ally.hp) + int(def.heal))
		"wave":
			for enemy in m.living("enemy"):
				if Shot.distance(Shot.pos(u), Shot.pos(enemy)) > float(def.range) or not Shot.los(m, Shot.pos(u), Shot.pos(enemy)): continue
				if def.has("damage"): m.apply_damage(enemy, int(def.damage[0]), u)
				if int(enemy.hp) > 0 and m.rng.randi_range(1, 100) <= int(def.chance): enemy.stunned = true; enemy.stunned_until = m.turn + 1; enemy.overwatch = false
		"blast": _blast(m, u, tile, def)
		"handoff": t.ap = mini(2, int(t.ap) + 1)
		"surge": u.ap = mini(2, int(u.ap) + 1)
		"momentum_rally":
			for ally in m.living("player"): ally.buff_aim = int(ally.get("buff_aim", 0)) + 10; ally.buff_until = m.turn + 1
		"taunt": u.taunt = true; u.taunt_until = m.turn + 1
		"bond_aid": Bonds.assist(m, u, t)
		"bond_strike": Bonds.strike(m, u, t)
		"backup":
			var helper := best_helper(m, u, t)
			if not helper.is_empty():
				var info := Shot.calculate(m, helper, t, false, -10)
				var old: Array = helper.damage
				helper.damage = [maxi(1, int(old[0])-1), maxi(1, int(old[1])-1)]
				m._apply_attack(helper, t, info, "shoot")
				helper.damage = old

static func best_helper(m: RefCounted, u: Dictionary, t: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var score := -1
	for ally in m.living("player"):
		if bool(ally.get("disarmed",false)) or int(ally.id) == int(u.id) or "shoot" not in ally.get("kit", []) or int(ally.get("ammo", 1)) <= 0: continue
		var info := Shot.calculate(m, ally, t)
		if bool(info.los) and bool(info.range_ok) and int(info.hit) > score: best = ally; score = int(info.hit)
	return best

static func _blast(m: RefCounted, u: Dictionary, tile: Vector2i, def: Dictionary) -> void:
	for target in m.units:
		if int(target.hp) <= 0 or maxi(absi(int(target.x)-tile.x), absi(int(target.y)-tile.y)) > 1: continue
		if not bool(def.get("friendly_fire", false)) and str(target.side) == str(u.side): continue
		var damage: int = int(def.get("droid_damage", def.damage[0])) if bool(target.get("droid", false)) else m.rng.randi_range(int(def.damage[0]), int(def.damage[1]))
		target.armor = maxi(0,int(target.get("armor",0))-int(target.get("counter",{}).get("explosive_shred",0)))
		m.apply_damage(target, maxi(1, damage - int(target.get("armor", 0))), u)
		if bool(target.get("droid", false)) and def.has("status"): target.stunned = true; target.stunned_until = m.turn + 1
		if bool(def.get("clear_overwatch", false)) or bool(target.get("stunned", false)): target.overwatch = false
		if int(def.get("cover_damage", 0)) > 0: target.armor = maxi(0, int(target.get("armor", 0))-1)
	for y in range(tile.y - 1, tile.y + 2):
		for x in range(tile.x - 1, tile.x + 2): m.damage_cover(Vector2i(x, y), int(def.get("cover_damage", 0)))

static func _save(m: RefCounted, u: Dictionary, t: Dictionary) -> void:
	if u.has("rid") and t.has("rid"): m.saved_by[str(t.rid)] = str(u.rid)
