extends RefCounted

static func facing_tile(m: RefCounted, attacker: Vector2i, target: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var value := 0
	for q in [target + Vector2i(signi(attacker.x - target.x), 0), target + Vector2i(0, signi(attacker.y - target.y))]:
		if q == target or not m.in_bounds(q): continue
		var c: String = m.tile(q)
		var score := 40 if c == "#" else 20 if c in ["c", "h", "k"] else 0
		if score > value: value = score; best = q
	return best

static func preview(m: RefCounted, attacker: Dictionary, target: Vector2i) -> Dictionary:
	var p := facing_tile(m, Vector2i(int(attacker.x),int(attacker.y)), target)
	if p.x < 0: return {}
	var before: int = int(m.cover_hp.get(p, 8 if m.tile(p) == "#" else 4))
	var heavy := str(attacker.get("class_name","")) == "Heavy"
	var active := bool(m.modern)
	var hit_chip := 3 if heavy and (active or not bool(m.modern)) else 1 if active else 0
	var miss_chip := 3 if heavy and active else 1 if active else 0
	return {"at":p, "tile":m.tile(p), "hp":before, "on_hit":_after(m.tile(p), before, hit_chip), "on_miss":_after(m.tile(p), before, miss_chip)}

static func _after(tile: String, hp: int, chip: int) -> String:
	if hp - chip <= 0: return "r"
	if tile == "#" and hp - chip <= 4: return "c"
	return tile

static func shot_chip(m: RefCounted, a: Dictionary, t: Dictionary, mode: String, outcome: String) -> void:
	if mode == "strike": return
	if not bool(m.modern):
		if mode == "shoot" and str(a.get("class_name","")) == "Heavy" and outcome in ["hits","crits","grazes"]:
			var direction := Vector2i(signi(int(a.x)-int(t.x)),signi(int(a.y)-int(t.y)))
			for q in [Vector2i(int(t.x)+direction.x,int(t.y)),Vector2i(int(t.x),int(t.y)+direction.y)]:
				m.damage_cover(q,3,{"kind":"heavy_shot","actor":int(a.id)})
		return
	var p := facing_tile(m, Vector2i(int(a.x),int(a.y)), Vector2i(int(t.x),int(t.y)))
	if p.x < 0: return
	var chip := 3 if str(a.get("class_name", "")) == "Heavy" else 1
	m.damage_cover(p, chip, {"kind":"shot_miss" if outcome == "misses" else "sustained_fire", "actor":int(a.id)})

static func damage(m: RefCounted, p: Vector2i, amount: int, cause: Dictionary) -> String:
	if bool(m.modern) and str(cause.get("kind","")) in ["grenade","ionNade","explosion","barrel"]: amount = maxi(8,amount)
	if not m._destructible(p) or amount <= 0: return m.tile(p)
	var before: String = m.tile(p)
	var old_hp: int = int(m.cover_hp.get(p, 8 if before == "#" else 4))
	var hp: int = old_hp - amount
	if hp <= 0:
		m.set_tile(p, "r")
		m.message("Cover collapses into rubble.")
	elif before == "#" and hp <= 4:
		m.set_tile(p, "c")
		m.cover_hp[p] = hp
		m.message("Full cover cracks into half cover.")
	else: m.cover_hp[p] = hp
	if m.tile(p) != before: m.terrain_revision += 1
	m.action_events.append({"kind":"cover_damage", "at":p, "from_tile":before, "to_tile":m.tile(p), "hp_before":old_hp, "hp_after":maxi(0,hp), "cause":cause.get("kind","environment"), "actor":int(cause.get("actor",-1))})
	if m.tile(p) != before:
		m.action_events.append({"kind":"cover_break", "at":p, "from_tile":before, "to_tile":m.tile(p), "cause":cause.get("kind","environment"), "actor":int(cause.get("actor",-1))})
	return m.tile(p)
