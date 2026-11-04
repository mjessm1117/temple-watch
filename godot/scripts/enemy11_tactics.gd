extends RefCounted
const Shot = preload("res://scripts/shot.gd")

static func hidden(m: RefCounted, e: Dictionary) -> bool:
	if str(e.get("kind","")) != "assassin11" or bool(e.get("revealed11",false)): return false
	for p in m.living("player"):
		if Shot.distance(Shot.pos(p),Shot.pos(e)) <= 1.5 or "sense" in p.get("passives",[]) and Shot.distance(Shot.pos(p),Shot.pos(e)) <= 5.0 and Shot.los(m,Shot.pos(p),Shot.pos(e)):
			e.revealed11 = true; e.spotted = true
			m.message("Sith Assassin revealed: it flanks from concealment.")
			return false
	return true

static func intercept_damage(m: RefCounted, target: Dictionary, amount: int, source: Dictionary) -> int:
	if str(target.get("kind","")) != "shield_droid11" or int(target.get("shield_front",0)) <= 0 or source.is_empty(): return amount
	var facing: Vector2i = target.get("front11",Vector2i(0,1))
	var delta := Shot.pos(source)-Shot.pos(target)
	if delta.x*facing.x+delta.y*facing.y <= 0: return amount
	target.shield_front = maxi(0,int(target.shield_front)-amount)
	m.message("Shield Droid blocks the frontal hit%s" % ("; shield broken!" if int(target.shield_front) == 0 else ". Flank it!"))
	return 0

static func act(m: RefCounted, e: Dictionary, fired: Dictionary) -> bool:
	match str(e.get("kind","")):
		"assassin11":
			if bool(e.get("stunned",false)): return false
			if not bool(e.awake): e.ap = 2
			var target: Dictionary = nearest(m,e)
			if target.is_empty(): return true
			var dest := flank(m,e,target)
			if dest != Shot.pos(e): m.move(int(e.id),dest)
			if Shot.distance(Shot.pos(e),Shot.pos(target)) <= 1.5: m.shot(int(e.id),int(target.id),"strike")
			hidden(m,e)
			return true
		"shield_droid11":
			var p: Dictionary = nearest(m,e)
			if not p.is_empty(): e.front11 = cardinal(Shot.pos(p)-Shot.pos(e))
			return false
		"alchemist11":
			if bool(e.get("stunned",false)): return false
			var wounded: Dictionary = {}
			for ally in m.living("enemy"):
				if int(ally.id) == int(e.id) or Shot.distance(Shot.pos(e),Shot.pos(ally)) > 6: continue
				if int(ally.hp) < int(ally.max_hp) and (wounded.is_empty() or int(ally.hp) < int(wounded.hp)): wounded = ally
			if not wounded.is_empty():
				wounded.hp = mini(int(wounded.max_hp),int(wounded.hp)+3)
				m.message("Sith Alchemist heals %s for 3. Target the Alchemist!" % wounded.name)
			else:
				for ally in m.living("enemy"):
					if int(ally.id) != int(e.id) and Shot.distance(Shot.pos(e),Shot.pos(ally)) <= 5:
						ally.buff_aim = 15; ally.buff_until = m.turn+2
						m.message("Sith Alchemist empowers %s (+15 aim)." % ally.name); break
			var retreat := preload("res://scripts/ai.gd").choose_destination(m,e,int(e.mob),true)
			if retreat != Shot.pos(e): m.move(int(e.id),retreat)
			return true
		"beast11":
			if bool(e.get("stunned",false)): return false
			var prey: Dictionary = nearest(m,e)
			if prey.is_empty(): return true
			var delta := Shot.pos(prey)-Shot.pos(e)
			var step := cardinal(delta)
			var blocker := Shot.pos(e)+step
			if m.tile(blocker) in ["c","h","k"]:
				m.set_tile(blocker,"r"); m.terrain_revision += 1
				m.message("The beast charges through half cover!")
			var reach: Dictionary = m.reach_tiles(e, 1); var best := Shot.pos(e)
			for p in reach.costs:
				if Shot.distance(p,Shot.pos(prey)) < Shot.distance(best,Shot.pos(prey)): best = p
			if best != Shot.pos(e): m.move(int(e.id),best)
			if Shot.distance(Shot.pos(e),Shot.pos(prey)) <= 1.5: m.shot(int(e.id),int(prey.id),"strike")
			return true
		"lord11":
			if int(e.get("duel_phase",1)) == 2 and int(e.get("lightning_turn",0)) < m.turn:
				var lightning: Dictionary = m.abilities.lordLightning11
				var p: Dictionary = nearest(m,e)
				if not p.is_empty() and Shot.distance(Shot.pos(e),Shot.pos(p)) <= float(lightning.range):
					e.lightning_turn = m.turn; m.apply_damage(p,int(lightning.damage[0]),e)
					m.message("The Sith Lord strikes %s with Force lightning." % p.name)
					m.action_events.append({"kind":"objective_attack","actor":e.id,"to":Shot.pos(p),"damage":int(lightning.damage[0])})
			return false
	return false

static func nearest(m: RefCounted, e: Dictionary) -> Dictionary:
	var target: Dictionary = {}; var distance := INF
	for p in m.living("player"):
		var d := Shot.distance(Shot.pos(e),Shot.pos(p))
		if d < distance: distance = d; target = p
	return target

static func cardinal(delta: Vector2i) -> Vector2i:
	return Vector2i(signi(delta.x),0) if absi(delta.x) >= absi(delta.y) else Vector2i(0,signi(delta.y))

static func flank(m: RefCounted, e: Dictionary, target: Dictionary) -> Vector2i:
	var reach: Dictionary = m.reach_tiles(e, 1); var best := Shot.pos(e); var score := -INF
	for p in reach.costs:
		var d := Shot.distance(p,Shot.pos(target))
		var side: int = absi(p.x-int(target.x)) if absi(int(e.y)-int(target.y)) > absi(int(e.x)-int(target.x)) else absi(p.y-int(target.y))
		var value := -d*3.0 + float(side)*1.2
		if d <= 1.5: value += 25
		if value > score: score = value; best = p
	return best
