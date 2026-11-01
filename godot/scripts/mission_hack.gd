extends RefCounted
const Shot = preload("res://scripts/shot.gd")

static func options(m: RefCounted, u: Dictionary, tile: Vector2i) -> Dictionary:
	if u.is_empty() or not is_same(m.unit_by_id(int(u.get("id",-1))),u) or int(u.get("hp",0)) <= 0 or u.get("side","") != "player" or m.phase != "player" or m.result != "" or int(u.get("ap",0)) < 1: return {}
	if Shot.distance(Shot.pos(u),tile) > 4.0 or not Shot.los(m,Shot.pos(u),tile): return {}
	var target := ""; var droid: Dictionary = {}
	for e in m.living("enemy"):
		if Shot.pos(e) == tile and bool(e.get("droid",false)): target = "droid"; droid = e
	if target == "" and m.tile(tile) in ["k","q","Q"] and not m.hack_state.get("used",{}).has(tile): target = "console"
	if target == "": return {}
	var bonus := (10 if u.get("class_name","") == "Medic" else 0) + (10 if bool(u.get("tech",false)) else 0)
	return {"target":target,"unit":droid,"safe":mini(95,(80 if target == "droid" else 85)+bonus),"risky":mini(95,(40 if target == "droid" else 45)+bonus)}

static func use(m: RefCounted, u: Dictionary, tile: Vector2i, mode: String = "safe") -> Dictionary:
	if mode not in ["safe","risky"]: return {"ok":false,"reason":"Unknown hack mode"}
	var choices := options(m,u,tile)
	if choices.is_empty(): return {"ok":false,"reason":"No hackable target in range"}
	u.ap = int(u.ap)-1
	m.break_concealment("Network intrusion")
	if not m.hack_state.has("used"): m.hack_state.used = {}
	if choices.target == "console": m.hack_state.used[tile] = true
	var success: bool = m.rng.randi_range(1,100) <= int(choices[mode])
	if success:
		if choices.target == "console" and mode == "safe":
			for e in m.living("enemy"): e.spotted = true
			m.hack_state.intel = int(m.hack_state.get("intel",0))+1
		elif choices.target == "console":
			var count := 0
			for e in m.living("enemy"):
				if count < 2 and Shot.los(m,Shot.pos(u),Shot.pos(e)): e.stunned = true; e.stunned_until = m.turn+1; count += 1
		elif mode == "safe": choices.unit.stunned = true; choices.unit.stunned_until = m.turn+1
		else: choices.unit.controlled_until = m.turn+1
	else:
		if mode == "risky" and choices.target == "console": m.queue_reinforcement(["trooper","trooper"],2,"Hack alarm")
		elif mode == "risky":
			if not choices.unit.has("hack_aim_until"): choices.unit.aim = int(choices.unit.aim)+20
			choices.unit.hack_aim_until = m.turn+2
	m.message("%s hack %s (%d%%)." % [mode.capitalize(),"succeeded" if success else "failed",int(choices[mode])])
	return {"ok":true,"success":success,"chance":choices[mode],"ap_cost":1}

static func player_start(m: RefCounted) -> void:
	for u in m.units:
		if u.has("hack_aim_until") and m.turn >= int(u.hack_aim_until): u.aim = int(u.aim)-20; u.erase("hack_aim_until")
		if u.has("controlled_until") and m.turn > int(u.controlled_until): u.erase("controlled_until")

static func controlled_turn(m: RefCounted, u: Dictionary) -> bool:
	if not u.has("controlled_until"): return false
	if int(u.hp) <= 0 or bool(u.get("stunned",false)): return true
	# Control takes effect for this enemy phase only; restore allegiance after the attack.
	var previous_kit: Array = u.get("kit",[]).duplicate()
	u.kit = ["shoot"]; u.side = "player"
	var phase: String = m.phase; m.phase = "player"
	for e in m.living("enemy"):
		if m.shot(int(u.id),int(e.id)): break
	m.phase = phase; u.side = "enemy"; u.kit = previous_kit; u.erase("controlled_until"); m._check_lose()
	return true
