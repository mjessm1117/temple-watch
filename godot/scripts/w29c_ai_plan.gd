extends RefCounted
const Shot = preload("res://scripts/shot.gd")

static func setup(m: RefCounted, e: Dictionary) -> Dictionary:
	if not bool(m.modern) or str(m.spec.get("family","")) == "sith_lord_duel": return {}
	if float(e.range) < 2.0 or int(e.ap) < 2 or bool(e.get("setup29_done",false)): return {}
	var team: Array[Dictionary] = []
	for ally in m.living("enemy"):
		if int(ally.group) == int(e.group) and bool(ally.awake) and float(ally.range) >= 2.0 and int(ally.hp) > 0: team.append(ally)
	if team.size() < 2: return {}
	team.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.id) < int(b.id))
	if e.id != team[0].id and e.id != team[1].id: return {}
	var target: Dictionary = {}
	for p in m.living("player"):
		if bool(p.get("concealed",false)): continue
		if Shot.distance(Shot.pos(e),Shot.pos(p)) > float(e.range) + float(e.mob): continue
		if Shot.cover(m, Shot.pos(p), Shot.pos(e)) > 0:
			target = p
			break
	if target.is_empty(): return {}
	if e.id == team[0].id:
		if not Shot.los(m,Shot.pos(e),Shot.pos(target)): return {}
		return {"role":"overwatch", "target":int(target.id)}
	var destination := flank_destination(m,e,target)
	if destination == Shot.pos(e): return {}
	return {"role":"flank", "target":int(target.id), "destination":destination}

static func flank_destination(m: RefCounted, e: Dictionary, target: Dictionary) -> Vector2i:
	var origin := Shot.pos(e)
	var reach: Dictionary = m.paths(e,int(e.mob))
	var best := origin
	var best_score := -9999.0
	for q in reach.costs:
		if q == origin: continue
		var probe := e.duplicate(); probe.x = q.x; probe.y = q.y
		var info: Dictionary = Shot.calculate(m,probe,target)
		var score := float(info.hit) * 0.35 + (28.0 if bool(info.flanked) else 0.0)
		score += float(Shot.cover(m,q,Shot.pos(target))) * 0.3
		score -= Shot.distance(q,Shot.pos(target)) * 1.2
		if not bool(info.los) or not bool(info.range_ok): score -= 15.0
		if score > best_score: best_score = score; best = q
	return best
