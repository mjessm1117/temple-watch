extends RefCounted

static func map_id(pending: Dictionary) -> String:
	var template := str(pending.get("mission_id",pending.get("mission","")))
	if not pending.has("sith_offer_id"): return template
	return str({"retaliation":"r_hospital", "stronghold":"dock", "pursuit":"adraasHunt", "ambush":"adraasHunt", "kidnap":"escort", "rescue_rival":"rescue", "project":"sabotage"}.get(str(pending.kind),template))

static func setup(c, m) -> void:
	var pending: Dictionary = c.state.pending_mission
	var mods: Dictionary = c.sith.campaign_mods()
	m.spec.sith_mods = mods
	for u in m.living("player"): u.aim += int(mods.squadAim)
	for u in m.living("enemy"):
		u.aim += int(mods.enemyAim); u.hp += int(mods.enemyHp); u.max_hp = u.hp
	var rival: Dictionary = c.sith.rival_for_mission(str(pending.get("sith_offer_id","")))
	if rival.is_empty(): return
	var anchor: Vector2i = preload("res://scripts/map_catalog.gd").point(m.spec.objective.points[0])
	m._spawn_near("acolyte",anchor,80)
	var u: Dictionary = m.units[-1]
	u.rival = rival.id; u.name = rival.n; u.hp = rival.hp; u.max_hp = u.hp; u.aim = rival.aim; u.armor = rival.armor
	u.strengths = rival.strengths; u.weaknesses = rival.weaknesses; u.counter = {}; u.no_capture = true
	for counter in rival.countermeasures: u.counter.merge(counter.mod,true)
	u.armor = maxi(0,int(u.armor)+int(u.counter.get("armor",0)))
	if u.rival == "veyra": u.defense = 10
	if u.rival == "korr": u.mob = 4
	if u.rival == "nyss": u.range = 7
	u.awake = true; u.spotted = true
	m.spec.rival_required = int(u.id)
	if pending.kind == "pursuit":
		var runner: Dictionary = m.unit_by_id(int(m.objective_state.runner_id))
		if not runner.is_empty(): m.units.erase(runner)
		m.spec.family = "pursuit"; m.spec.turn_limit = 0
	if pending.kind == "kidnap": m.prisoner.name = "Abduction target"
	m.message("%s · %s. Weaknesses: %s" % [u.name,", ".join(u.strengths),", ".join(u.weaknesses)])

static func aim(attacker: Dictionary, target: Dictionary, melee: bool) -> int:
	var value := int(target.get("counter",{}).get("attacker_aim",0))
	if target.get("rival","") == "veyra" and bool(target.get("marked",false)):
		value -= int(target.get("counter",{}).get("marked_evasion",-10))
	if bool(attacker.get("suppressed",false)): value += int(attacker.get("counter",{}).get("suppressed_aim",0))
	if melee and target.get("rival","") == "nyss": value += 15
	return value

static func before_actor(m, u: Dictionary) -> void:
	if not u.has("rival") or bool(u.get("stunned",false)): return
	if u.rival == "korr" and not (bool(u.get("disarmed",false)) and bool(u.counter.get("disorient_cancels_rally",false))):
		for ally in m.living("enemy"):
			if m.Shot.distance(m.Shot.pos(u),m.Shot.pos(ally)) <= 5:
				ally.buff_aim = 10; ally.buff_until = m.turn+1
	elif u.rival == "nyss" and int(u.get("siphon_stopped",0)) < m.turn:
		for target in m.living("player"):
			if m.Shot.distance(m.Shot.pos(u),m.Shot.pos(target)) > 6 or not m.Shot.los(m,m.Shot.pos(u),m.Shot.pos(target)): continue
			var will := int(target.get("will",0)) + (int(u.counter.get("guarded_will",0)) if bool(target.get("guard",false)) else 0)
			if m.rng.randi_range(1,100) > will:
				target.rooted = true; target.rooted_until = m.turn+2
				var amount: int = m.apply_damage(target,2,u)
				u.hp = mini(int(u.max_hp),int(u.hp)+amount)
				m.message("%s snares %s and siphons %d life." % [u.name,target.name,amount])
			break
