extends RefCounted
const Shot = preload("res://scripts/shot.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const AI = preload("res://scripts/ai.gd")

static func setup(m: RefCounted) -> void:
	m.pressure_state = {"pending":[],"last_entry":-1,"waves":0,"brood_turn":0,"chain_turn":0,"chain_count":0,"calm_turn":0,"serial":0}
	# Introduce one new threat at a time across the late war and later era.
	var variants := {"dock":[2,0,"assassin11"],"r_muster":[1,0,"shield_droid11"],"r_bomb":[2,0,"alchemist11"],"r_nexus":[0,0,"beast11"],"h_roots":[1,0,"beast11"]}
	if variants.has(str(m.spec.id)):
		var swap: Array = variants[str(m.spec.id)]
		if m.spec.groups.size() > int(swap[0]) and m.spec.groups[int(swap[0])].size() > int(swap[1]): m.spec.groups[int(swap[0])][int(swap[1])][0] = swap[2]
	# Local additions avoid changing the combat lane's unit catalog.
	var droid: Dictionary = m.catalog.trooper.duplicate(true)
	droid.name = "Security Droid"; droid.droid = true; droid.class_name = "Security Droid"
	m.catalog.droid = droid
	var courier: Dictionary = m.catalog.trooper.duplicate(true)
	courier.name = "Imperial Courier"; courier.hp = 5; courier.mob = 3
	m.catalog.courier = courier
	var brood: Dictionary = m.catalog.acolyte.duplicate(true)
	brood.name = "Brood Horror"; brood.hp = 10; brood.horror = true; brood.range = 1.5
	m.catalog.brood = brood
	var husk: Dictionary = brood.duplicate(true)
	husk.name = "Dark Husk"; husk.hp = 3; husk.mob = 6; husk.damage = [2,3]; husk.swarm = true
	m.catalog.husk = husk

static func choose_entry(m: RefCounted) -> int:
	var entries: Array = m.spec.entries
	var best := 0; var score := -INF
	for i in entries.size():
		var p := Maps.point(entries[i]); var distance := INF
		for u in m.living("player"): distance = minf(distance,Shot.distance(p,Shot.pos(u)))
		var value := distance + (100.0 if distance >= 4.0 else 0.0) - (30.0 if i == int(m.pressure_state.last_entry) else 0.0)
		if value > score: score = value; best = i
	return best

static func queue(m: RefCounted, kinds: Array, delay: int = 1, reason: String = "Reinforcements") -> void:
	if kinds.is_empty() or m.result != "" or m.spec.get("entries",[]).is_empty(): return
	kinds = kinds.duplicate()
	for extra in int(m.spec.get("sith_mods",{}).get("extraEnemies",0)): kinds.append("trooper")
	var i := choose_entry(m); var entry: Array = m.spec.entries[i]
	m.pressure_state.last_entry = i
	m.pressure_state.serial += 1
	m.pressure_state.pending.append({"serial":m.pressure_state.serial,"spawned":0,"at":[entry[0],entry[1]],"name":entry[2],"kinds":kinds.duplicate(),"turn":m.turn+maxi(1,delay),"announced":m.turn,"reason":reason})
	m.reinforcement_announced = true; m.reinforcement_marker = Maps.point(entry)
	m.message("INBOUND: %s — %s in %d turn(s)." % [reason,entry[2],maxi(1,delay)])

static func player_start(m: RefCounted) -> void:
	var later: Array = []
	for wave in m.pressure_state.pending:
		if int(wave.turn) > m.turn: later.append(wave); continue
		var landed := 0; var blocked: Array = []
		for kind in wave.kinds:
			var count: int = m.units.size()
			m._spawn_near(str(kind),Maps.point(wave.at),1000+int(wave.serial)*20+int(wave.spawned)/2)
			if m.units.size() == count: blocked.append(kind); continue
			landed += 1; wave.spawned += 1; m.units[-1].spotted = true; m.units[-1].detected = true
			if m.spec.family == "defend" and int(m.spec.objective.get("hold_turns",0)) > 0: m.units[-1].awake = true
			m.action_events.append({"kind":"reinforcement","actor":m.units[-1].id,"at":Shot.pos(m.units[-1])})
		if not blocked.is_empty():
			wave.kinds = blocked; wave.turn = m.turn+1; wave.announced = m.turn; later.append(wave)
			m.message("Blocked landing: remaining hostiles inbound next turn.")
		if landed > 0: m.reinforcement_dropped = true; m.message("%d hostiles arrive from %s." % [landed,wave.name])
	m.pressure_state.pending = later
	m.reinforcement_marker = Maps.point(later[0].at) if not later.is_empty() else Vector2i(-1,-1)
	if m.spec.family == "defend" and m.objective_state.phase == "primary" and m.turn % 2 == 0 and int(m.pressure_state.waves) < int(m.spec.objective.waves):
		var wave := int(m.pressure_state.waves)
		var kinds: Array = ["trooper","trooper"]
		if wave > 0: kinds.append("heavy")
		if wave > 1: kinds.append("acolyte")
		if wave > 2: kinds.append("agent")
		if m.spec.has("wave_roster") and wave < m.spec.wave_roster.size(): kinds = m.spec.wave_roster[wave].duplicate()
		queue(m,kinds,1,"Defense wave %d" % (wave+1)); m.pressure_state.waves += 1
	elif m.spec.family not in ["defend","holocron_recovery","evacuation","sith_lord_duel"] and m.turn == 4: queue(m,["trooper","trooper"],1,"Patrol support")

static func brood(m: RefCounted) -> void:
	if not bool(m.spec.get("swarm",false)) or m.turn % 2 != 0 or int(m.pressure_state.brood_turn) == m.turn: return
	var live := 0
	for u in m.living("enemy"):
		if bool(u.get("swarm",false)): live += 1
	if live >= 6: return
	for u in m.living("enemy"):
		if not bool(u.get("horror",false)) or bool(u.get("swarm",false)) or bool(u.get("stunned",false)) or not bool(u.awake): continue
		m.pressure_state.brood_turn = m.turn
		for i in mini(2,6-live):
			var count: int = m.units.size(); m._spawn_near("husk",Shot.pos(u),int(u.group),3)
			if m.units.size() > count: m.units[-1].awake = true; m.units[-1].spotted = true
		m.message("The horror calls its brood."); return

static func on_kill(m: RefCounted, target: Dictionary, source: Dictionary) -> void:
	if not bool(m.spec.get("swarm",false)) or not bool(target.get("horror",false)) or source.get("side","") != "player" or m.phase != "player": return
	if int(m.pressure_state.calm_turn) == m.turn: m.message("The swarm stays calm."); return
	if int(m.pressure_state.chain_turn) != m.turn: m.pressure_state.chain_turn = m.turn; m.pressure_state.chain_count = 0
	if int(m.pressure_state.chain_count) >= 2: return
	var nearest: Dictionary = {}; var distance := 5.01
	for u in m.living("enemy"):
		if not bool(u.get("swarm",false)) or int(u.get("chained",0)) == m.turn: continue
		var d := Shot.distance(Shot.pos(u),Shot.pos(target))
		if d < distance: nearest = u; distance = d
	if nearest.is_empty(): return
	m.pressure_state.chain_count += 1; nearest.chained = m.turn
	m.message("SWARM SURGE: the nearest Husk lunges!")
	var phase: String = m.phase; m.phase = "enemy"; nearest.ap = 3
	horror_turn(m,nearest)
	m.phase = phase

## Horrors only attack Jedi: troops can screen them. Uses the existing move/shot rules.
static func horror_turn(m: RefCounted, u: Dictionary) -> bool:
	if not bool(u.get("horror",false)): return false
	if bool(u.get("stunned",false)) or int(u.hp) <= 0: return true
	var jedi: Array = m.living("player").filter(func(p): return str(p.class_name) in ["Guardian","Consular"])
	if jedi.is_empty(): return true
	jedi.sort_custom(func(a,b): return Shot.distance(Shot.pos(u),Shot.pos(a)) < Shot.distance(Shot.pos(u),Shot.pos(b)))
	var target: Dictionary = jedi[0]; var reach: Dictionary = m.paths(u,int(u.mob)); var best := Shot.pos(u)
	for p in reach.costs:
		if Shot.distance(p,Shot.pos(target)) < Shot.distance(best,Shot.pos(target)): best = p
	if best != Shot.pos(u): m.move(int(u.id),best)
	if int(u.hp) > 0: m.shot(int(u.id),int(target.id),"strike")
	return true
