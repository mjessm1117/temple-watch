extends RefCounted
class_name RescueAI

const Shot = preload("res://scripts/shot.gd")

static func is_melee(e: Dictionary) -> bool:
	return float(e.range) < 2.0

static func visible(m: RefCounted, e: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in m.living("player"):
		if bool(p.get("concealed", false)) and Shot.distance(Shot.pos(e), Shot.pos(p)) > 2.0: continue
		if Shot.los(m, Shot.pos(e), Shot.pos(p)): out.append(p)
	return out

static func choose_target(m: RefCounted, e: Dictionary, fired: Dictionary = {}) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -9999.0
	for p in visible(m, e):
		var melee := is_melee(e)
		if melee and max(abs(int(e.x) - int(p.x)), abs(int(e.y) - int(p.y))) > 1: continue
		var info: Dictionary = Shot.calculate(m, e, p, melee)
		if not bool(info.range_ok): continue
		var score := float(info.hit)
		if bool(p.get("taunt", false)) and Shot.distance(Shot.pos(e), Shot.pos(p)) <= 8.0: score += 60.0
		if int(p.hp) <= int(e.damage[1]): score += 18.0
		if bool(info.flanked): score += 12.0
		if melee and str(p.class_name) in ["Guardian", "Consular"]: score += 30.0
		if str(p.class_name) in ["Medic", "Consular"] and int(p.get("medpacs", 0)) > 0: score += 8.0
		# A recent target is still appealing, but spread fire when alternatives are sound.
		score -= min(30.0, float(fired.get(int(p.id), 0)) * 18.0)
		if score > best_score: best_score = score; best = p
	return best

static func destination_score(m: RefCounted, e: Dictionary, q: Vector2i, retreat: bool = false) -> float:
	var squad: Array[Dictionary] = m.living("player")
	if squad.is_empty(): return -9999.0
	var melee := is_melee(e)
	var ideal := 1.0 if melee else float(e.range) * (0.78 if str(e.class_name) in ["Heavy", "Agent"] else 0.65)
	var nearest := 999.0
	var cover_score := 0.0
	var attack_score := 0.0
	var danger := 0.0
	var jedi_nearest := 999.0
	for p in squad:
		var pp: Vector2i = Shot.pos(p)
		var d := Shot.distance(q, pp)
		nearest = min(nearest, d)
		if str(p.class_name) in ["Guardian", "Consular"]: jedi_nearest = min(jedi_nearest, d)
		if not Shot.los(m, pp, q): continue
		var cv := Shot.cover(m, q, pp)
		cover_score += float(cv) * (0.24 if melee else 0.42)
		if bool(p.overwatch) and d <= float(p.range): danger += max(0.0, 24.0 - float(cv) * 0.35)
		if not melee and d <= float(e.range) and Shot.los(m, q, pp):
			var probe := e.duplicate()
			probe.x = q.x; probe.y = q.y
			var info: Dictionary = Shot.calculate(m, probe, p)
			attack_score = max(attack_score, float(info.hit) * 0.27 + (11.0 if bool(info.flanked) else 0.0))
	var distance_score: float = -abs(nearest - ideal) * (6.5 if melee else 2.0)
	if melee and jedi_nearest < 999.0: distance_score = -jedi_nearest * 7.5
	if retreat: distance_score = nearest * 4.0
	var height := float(Shot.elevation(m, q)) * (3.0 if melee else 8.0)
	var spread := 0.0
	for ally in m.living("enemy"):
		if int(ally.id) == int(e.id): continue
		var gap := Shot.distance(q, Shot.pos(ally))
		if gap < 3.0: spread -= (3.0 - gap) * 4.0
	var movement := Shot.distance(q, Shot.pos(e)) * (0.15 if melee else 0.45)
	return cover_score + attack_score + distance_score + height + spread - danger - movement

static func choose_destination(m: RefCounted, e: Dictionary, budget: int = -1, retreat: bool = false) -> Vector2i:
	if budget < 0: budget = int(e.mob)
	var reach: Dictionary = m.paths(e, budget)
	var best: Vector2i = Shot.pos(e)
	var best_score := destination_score(m, e, best, retreat)
	for q in reach.costs:
		var score := destination_score(m, e, q, retreat)
		if score > best_score + 0.01: best_score = score; best = q
	return best

static func can_attack_from(m: RefCounted, e: Dictionary, at: Vector2i) -> bool:
	var probe := e.duplicate()
	probe.x = at.x; probe.y = at.y
	for target in m.living("player"):
		if is_melee(e) and maxi(absi(at.x-int(target.x)), absi(at.y-int(target.y))) > 1: continue
		var info: Dictionary = Shot.calculate(m, probe, target, is_melee(e))
		if bool(info.los) and bool(info.range_ok): return true
	return false

static func scamper(m: RefCounted, e: Dictionary) -> void:
	if int(e.hp) <= 0: return
	if m.phase == "enemy": e.skip_turn = true
	var old: Vector2i = Shot.pos(e)
	var reach: Dictionary = m.paths(e, maxi(2, ceili(float(e.mob) * 0.6)))
	var best := old
	var best_score := -9999.0
	for q in reach.costs:
		var score := 0.0
		for p in m.living("player"):
			if Shot.los(m, Shot.pos(p), q): score += float(Shot.cover(m, q, Shot.pos(p))) - 20.0
		score -= Shot.distance(old, q) * 0.6
		if score > best_score: best_score = score; best = q
	if best != old:
		e.x = best.x; e.y = best.y
		m.action_events.append({"kind": "activation", "actor": int(e.id), "at": old})
		var route: Array[Vector2i] = []
		var cursor := best
		while cursor != old and reach.prev.has(cursor): route.push_front(cursor); cursor = reach.prev[cursor]
		m.action_events.append({"kind": "move", "actor": int(e.id), "from": old, "to": best, "path": route})
		m.message("%s scrambles for cover." % e.name)
		m._reaction_fire(e)

static func act(m: RefCounted, e: Dictionary, fired: Dictionary) -> void:
	if int(e.hp) <= 0 or not bool(e.awake): return
	if bool(e.get("stunned", false)):
		e.stunned = false
		m.message("%s is stunned and loses a turn." % e.name)
		return
	if bool(e.get("tricked", false)):
		e.tricked = false
		for foe in m.living("enemy"):
			if int(foe.id) != int(e.id) and Shot.distance(Shot.pos(e), Shot.pos(foe)) <= float(e.range):
				var trick_shot := Shot.calculate(m, e, foe, is_melee(e))
				m._apply_attack(e, foe, trick_shot, "strike" if is_melee(e) else "shoot")
				m.message("%s attacks an ally under Mind Trick." % e.name)
				return
		return
	if bool(e.get("skip_turn", false)):
		e.skip_turn = false
		return
	if not is_melee(e) and int(e.get("ammo", 1)) == 0:
		e.ammo = int(e.get("clip", 4)); e.ap = maxi(0, int(e.ap) - 1)
		m.action_events.append({"kind":"reload", "actor":int(e.id)})
	var retreat := int(e.hp) * 3 <= int(e.max_hp)
	if retreat:
		var safe := choose_destination(m, e, int(e.mob), true)
		if safe != Shot.pos(e): m.move(int(e.id), safe)
	if str(e.class_name) == "Sith Warrior" and int(e.get("focus_left", 0)) >= 2 and not bool(e.get("pushed", false)):
		for p in visible(m, e):
			if Shot.distance(Shot.pos(e), Shot.pos(p)) > 1.5 and Shot.distance(Shot.pos(e), Shot.pos(p)) <= 4.0 and Shot.in_cover(m, Shot.pos(p)):
				if m.push(int(e.id), int(p.id)):
					e.pushed = true
					return
	var target := choose_target(m, e, fired)
	if not target.is_empty() and not bool(e.get("disarmed", false)):
		var mode := "strike" if is_melee(e) else "shoot"
		var info: Dictionary = Shot.calculate(m, e, target, is_melee(e))
		if (is_melee(e) or int(info.hit) >= 55) and m.shot(int(e.id), int(target.id), mode):
			fired[int(target.id)] = int(fired.get(int(target.id), 0)) + 1
			return
	if int(e.ap) >= 1:
		var dest := choose_destination(m, e, int(e.mob))
		if int(e.ap) >= 2 and not can_attack_from(m, e, dest):
			var dash := choose_destination(m, e, int(e.mob) * 2)
			if dash != Shot.pos(e) and destination_score(m, e, dash) > destination_score(m, e, dest) + 0.01:
				m.move(int(e.id), dash)
				return
		if dest != Shot.pos(e): m.move(int(e.id), dest)
	if int(e.hp) <= 0: return
	if int(e.ap) >= 1 and not bool(e.get("disarmed", false)):
		target = choose_target(m, e, fired)
		if not target.is_empty():
			var mode := "strike" if is_melee(e) else "shoot"
			if m.shot(int(e.id), int(target.id), mode):
				fired[int(target.id)] = int(fired.get(int(target.id), 0)) + 1
				return
	if not is_melee(e) and int(e.ap) > 0:
		e.ap = 0; e.overwatch = true
		m.action_events.append({"kind": "overwatch", "actor": int(e.id), "at": Shot.pos(e)})
		m.message("%s watches a firing lane." % e.name)
