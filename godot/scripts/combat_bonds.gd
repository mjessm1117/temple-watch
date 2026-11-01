extends RefCounted
const Shot = preload("res://scripts/shot.gd")

static func setup(m: RefCounted, state: Dictionary) -> void:
	m.bond_pairs = state.get("bonds", {}).duplicate(true)
	for u in m.living("player"):
		u.bondmates = {}
		for partner in m.living("player"):
			if u == partner or not u.has("rid") or not partner.has("rid"): continue
			var ids: Array = [str(u.rid), str(partner.rid)]; ids.sort()
			var key := "|".join(ids)
			var bond: Dictionary = m.bond_pairs.get(key, {})
			if int(bond.get("lvl", 0)) < 1: continue
			u.bondmates[int(partner.id)] = key
			for skill in ["bondAid", "bondStrike"]:
				if skill == "bondStrike" and int(bond.lvl) < 4: continue
				if skill not in u.kit: u.kit.append(skill)

static func partners(m: RefCounted, u: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in u.get("bondmates", {}):
		var t: Dictionary = m.unit_by_id(int(id))
		if int(t.get("hp", 0)) > 0 and Shot.distance(Shot.pos(u), Shot.pos(t)) <= 8: out.append(t)
	return out

static func assist(m: RefCounted, u: Dictionary, t: Dictionary) -> void:
	var key: String = u.bondmates[int(t.id)]
	m.bond_pairs[key].aid_used = true
	t.ap = mini(3, int(t.ap) + 1)
	for status in ["stunned", "disarmed", "rooted", "suppressed", "suppressed_by"]: t.erase(status)
	if int(t.get("debuff_aim", 0)) == -30: t.erase("debuff_aim")
	m.message("%s steadies %s: +1 AP, conditions cleared." % [u.name, t.name])

static func strike(m: RefCounted, u: Dictionary, enemy: Dictionary) -> void:
	for ally in partners(m, u):
		var key: String = u.bondmates[int(ally.id)]
		var pair: Dictionary = m.bond_pairs[key]
		if int(pair.lvl) < 4 or bool(pair.get("strike_used", false)): continue
		var info := Shot.calculate(m, ally, enemy)
		if not bool(info.los) or not bool(info.range_ok) or int(ally.get("ammo", 1)) <= 0: continue
		pair.strike_used = true
		m._apply_attack(ally, enemy, info, "shoot")
		return
