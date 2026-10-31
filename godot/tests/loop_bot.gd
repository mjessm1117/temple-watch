extends RefCounted
const Shot = preload("res://scripts/shot.gd")

static func _distance_field(m: RefCounted, goal: Vector2i) -> Dictionary:
	var field: Dictionary = {goal: 0}
	var queue: Array[Vector2i] = [goal]
	while not queue.is_empty():
		var p: Vector2i = queue.pop_front()
		for d in Shot.DIRS:
			var q: Vector2i = p + d
			if not m.passable(q) or field.has(q): continue
			field[q] = int(field[p]) + 1
			queue.append(q)
	return field

static func _bot_move_toward(m: RefCounted, u: Dictionary, goal: Vector2i) -> bool:
	var reach: Dictionary = m.paths(u, int(u.mob) * (2 if int(u.ap) >= 2 else 1))
	var field := _distance_field(m, goal)
	var best: Vector2i = Shot.pos(u)
	var best_score: float = float(field.get(best, 999))
	for q in reach.costs:
		if q == Shot.pos(u): continue
		var cost: int = int(reach.costs[q])
		if cost > int(u.mob) and int(u.ap) < 2: continue
		var score: float = float(field.get(q, 999)) + float(cost) * 0.01
		if score < best_score: best = q; best_score = score
	if best != Shot.pos(u): return m.move(int(u.id), best)
	return false

static func _bot_turn(m: RefCounted) -> void:
	var objective := Vector2i(int(m.prisoner.x), int(m.prisoner.y)) if not bool(m.prisoner.freed) else Vector2i(5, 23)
	var squad: Array[Dictionary] = m.living("player")
	for u in squad:
		if m.result != "": return
		if int(u.hp) <= 0: continue
		var cycles := 0
		while int(u.ap) > 0 and cycles < 4 and m.result == "":
			cycles += 1
			var treated := false
			for ally in m.units:
				if str(ally.side) != "player" or int(ally.id) == int(u.id): continue
				if int(ally.get("treated_turn", 0)) == m.turn: continue
				if str(ally.get("status", "ok")) == "down":
					for skill in ["forceHeal", "reviveStim", "revive", "medpac"]:
						if m.ability_reason(int(u.id), skill) == "" and m.use_ability(int(u.id), skill, int(ally.id)): treated = true; break
				elif int(ally.hp) <= int(ally.max_hp) - 3:
					for skill in ["forceHeal", "heal", "medpac"]:
						if m.ability_reason(int(u.id), skill) == "" and m.use_ability(int(u.id), skill, int(ally.id)): treated = true; break
				if treated: ally.treated_turn = m.turn; break
			if treated: continue
			if not bool(m.prisoner.freed) and max(abs(int(u.x) - int(m.prisoner.x)), abs(int(u.y) - int(m.prisoner.y))) <= 1:
				if m.free_prisoner(int(u.id)): continue
			var target: Dictionary = {}
			for e in m.living("enemy"):
				if not bool(e.awake): continue
				var info: Dictionary = Shot.calculate(m, u, e)
				if bool(info.los) and bool(info.range_ok) and int(info.hit) >= 45 and (target.is_empty() or int(e.hp) < int(target.hp)): target = e
			if not target.is_empty() and int(u.ap) >= 2 and str(u.class_name) not in ["Guardian", "Consular"]:
				m.shot(int(u.id), int(target.id)); continue
			if not target.is_empty() and str(u.class_name) in ["Guardian", "Consular"] and max(abs(int(u.x)-int(target.x)), abs(int(u.y)-int(target.y))) <= 1:
				m.shot(int(u.id), int(target.id), "strike"); continue
			if not _bot_move_toward(m, u, objective): break
	m.end_turn()
