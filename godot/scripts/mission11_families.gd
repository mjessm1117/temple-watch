extends RefCounted
## Ruusan objectives share the existing interact and turn contract.
const Shot = preload("res://scripts/shot.gd")
const Maps = preload("res://scripts/map_catalog.gd")

static func applies(m: RefCounted) -> bool:
	return str(m.spec.family) in ["holocron_recovery", "evacuation", "sith_lord_duel"]

static func setup(m: RefCounted) -> void:
	var s: Dictionary = m.objective_state
	match str(m.spec.family):
		"holocron_recovery":
			m.spec.turn_limit = int(Maps.read("res://data/campaign/missions.json").MISSIONS.r_caves.turn_limit)
			s.item_at = Maps.point(m.spec.objective.points[0]); s.carrier_id = -1
			m.message("Recover the holocron. Its carrier moves two tiles slower; reach extraction before the Brotherhood converges.")
		"evacuation":
			s.civilians = []; s.civilian_ids = []; s.saved = 0; s.lost = 0
			for at in m.spec.objective.civilians:
				m._spawn("civilian11",int(at[0]),int(at[1]),-1)
				s.civilian_ids.append(int(m.units[-1].id))
			m.message("Escort the wounded to the blue exit. Reinforcements arrive every two turns; save at least %d." % int(m.spec.objective.save))
		"sith_lord_duel":
			for enemy in m.living("enemy"):
				if bool(enemy.get("duel_boss",false)): s.boss_id = int(enemy.id); break
			s.boss_phase = 1
			m.message("Defeat the Sith Lord. At half health, expect a new attack and fresh guards.")

static func targets(m: RefCounted) -> Array[Vector2i]:
	if m.spec.family == "holocron_recovery" and int(m.objective_state.get("carrier_id",-1)) < 0: return [m.objective_state.item_at]
	if m.spec.family == "evacuation" and m.objective_state.phase == "primary":
		var out: Array[Vector2i] = []
		for id in m.objective_state.civilian_ids:
			var c: Dictionary = m.unit_by_id(int(id))
			if int(c.get("hp",0)) > 0 and not bool(c.get("escorted",false)): out.append(Shot.pos(c))
		return out
	return []

static func interact(m: RefCounted, u: Dictionary, p: Vector2i) -> bool:
	if m.spec.family == "evacuation":
		for id in m.objective_state.civilian_ids:
			var c: Dictionary = m.unit_by_id(int(id))
			if int(c.get("hp",0)) > 0 and not bool(c.get("escorted",false)) and Shot.pos(c) == p:
				c.escorted = true; m.message("%s joins the evacuation column." % c.name)
				var tagged := 0
				for other_id in m.objective_state.civilian_ids:
					if bool(m.unit_by_id(int(other_id)).get("escorted",false)): tagged += 1
				if targets(m).is_empty(): m.objective_state.phase = "evac"
				return true
		return false
	if m.spec.family != "holocron_recovery" or p != m.objective_state.get("item_at",Vector2i(-1,-1)): return false
	m.objective_state.carrier_id = int(u.id)
	u.holocron_base_mob = int(u.mob); u.carrying_holocron = true; u.mob = maxi(2,int(u.mob)-2)
	m.objective_state.phase = "evac"; m.metrics.objective_turn = m.turn
	m.message("%s carries the holocron. Brotherhood hunters are converging!" % u.name)
	for enemy in m.living("enemy"): enemy.awake = true; enemy.spotted = true
	m.queue_reinforcement(["assassin11","trooper"],1,"Holocron pursuit")
	return true

static func check(m: RefCounted) -> void:
	var s: Dictionary = m.objective_state
	match str(m.spec.family):
		"holocron_recovery":
			var carrier: Dictionary = m.unit_by_id(int(s.carrier_id))
			if not carrier.is_empty() and int(carrier.hp) <= 0:
				carrier.mob = int(carrier.get("holocron_base_mob",carrier.mob)); carrier.carrying_holocron = false
				s.item_at = Shot.pos(carrier); s.carrier_id = -1; s.phase = "primary"
				m.message("Holocron dropped. Another soldier must recover it.")
			if not carrier.is_empty() and int(carrier.hp) > 0 and m.objective_state.phase == "evac" and preload("res://scripts/mission_objectives.gd").at_evac(m,Shot.pos(carrier)):
				win(m,"The holocron is aboard the shuttle.")
		"evacuation":
			if s.phase == "primary" and targets(m).is_empty(): s.phase = "evac"
			if int(s.saved) >= int(m.spec.objective.save): win(m,"%d civilians survive the evacuation." % int(s.saved))
			elif s.civilian_ids.size()-int(s.lost) < int(m.spec.objective.save): lose(m,"Too many civilians were lost.")
		"sith_lord_duel":
			var boss: Dictionary = m.unit_by_id(int(s.get("boss_id",-1)))
			if not boss.is_empty() and int(boss.hp) <= 0: win(m,"The Sith Lord falls. The Brotherhood line breaks.")

static func damage(m: RefCounted, target: Dictionary) -> void:
	preload("res://scripts/villain11_battle.gd").on_damage(m, target)
	if m.spec.family != "sith_lord_duel" or not bool(target.get("duel_boss",false)): return
	if int(target.hp) > 0 and int(target.hp)*2 <= int(target.max_hp) and int(m.objective_state.boss_phase) == 1:
		m.objective_state.boss_phase = 2; target.duel_phase = 2
		target.damage = [int(target.damage[0])+1,int(target.damage[1])+1]
		m.message("PHASE TWO: the Sith Lord unleashes lightning and calls guards!")
		m.queue_reinforcement(["assassin11","trooper"],1,"The Lord's guard")
	check(m)

static func enemy_end(m: RefCounted) -> void:
	if m.spec.family != "evacuation" or m.result != "": return
	var s: Dictionary = m.objective_state
	for id in s.civilian_ids:
		var c: Dictionary = m.unit_by_id(int(id))
		if c.is_empty() or int(c.hp) <= 0 or bool(c.get("evacuated",false)): continue
		var exposed := false
		for enemy in m.living("enemy"):
			if bool(enemy.awake) and Shot.distance(Shot.pos(enemy),Shot.pos(c)) <= 3.5 and Shot.los(m,Shot.pos(enemy),Shot.pos(c)): exposed = true; break
		if exposed:
			c.hp = maxi(0,int(c.hp)-2)
			if int(c.hp) == 0: s.lost += 1; m.message("A civilian falls under Brotherhood fire."); continue
		if not bool(c.get("escorted",false)): continue
		var reach: Dictionary = m.paths(c,3); var next := Shot.pos(c)
		var best_distance := exit_distance(m,next)
		for p in reach.costs:
			var distance := exit_distance(m,p)
			if distance < best_distance: best_distance = distance; next = p
		if next != Shot.pos(c): c.x = next.x; c.y = next.y
		var boarding := preload("res://scripts/mission_objectives.gd").at_evac(m,Shot.pos(c))
		if not boarding:
			for at in m.spec.evac:
				var tile := Maps.point(at)
				if Shot.distance(Shot.pos(c),tile) <= 1.5 and m.living("player").any(func(u): return Shot.pos(u) == tile): boarding = true; break
		if boarding:
			c.evacuated = true; s.saved += 1; m.message("Civilian aboard: %d/%d." % [int(s.saved),int(m.spec.objective.save)])
	check(m)

static func exit_distance(m: RefCounted, p: Vector2i) -> float:
	var best := INF
	for at in m.spec.evac: best = minf(best,Shot.distance(p,Maps.point(at)))
	return best

static func player_start(m: RefCounted) -> void:
	if m.spec.family == "evacuation" and m.result == "" and m.turn % 2 == 0:
		m.queue_reinforcement(["trooper","assassin11"] if m.turn >= 4 else ["trooper"],1,"Brotherhood sweep")

static func status(m: RefCounted) -> String:
	match str(m.spec.family):
		"holocron_recovery": return "Carry the holocron to extraction" if int(m.objective_state.carrier_id) >= 0 else "Recover the holocron"
		"evacuation": return "Evacuated %d/%d · %d lost" % [int(m.objective_state.saved),int(m.spec.objective.save),int(m.objective_state.lost)]
		"sith_lord_duel":
			var boss: Dictionary = m.unit_by_id(int(m.objective_state.get("boss_id",-1)))
			return "Defeat the Sith Lord · Phase %d · %d HP" % [int(m.objective_state.boss_phase),int(boss.get("hp",0))]
	return ""

static func win(m: RefCounted, why: String) -> void:
	if m.result != "": return
	m.result = "win"; m.metrics.evac_turn = m.turn; m.message(why)

static func lose(m: RefCounted, why: String) -> void:
	if m.result != "": return
	m.result = "loss"; m.message(why)
