extends RefCounted
const Shot = preload("res://scripts/shot.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Families11 = preload("res://scripts/mission11_families.gd")

static func setup(m: RefCounted) -> void:
	var f := str(m.spec.family)
	if str(m.difficulty.name) == "Normal" and int(m.spec.get("normal_turn_limit",0)) > 0: m.spec.turn_limit = int(m.spec.normal_turn_limit)
	var relay_hp := int(m.spec.objective.hp)
	if bool(m.spec.get("first_mission",false)):
		relay_hp = int(m.spec.objective.get("hard_hold_hp" if str(m.difficulty.name) == "Hard" else "normal_hold_hp",relay_hp))
	m.objective_state = {"phase":"primary","done":{},"held":0,"step":0,"clock_start":1 if m.spec.clock_trigger == "start" else 0,
		"relay_hp":relay_hp,"overrun":0,"saved":0,"lost":0,"civilians":[],"runner_id":-1,"evac_start":0}
	if f == "retaliation":
		for at in m.spec.objective.civilians: m.objective_state.civilians.append({"at":at,"state":"waiting"})
	if not bool(m.prisoner.get("active", false)): m.prisoner.x = -99; m.prisoner.y = -99
	if f == "vip_extract":
		m.prisoner.freed = true
		m.prisoner.escort_id = m.living("player")[0].id
	if f == "ambush": spawn_runner(m,m.spec.objective)
	if f == "operation": begin_step(m)
	if Families11.applies(m): Families11.setup(m)
	if f == "defend" and int(m.spec.objective.get("hold_turns",0)) > 0:
		for enemy in m.living("enemy"):
			enemy.awake = true; enemy.spotted = true; enemy.detected = true
		m.queue_reinforcement(m.spec.wave_roster[0],2 if bool(m.spec.get("first_mission", false)) else 1,"Gate assault 1")
		m.pressure_state.waves = 1
	m.message("%s — %s" % [m.spec.name,status(m).label])

static func targets(m: RefCounted) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if m.result != "": return out
	if Families11.applies(m): return Families11.targets(m)
	if m.objective_state.phase != "primary" and (m.spec.family not in ["hack_terminal","sabotage"] or bool(m.spec.get("envoy_extract",false))): return out
	match str(m.spec.family):
		"rescue", "vip_extract":
			if not bool(m.prisoner.freed): out.append(Shot.pos(m.prisoner))
		"hack_terminal", "sabotage", "destroy_relay":
			for at in m.spec.objective.points:
				var p := Maps.point(at)
				if not m.objective_state.done.has(p): out.append(p)
		"retaliation":
			for c in m.objective_state.civilians:
				if c.state == "waiting": out.append(Maps.point(c.at))
	return out

static func interact(m: RefCounted, u: Dictionary, p: Vector2i) -> Dictionary:
	if u.is_empty() or not is_same(m.unit_by_id(int(u.get("id",-1))),u): return {"ok":false,"reason":"Unknown unit"}
	if m.result != "" or m.phase != "player" or u.get("side", "") != "player" or int(u.get("hp",0)) <= 0 or u.get("status", "ok") != "ok" or int(u.get("ap",0)) < 1:
		return {"ok":false,"reason":"Unit cannot interact"}
	if maxi(absi(int(u.x)-p.x),absi(int(u.y)-p.y)) > 1 or p == Shot.pos(u): return {"ok":false,"reason":"Stand on an adjacent tile"}
	if not targets(m).has(p): return {"ok":false,"reason":"No active objective here"}
	u.ap = int(u.ap)-1
	var f := str(m.spec.family)
	if Families11.applies(m): Families11.interact(m,u,p)
	match f:
		"rescue", "vip_extract":
			m.prisoner.freed = true; m.prisoner.escort_id = u.id
			primary_done(m)
		"hack_terminal", "sabotage":
			m.objective_state.done[p] = true
			if bool(m.spec.get("envoy_extract",false)):
				m.prisoner.freed = true; m.prisoner.escort_id = u.id
			m.message("%s: %d/%d" % ["Transmission intercepted" if bool(m.spec.get("envoy_extract",false)) else "Terminal copied" if f == "hack_terminal" else "Charge planted",m.objective_state.done.size(),int(m.spec.objective.required)])
			if m.objective_state.done.size() >= int(m.spec.objective.required): primary_done(m)
		"destroy_relay": damage_relay(m,6)
		"retaliation":
			for c in m.objective_state.civilians:
				if Maps.point(c.at) == p and c.state == "waiting": c.state = "saved"; m.objective_state.saved += 1
			if int(m.objective_state.saved) >= int(m.spec.objective.save): primary_done(m)
	m.break_concealment("Objective interaction")
	check(m)
	return {"ok":true,"ap_cost":1,"phase":m.objective_state.phase,"message":status(m).label}

static func damage_relay(m: RefCounted, amount: int) -> void:
	if m.result != "" or amount <= 0: return
	m.objective_state.relay_hp = maxi(0,int(m.objective_state.relay_hp)-amount)
	m.message("Relay integrity %d" % int(m.objective_state.relay_hp))
	if int(m.objective_state.relay_hp) > 0: return
	if m.spec.family == "defend": fail(m,"%s is lost." % str(m.spec.objective.get("name","The protected relay")))
	elif m.spec.family == "destroy_relay": primary_done(m)

static func primary_done(m: RefCounted) -> void:
	if m.objective_state.phase == "evac": return
	var rival: Dictionary = m.unit_by_id(int(m.spec.get("rival_required",-1)))
	if not rival.is_empty() and int(rival.hp) > 0:
		m.objective_state.objective_ready = true
		return
	m.objective_state.phase = "evac"; m.objective_state.evac_start = m.turn
	m.metrics.objective_turn = m.turn
	m.message("Escort the envoy to the blue evacuation zone." if bool(m.spec.get("envoy_extract",false)) else "Main objective complete. Reach the blue evacuation zone.")
	m.queue_reinforcement(["trooper","heavy"],1,"Evac pursuit")

static func fail(m: RefCounted, why: String) -> void:
	if m.result != "": return
	m.result = "loss"; m.message(why)

static func at_evac(m: RefCounted, p: Vector2i) -> bool:
	for at in m.spec.evac:
		if Maps.point(at) == p: return true
	return false

static func check(m: RefCounted) -> void:
	if m.result != "": return
	if Families11.applies(m): Families11.check(m); return
	var f := str(m.spec.family)
	if bool(m.objective_state.get("objective_ready",false)) or f == "pursuit": primary_done(m)
	if f == "operation": check_step(m)
	elif f in ["rescue","vip_extract"] or bool(m.spec.get("envoy_extract",false)):
		if int(m.prisoner.get("hp",8)) <= 0: fail(m,"The evacuee is lost."); return
		if bool(m.prisoner.freed) and m.objective_state.phase == "primary": primary_done(m)
	elif f == "ambush":
		var runner: Dictionary = m.unit_by_id(int(m.objective_state.runner_id))
		if runner_stopped(runner): primary_done(m)
	elif f == "retaliation" and m.objective_state.civilians.size()-int(m.objective_state.lost) < int(m.spec.objective.save): fail(m,"Too many civilians were lost.")
	if m.objective_state.phase != "evac" or m.result != "": return
	var squad: Array = m.living("player")
	if squad.is_empty(): return
	var done := squad.all(func(u): return at_evac(m,Shot.pos(u)))
	if f in ["rescue","vip_extract"] or bool(m.spec.get("envoy_extract",false)):
		done = at_evac(m,Shot.pos(m.prisoner)) and squad.any(func(u): return Shot.distance(Shot.pos(u),Shot.pos(m.prisoner)) <= 3.0)
	if done:
		m.result = "win"; m.metrics.evac_turn = m.turn; m.message("Objective secured. Squad extracted.")

static func enemy_end(m: RefCounted) -> void:
	if m.result != "": return
	if Families11.applies(m): Families11.enemy_end(m); return
	var f := str(m.spec.family)
	if (f in ["rescue","vip_extract"] or bool(m.spec.get("envoy_extract",false))) and bool(m.prisoner.freed):
		var vip := Shot.pos(m.prisoner)
		for e in m.living("enemy"):
			if not bool(e.awake) or bool(e.get("stunned",false)) or Shot.distance(Shot.pos(e),vip) > 4.0 or not Shot.los(m,Shot.pos(e),vip): continue
			m.prisoner.hp = maxi(0,int(m.prisoner.get("hp",8))-2)
			m.message("The exposed evacuee takes 2 damage.")
			m.action_events.append({"kind":"vip_attack","actor":e.id,"to":vip,"damage":2})
			break
	if f == "defend" and m.objective_state.phase == "primary":
		if int(m.spec.objective.get("hold_turns",0)) > 0:
			var at := Maps.point(m.spec.objective.points[0])
			var radius := float(m.spec.objective.get("zone_radius",2))
			var allies: int = m.living("player").filter(func(u): return Shot.distance(Shot.pos(u),at) <= radius).size()
			var hostiles: int = m.living("enemy").filter(func(u): return Shot.distance(Shot.pos(u),at) <= radius).size()
			var opening_grace: bool = bool(m.spec.get("first_mission", false))
			var contested := hostiles >= 2 and (hostiles > allies if opening_grace else hostiles >= allies)
			m.objective_state.overrun = int(m.objective_state.overrun) + 1 if contested else 0
			var loss_grace := 3 if opening_grace else 2
			if int(m.objective_state.overrun) >= loss_grace or (not opening_grace and hostiles >= 2 and hostiles > allies): fail(m,"The gate zone is overrun.")
			else:
				if not contested: m.objective_state.held += 1
				else: m.message("Gate contested: clear the zone next turn to recover the line.")
				if int(m.objective_state.held) >= int(m.spec.objective.hold_turns):
					m.result = "win"; m.message("%s held." % str(m.spec.objective.name))
		elif int(m.pressure_state.get("waves",0)) >= int(m.spec.objective.waves) and m.pressure_state.pending.is_empty() and m.living("enemy").is_empty(): primary_done(m)
	if f == "retaliation" and m.turn % int(m.spec.objective.get("civilian_interval",2)) == 0 and m.objective_state.phase == "primary":
		for c in m.objective_state.civilians:
			if c.state != "waiting": continue
			var exposed := false
			for e in m.living("enemy"):
				if Shot.distance(Shot.pos(e),Maps.point(c.at)) <= 8.0 and Shot.los(m,Shot.pos(e),Maps.point(c.at)): exposed = true
			if exposed:
				c.state = "lost"; m.objective_state.lost += 1; m.message("A civilian is lost. Reach the others!"); break
	if f == "operation":
		var step := current_step(m)
		if step.get("kind","") == "hold":
			var at := Maps.point(step.at); var radius := float(step.get("radius",2))
			var present: bool = m.living("player").any(func(u): return Shot.distance(Shot.pos(u),at) <= radius)
			var contested: bool = m.living("enemy").any(func(u): return Shot.distance(Shot.pos(u),at) <= radius)
			if present and not contested:
				m.objective_state.held += 1
				if int(m.objective_state.held) >= int(step.turns): next_step(m)
	check(m)

static func player_start(m: RefCounted) -> void:
	var extraction_clock: bool = str(m.objective_state.phase) == "evac" and int(m.spec.get("evac_turn_limit",0)) > 0
	var start := int(m.objective_state.evac_start) if extraction_clock else int(m.objective_state.clock_start)
	var limit := int(m.spec.evac_turn_limit) if extraction_clock else int(m.spec.turn_limit)
	if limit > 0 and start > 0 and m.turn-start >= limit:
		fail(m,"%s window closed." % str(m.spec.family).replace("_"," "))
	if Families11.applies(m): Families11.player_start(m)
	check(m)

static func current_step(m: RefCounted) -> Dictionary:
	var steps: Array = m.spec.get("operation",[])
	var index := int(m.objective_state.step)
	return steps[index] if index < steps.size() else {}

static func begin_step(m: RefCounted) -> void:
	var step := current_step(m)
	if step.is_empty(): primary_done(m); return
	m.message("Operation %d: %s" % [int(m.objective_state.step)+1,step.name])
	if not step.get("wave",[]).is_empty(): m.queue_reinforcement(step.wave,1,str(step.name))
	if step.kind == "chase": spawn_runner(m,step)
	if step.kind == "extract": primary_done(m)

static func next_step(m: RefCounted) -> void:
	m.objective_state.step += 1; m.objective_state.held = 0; begin_step(m)

static func check_step(m: RefCounted) -> void:
	var step := current_step(m)
	if step.get("kind","") == "reach":
		if m.living("player").any(func(u): return Shot.distance(Shot.pos(u),Maps.point(step.at)) <= float(step.get("radius",1))): next_step(m)
	elif step.get("kind","") == "chase":
		if runner_stopped(m.unit_by_id(int(m.objective_state.runner_id))): next_step(m)

static func runner_stopped(runner: Dictionary) -> bool:
	return not runner.is_empty() and (int(runner.hp) <= 0 or bool(runner.get("stunned",false)) or str(runner.side) != "enemy")

static func spawn_runner(m: RefCounted, step: Dictionary) -> void:
	var p := Maps.point(step.runner)
	var before: int = m.units.size()
	m._spawn_near("courier",p,90)
	if m.units.size() == before: fail(m,"Courier insertion blocked."); return
	var u: Dictionary = m.units[-1]
	if step.has("runner_hp"): u.hp = int(step.runner_hp)+int(m.difficulty.get("enemy_hp",0)); u.max_hp = u.hp
	u.runner_exit = step.exit; u.mob = int(step.get("runner_mob",3)); u.awake = true; u.spotted = true
	m.objective_state.runner_id = int(u.id)

static func runner_turn(m: RefCounted, u: Dictionary) -> bool:
	if not u.has("runner_exit"): return false
	if runner_stopped(u): check(m); return true
	var exit := Maps.point(u.runner_exit)
	var route := preload("res://scripts/map_validator.gd").path(m.board,Shot.pos(u),exit)
	var destination := Shot.pos(u)
	for p in route.slice(1,int(u.mob)+1):
		if m.occupied(p,int(u.id)): break
		destination = p
	if destination != Shot.pos(u): m.move(int(u.id),destination)
	if int(u.hp) > 0 and Shot.pos(u) == exit: fail(m,"The courier escaped with the codes.")
	check(m)
	return true

static func status(m: RefCounted) -> Dictionary:
	var s: Dictionary = m.objective_state
	var label := ("Escort the envoy to evac" if bool(m.spec.get("envoy_extract",false)) else "Extract the squad") if s.phase == "evac" else str(m.spec.family).replace("_"," ").capitalize()
	if Families11.applies(m): label = Families11.status(m)
	if s.phase == "primary":
		match str(m.spec.family):
			"rescue": label = "Free the prisoner, then escort to evac"
			"vip_extract": label = "Escort the VIP to the far evac"
			"hack_terminal", "sabotage": label = ("Intercept the envoy's transmission" if bool(m.spec.get("envoy_extract",false)) else label) + " %d/%d" % [s.done.size(),int(m.spec.objective.required)]
			"destroy_relay": label += " · Relay %d HP" % int(s.relay_hp)
			"defend": label = "HOLD %d/%d · %s %d HP" % [int(s.held),int(m.spec.objective.hold_turns),str(m.spec.objective.name),int(s.relay_hp)] if int(m.spec.objective.get("hold_turns",0)) > 0 else label + " · Relay %d HP" % int(s.relay_hp)
			"retaliation": label = "Save civilians %d/%d · %d lost" % [int(s.saved),int(m.spec.objective.save),int(s.lost)]
			"operation": label = str(current_step(m).get("name","Extract"))
	if m.spec.has("rival_required") and s.phase == "primary": label += " · Defeat the rival"
	var extraction_clock: bool = s.phase == "evac" and int(m.spec.get("evac_turn_limit",0)) > 0
	var clock_start := int(s.evac_start) if extraction_clock else int(s.clock_start)
	var limit := int(m.spec.evac_turn_limit) if extraction_clock else int(m.spec.turn_limit)
	return {"label":label,"phase":s.phase,"clock_trigger":m.spec.clock_trigger,"turns_left":maxi(0,limit-(m.turn-clock_start)) if clock_start>0 and limit>0 else -1,"held":s.held}

static func defense_turn(m: RefCounted, u: Dictionary) -> bool:
	if m.spec.family != "defend" or m.objective_state.phase != "primary": return false
	if bool(u.get("stunned",false)) or bool(u.get("skip_turn",false)): return false
	var target := Maps.point(m.spec.objective.points[0])
	if Shot.distance(Shot.pos(u),target) > 5.0 or not Shot.los(m,Shot.pos(u),target):
		var reachable: Dictionary = m.paths(u,int(u.mob)); var best := Shot.pos(u)
		for p in reachable.costs:
			if Shot.distance(p,target) < Shot.distance(best,target): best = p
		if best != Shot.pos(u): m.move(int(u.id),best)
	if int(u.hp) > 0 and int(u.ap) >= 2 and Shot.distance(Shot.pos(u),target) <= 5.0 and Shot.los(m,Shot.pos(u),target):
		u.ap = int(u.ap)-2; damage_relay(m,2)
		m.action_events.append({"kind":"objective_attack","actor":u.id,"from":Shot.pos(u),"to":target,"damage":2})
	return true
