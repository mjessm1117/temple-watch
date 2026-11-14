extends RefCounted
class_name RescueAI

const Shot = preload("res://scripts/shot.gd")
const Plan29 = preload("res://scripts/w29c_ai_plan.gd")

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
		if bool(m.modern) and Shot.in_cover(m, q) and cv == 0 and d <= float(p.range): danger += 16.0
		if bool(p.overwatch) and d <= float(p.range): danger += max(0.0, 24.0 - float(cv) * 0.35)
		if not melee and d <= float(e.range) and Shot.los(m, q, pp):
			var probe := e.duplicate()
			probe.x = q.x; probe.y = q.y
			var info: Dictionary = Shot.calculate(m, probe, p)
			attack_score = max(attack_score, float(info.hit) * 0.27 + (22.0 if bool(info.flanked) and bool(m.modern) else 11.0 if bool(info.flanked) else 0.0))
	var distance_score: float = -abs(nearest - ideal) * (6.5 if melee else 2.0)
	if melee and jedi_nearest < 999.0: distance_score = -jedi_nearest * 7.5
	if retreat: distance_score = nearest * 4.0
	var height := float(Shot.elevation(m, q)) * (3.0 if melee else 11.0 if bool(m.modern) else 8.0)
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
		m.action_events.append({"kind": "activation", "actor": int(e.id), "at": old, "reason24":"Seeking cover", "reason27":"Seeking cover"})
		var route: Array[Vector2i] = []
		var cursor := best
		while cursor != old and reach.prev.has(cursor): route.push_front(cursor); cursor = reach.prev[cursor]
		m.action_events.append({"kind": "move", "actor": int(e.id), "from": old, "to": best, "path": route, "reason24":"Seeking cover", "reason27":"Seeking cover"})
		m.message("%s scrambles for cover." % e.name)
		m._reaction_fire(e)

static func _reason24(m: RefCounted, first: int, actor: Dictionary, reason: String) -> void:
	for i in range(first, m.action_events.size()):
		if int(m.action_events[i].get("actor", -1)) != int(actor.id): continue
		m.action_events[i].reason24 = reason
		m.action_events[i].reason27 = reason
		if m.has_method("intent_explain27"):
			if reason == "Flank setup": m.action_events[i].reason27 = "Flanking the gate line" if str(m.spec.get("id", "")) == "relay" else "Flanking the squad"
			elif reason == "Holding cover": m.action_events[i].reason27 = "Holding cover and firing"
			elif reason in ["Flank route", "Taking high ground", "Escaping flank"]: m.action_events[i].reason27 = reason
			else: m.action_events[i].reason27 = m.intent_explain27(m.action_events[i])

static func _shot24(m: RefCounted, e: Dictionary, target: Dictionary, mode: String, info: Dictionary = {}) -> bool:
	var first: int = m.action_events.size()
	var ok: bool = m.shot(int(e.id), int(target.id), mode)
	if ok:
		var reason := "Flanking" if bool(info.get("flanked", false)) else "Holding cover" if Shot.cover(m, Shot.pos(e), Shot.pos(target)) > 0 else "Threat in sight"
		_reason24(m, first, e, reason)
	return ok

static func _move24(m: RefCounted, e: Dictionary, destination: Vector2i, reason: String) -> bool:
	var first: int = m.action_events.size()
	var ok: bool = m.move(int(e.id), destination)
	if ok:
		for target in m.living("player"):
			var info: Dictionary = Shot.calculate(m, e, target)
			if not bool(info.los) or not bool(info.range_ok) or not bool(info.flanked): continue
			for i in range(first, m.action_events.size()):
				if int(m.action_events[i].get("actor", -1)) == int(e.id) and str(m.action_events[i].get("kind", "")) == "move":
					m.action_events[i].target = int(target.id)
					m.action_events[i].flanked = true
			break
		_reason24(m, first, e, reason)
	return ok

static func _position_reason(m: RefCounted, e: Dictionary, destination: Vector2i) -> String:
	var probe := e.duplicate()
	probe.x = destination.x; probe.y = destination.y
	for target in m.living("player"):
		var info: Dictionary = Shot.calculate(m, probe, target)
		if bool(info.los) and bool(info.range_ok) and bool(info.flanked): return "Flank route"
	if Shot.elevation(m, destination) > Shot.elevation(m, Shot.pos(e)): return "Taking high ground"
	for target in m.living("player"):
		if Shot.in_cover(m, Shot.pos(e)) and Shot.cover(m, Shot.pos(e), Shot.pos(target)) == 0 and Shot.cover(m, destination, Shot.pos(target)) > 0: return "Escaping flank"
	return "Better position"

static func _flank_route(m: RefCounted, e: Dictionary, target: Dictionary) -> Vector2i:
	var origin := Shot.pos(e)
	var best := origin
	var score := -9999.0
	for q in m.paths(e, int(e.mob)).costs:
		if q == origin: continue
		var probe := e.duplicate()
		probe.x = q.x; probe.y = q.y
		var info: Dictionary = Shot.calculate(m, probe, target)
		if not bool(info.los) or not bool(info.range_ok) or not bool(info.flanked): continue
		var value := destination_score(m, e, q)
		if value > score: score = value; best = q
	return best

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
				var first: int = m.action_events.size()
				m._apply_attack(e, foe, trick_shot, "strike" if is_melee(e) else "shoot")
				_reason24(m, first, e, "Mind Trick compulsion")
				m.message("%s attacks an ally under Mind Trick." % e.name)
				return
		return
	if bool(e.get("skip_turn", false)):
		e.skip_turn = false
		return
	if not is_melee(e) and int(e.get("ammo", 1)) == 0:
		e.ammo = int(e.get("clip", 4)); e.ap = maxi(0, int(e.ap) - 1)
		m.action_events.append({"kind":"reload", "actor":int(e.id), "reason24":"Empty magazine", "reason27":"Reloading an empty magazine"})
	var retreat := int(e.hp) * 3 <= int(e.max_hp)
	if retreat:
		var safe := choose_destination(m, e, int(e.mob), true)
		if safe != Shot.pos(e): _move24(m, e, safe, "Low health")
	if str(e.class_name) == "Sith Warrior" and int(e.get("focus_left", 0)) >= 2 and not bool(e.get("pushed", false)):
		for p in visible(m, e):
			if Shot.distance(Shot.pos(e), Shot.pos(p)) > 1.5 and Shot.distance(Shot.pos(e), Shot.pos(p)) <= 4.0 and Shot.in_cover(m, Shot.pos(p)):
				var first: int = m.action_events.size()
				if m.push(int(e.id), int(p.id)):
					_reason24(m, first, e, "Target in cover")
					e.pushed = true
					return
	var setup29: Dictionary = Plan29.setup(m,e)
	if not setup29.is_empty():
		if setup29.role == "overwatch":
			e.ap = 0; e.overwatch = true; e.setup29_done = true
			var event := {"kind":"overwatch", "actor":int(e.id), "at":Shot.pos(e), "target":int(setup29.target), "reason24":"Covering flank setup", "reason27":"Covering flank setup"}
			if m.has_method("intent_explain27"): event.reason27 = m.intent_explain27(event)
			m.action_events.append(event)
			m.message("%s holds the lane on Overwatch." % e.name)
			return
		if _move24(m,e,setup29.destination,"Flank setup"):
			e.setup29_done = true
			return
	if bool(m.modern) and not is_melee(e) and int(e.ap) > 0 and visible(m, e).is_empty() and m._neighbors(Shot.pos(e), int(e.id)).size() <= 2:
		e.ap = 0; e.overwatch = true
		m.action_events.append({"kind":"overwatch", "actor":int(e.id), "at":Shot.pos(e), "reason24":"Chokepoint lane", "reason27":"Holding a chokepoint on Overwatch"})
		return
	var target := choose_target(m, e, fired)
	if not target.is_empty() and not bool(e.get("disarmed", false)):
		var mode := "strike" if is_melee(e) else "shoot"
		var info: Dictionary = Shot.calculate(m, e, target, is_melee(e))
		if bool(m.modern) and not is_melee(e) and int(e.ap) >= 2 and int(info.cover) > 0:
			var flank := _flank_route(m, e, target)
			if flank != Shot.pos(e) and _move24(m, e, flank, "Flank route"):
				info = Shot.calculate(m, e, target)
				if _shot24(m, e, target, mode, info):
					fired[int(target.id)] = int(fired.get(int(target.id), 0)) + 1
				return
		if (is_melee(e) or int(info.hit) >= 55) and _shot24(m, e, target, mode, info):
			fired[int(target.id)] = int(fired.get(int(target.id), 0)) + 1
			return
	if int(e.ap) >= 1:
		var dest := choose_destination(m, e, int(e.mob))
		if int(e.ap) >= 2 and not can_attack_from(m, e, dest):
			var dash := choose_destination(m, e, int(e.mob) * 2)
			if dash != Shot.pos(e) and destination_score(m, e, dash) > destination_score(m, e, dest) + 0.01:
				_move24(m, e, dash, _position_reason(m, e, dash))
				return
		if dest != Shot.pos(e): _move24(m, e, dest, _position_reason(m, e, dest))
	if int(e.hp) <= 0: return
	if int(e.ap) >= 1 and not bool(e.get("disarmed", false)):
		target = choose_target(m, e, fired)
		if not target.is_empty():
			var mode := "strike" if is_melee(e) else "shoot"
			var later_info: Dictionary = Shot.calculate(m, e, target, is_melee(e))
			if _shot24(m, e, target, mode, later_info):
				fired[int(target.id)] = int(fired.get(int(target.id), 0)) + 1
				return
	if not is_melee(e) and int(e.ap) > 0:
		e.ap = 0; e.overwatch = true
		var reason := "High ground firing lane" if Shot.elevation(m, Shot.pos(e)) > 0 else "Chokepoint lane" if m._neighbors(Shot.pos(e), int(e.id)).size() <= 2 else "No clear shot"
		var event := {"kind": "overwatch", "actor": int(e.id), "at": Shot.pos(e), "reason24":reason, "reason27":reason}
		if m.has_method("intent_explain27"): event.reason27 = m.intent_explain27(event)
		m.action_events.append(event)
		m.message("%s watches a firing lane." % e.name)
