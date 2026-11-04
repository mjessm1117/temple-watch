extends SceneTree
## Campaign factory, roster gear and combat adapter; no teleports or simulated results.
const Campaign = preload("res://scripts/campaign/state.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Bot = preload("res://tests/loop_bot.gd")
const Shot = preload("res://scripts/shot.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Ability = preload("res://scripts/abilities_engine.gd")
const FAMILIES = {"rescue":"rescue","hack":"archive","relay":"dock","defend":"relay","retaliation":"r_hospital","sabotage":"sabotage","ambush":"adraasHunt"}

func _initialize() -> void: run.call_deferred()

static func goal(m, u: Dictionary) -> Vector2i:
	if m.objective_state.phase == "evac":
		if m.spec.family in ["rescue","vip_extract"]:
			var escort: Dictionary = m.unit_by_id(int(m.prisoner.get("escort_id",-1)))
			if (escort.is_empty() or int(escort.hp)<=0) and Shot.distance(Shot.pos(u),Shot.pos(m.prisoner))>3: return Shot.pos(m.prisoner)
			if int(escort.get("id",-1)) == int(u.id) and Shot.distance(Shot.pos(u),Shot.pos(m.prisoner))>6: return Shot.pos(m.prisoner)
		var best := Vector2i(-1,-1); var distance := INF
		for at in m.spec.evac:
			var p := Maps.point(at)
			if m.occupied(p,int(u.id)): continue
			if Shot.distance(Shot.pos(u),p) < distance: best = p; distance = Shot.distance(Shot.pos(u),p)
		return best if best.x >= 0 else Shot.pos(u)
	var points: Array = m.interactables()
	if m.spec.family == "ambush":
		var runner: Dictionary = m.unit_by_id(int(m.objective_state.runner_id))
		if not runner.is_empty(): return Shot.pos(runner)
	if points.is_empty(): points = [Maps.point(m.spec.objective.points[0])]
	points.sort_custom(func(a,b): return Shot.distance(Shot.pos(u),a)<Shot.distance(Shot.pos(u),b))
	return points[0]

static func advance_to(m, u: Dictionary, dest: Vector2i, reserve: bool = false) -> bool:
	if not m.has_meta("bot_fields") or int(m.get_meta("bot_revision",-1)) != int(m.terrain_revision):
		m.set_meta("bot_fields",{}); m.set_meta("bot_revision",int(m.terrain_revision))
	var fields: Dictionary = m.get_meta("bot_fields")
	if not fields.has(dest): fields[dest] = Bot._distance_field(m,dest)
	var field: Dictionary = fields[dest]
	var budget: int = int(u.mob)*(2 if int(u.ap)>=2 and not reserve else 1)
	var reach: Dictionary = m.paths(u,budget)
	var best := Shot.pos(u); var score := float(field.get(best,999))
	for p in reach.costs:
		if p == Shot.pos(u): continue
		var next := float(field.get(p,999))+float(reach.costs[p])*0.015
		# Cover is a tie breaker, never an excuse to abandon the objective.
		if Shot.in_cover(m,p): next -= 0.15
		if next < score: score = next; best = p
	return best != Shot.pos(u) and m.move(int(u.id),best)

static func turn(m) -> void:
	for u in m.living("player"):
		var treated := false
		for cycle in 6:
			if m.result != "" or int(u.hp)<=0 or int(u.ap)<=0: break
			var interacted := false
			for p in m.interactables():
				if maxi(absi(int(u.x)-p.x),absi(int(u.y)-p.y)) == 1:
					if m.use_ability(int(u.id),"interact",-1,p): interacted = true; break
			if interacted: continue
			if not treated and int(u.ap)>=2:
				for skill in ["forceHeal","heal","medpac","revive"]:
					if m.ability_reason(int(u.id),skill) != "": continue
					for ally in Ability.targets(m,u,skill):
						if int(ally.hp) <= int(ally.max_hp)-4 and m.use_ability(int(u.id),skill,int(ally.id)):
							treated = true; break
					if treated: break
				if treated: continue
			var dest := goal(m,u)
			if m.objective_state.phase == "evac":
				if m.spec.family not in ["rescue","vip_extract"] and preload("res://scripts/mission_objectives.gd").at_evac(m,Shot.pos(u)): break
				if advance_to(m,u,dest): continue
				if m.spec.family in ["rescue","vip_extract"] and bool(m.prisoner.freed): break
			var foes: Array = m.living("enemy").filter(func(e): return bool(e.spotted) or bool(e.awake))
			foes.sort_custom(func(a,b): return (0 if a.has("runner_exit") else 100)+int(a.hp)<(0 if b.has("runner_exit") else 100)+int(b.hp))
			var attacked := false
			for e in foes:
				if "strike" in u.kit and maxi(absi(int(u.x)-int(e.x)),absi(int(u.y)-int(e.y)))<=1:
					if m.shot(int(u.id),int(e.id),"strike"): attacked = true; break
				if "shoot" in u.kit and int(u.ap)>=1:
					var info: Dictionary = Shot.calculate(m,u,e)
					if info.los and info.range_ok and int(info.hit)>=40:
						if int(u.get("ammo",1)) == 0: attacked = m.use_ability(int(u.id),"reload")
						else: attacked = m.shot(int(u.id),int(e.id))
						if attacked: break
			if attacked: continue
			if m.objective_state.phase != "evac" and m.spec.family == "defend" and foes.is_empty():
				# Search the briefed patrol sectors after the visible attackers fall.
				var sector: Array = m.spec.groups[(m.turn/3)%m.spec.groups.size()][0]
				dest = Vector2i(int(sector[1]),int(sector[2]))
			elif m.objective_state.phase != "evac" and m.spec.family == "defend" and not foes.is_empty():
				foes.sort_custom(func(a,b): return Shot.distance(Shot.pos(u),Shot.pos(a))<Shot.distance(Shot.pos(u),Shot.pos(b)))
				dest = Shot.pos(foes[0])
			elif "strike" in u.kit and m.objective_state.phase != "evac":
				for e in foes:
					if Shot.distance(Shot.pos(u),Shot.pos(e))<=float(u.mob)+1 and (Shot.distance(Shot.pos(e),dest)<Shot.distance(Shot.pos(u),dest)+3 or m.spec.family=="ambush"):
						dest = Shot.pos(e); break
			if advance_to(m,u,dest,int(u.ap)>=2): continue
			if u.has("ammo") and int(u.ammo)<int(u.clip): m.use_ability(int(u.id),"reload")
			elif "overwatch" in u.kit: m.overwatch(int(u.id))
			break
	m.end_turn()

func run() -> void:
	var count := 20
	if "--quick" in OS.get_cmdline_user_args(): count = 3
	var failures := 0
	for family in FAMILIES:
		if "--family" in OS.get_cmdline_user_args() and family != OS.get_cmdline_user_args()[-1]: continue
		var wins := 0; var losses := {}; var turns := 0
		for seed_value in range(1,count+1):
			var c = Campaign.new("normal")
			c.state.options = [{"mission":FAMILIES[family],"map_variant":0,"adv":false}]
			c.select_mission(0)
			var m = Battle.create(c,seed_value)
			for step in 60:
				if m.result != "": break
				turn(m)
			if "--trace" in OS.get_cmdline_user_args(): print("TRACE ",family," seed ",seed_value," ",m.turn," ",m.result," objective ",m.objective_status()," players ",m.living("player").map(func(u): return [u.name,u.hp,u.x,u.y])," enemies ",m.living("enemy").map(func(u): return [u.name,u.hp,u.x,u.y,u.awake])," vip ",m.prisoner)
			turns += m.turn
			if m.result == "win": wins += 1
			else:
				var why: String = m.log_lines[-1] if m.result != "" else "turn safety limit"
				losses[why] = int(losses.get(why,0))+1
				if m.result == "": failures += 1
			c.apply_mission_result(Battle.result(c,m))
		if count >= 20 and (wins*100/count < 30 or wins*100/count > 80):
			failures += 1; push_error("Campaign family outside 30–80% band: " + str(family))
		print("CAMPAIGN BOT %s: %d/%d wins (%d%%), mean turns %.1f; losses %s" % [family,wins,count,100*wins/count,float(turns)/count,JSON.stringify(losses)])
	quit(1 if failures else 0)
