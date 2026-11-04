extends SceneTree
const Mission = preload("res://scripts/mission.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Families = preload("res://scripts/mission11_families.gd")
const Enemy = preload("res://scripts/enemy11_tactics.gd")
const Shot = preload("res://scripts/shot.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Bot = preload("res://tests/campaign_bot.gd")
const Settings = preload("res://scripts/settings.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; print("FAIL: ",label)

func mission(id: String) -> RefCounted:
	return Mission.new(17,Maps.resolve(id))

func run() -> void:
	Settings.difficulty = "normal"
	var families := {"r_caves":"holocron_recovery","r_ravine":"evacuation","r_seventh":"sith_lord_duel"}
	var briefings: Dictionary = Maps.read("res://data/campaign/missions.json").MISSIONS
	for id in families:
		var m = mission(id)
		check(m.spec.family == families[id],id+" uses new family")
		check(briefings[id].family == families[id] and str(briefings[id].brief).length() > 80 and int(m.spec.turn_limit) > 0,id+" has briefing and deadline")
	for pair in [["dock","assassin11"],["r_muster","shield_droid11"],["r_bomb","alchemist11"],["r_nexus","beast11"],["h_roots","beast11"]]:
		check(mission(pair[0]).living("enemy").any(func(u): return u.kind == pair[1]),"era roster adds "+pair[1]+" to "+pair[0])
	_holocron()
	_evacuation()
	_duel()
	_enemies()
	if "--rules" in OS.get_cmdline_user_args():
		print("MISSIONS11 RESULTS: %d checks, %d failures" % [checks,failures]); quit(1 if failures > 0 else 0); return
	for id in families:
		if "--family" in OS.get_cmdline_user_args() and id != OS.get_cmdline_user_args()[-1]: continue
		var wins := 0; var finish_turns := {}
		for seed_value in range(1,21):
			var c = Campaign.new("normal")
			c.state.options = [{"mission":id,"map_variant":0,"adv":false}]
			c.select_mission(0)
			var m = Battle.create(c,seed_value)
			check(m != null,id+" campaign battle created")
			if m == null: continue
			for step in 60:
				if m.result != "": break
				Bot.turn(m)
			check(m.result != "",id+" campaign bot terminates")
			finish_turns[m.turn] = int(finish_turns.get(m.turn,0))+1
			if m.result == "win": wins += 1
		print("MISSIONS11 CAMPAIGN %s (%s): %d/20 wins (%d%%)" % [id,families[id],wins,wins*5])
		print("MISSIONS11 TURNS %s: %s" % [families[id],JSON.stringify(finish_turns)])
		check(wins >= 7 and wins <= 16,id+" campaign Normal 35–80% band")
	if "--family" in OS.get_cmdline_user_args():
		print("MISSIONS11 RESULTS: %d checks, %d failures" % [checks,failures]); quit(1 if failures > 0 else 0); return
	var rescue_wins := 0
	for seed_value in range(1,21):
		var m = Mission.new(seed_value,"res://data/rescue.json")
		for step in 60:
			if m.result != "": break
			preload("res://tests/loop_bot.gd")._bot_turn(m)
		if m.result == "win": rescue_wins += 1
	print("Normal rescue bot: %d/20 wins" % rescue_wins)
	check(rescue_wins >= 9 and rescue_wins <= 11,"legacy Normal rescue bot remains 9–11/20")
	print("MISSIONS11 RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)

func _holocron() -> void:
	var m = mission("r_caves"); var u: Dictionary = m.living("player")[0]
	var at: Vector2i = m.interactables()[0]
	u.x = at.x-1; u.y = at.y; u.ap = 3
	var before := int(u.mob)
	check(m.interact(u,at).ok and int(u.mob) == before-2 and m.objective_state.phase == "evac","holocron pickup slows carrier and triggers extraction")
	check(not m.pressure_state.pending.is_empty(),"holocron pursuit announced")
	u.x = m.spec.evac[0][0]; u.y = m.spec.evac[0][1]; m._check_win()
	check(m.result == "win","holocron carrier extracts")
	m = mission("r_caves"); u = m.living("player")[0]; at = m.interactables()[0]
	u.x = at.x-1; u.y = at.y; m.interact(u,at)
	m.apply_damage(u,99,m.living("enemy")[0])
	check(m.objective_state.phase == "primary" and m.interactables().has(Shot.pos(u)),"downed carrier drops holocron")

func _evacuation() -> void:
	var m = mission("r_ravine")
	check(m.objective_state.civilian_ids.size() >= 4,"four or more civilians present")
	check(preload("res://scripts/mission_metrics.gd").report(m).civilians_total == 5,"evacuation score tracks all five civilians")
	var c: Dictionary = m.unit_by_id(int(m.objective_state.civilian_ids[0])); var escort: Dictionary = m.living("player")[0]
	escort.x = int(c.x); escort.y = int(c.y)+1
	m.interact(escort,Shot.pos(c))
	var before := Shot.pos(c)
	m.units = m.units.filter(func(u): return u.side != "enemy")
	Families.enemy_end(m)
	check(Shot.pos(c) != before,"civilian follows nearby escort")
	m.turn = 2; Families.player_start(m)
	check(not m.pressure_state.pending.is_empty(),"timed evacuation wave announced")
	for i in range(2):
		c = m.unit_by_id(int(m.objective_state.civilian_ids[i])); c.hp = 0; m.objective_state.lost += 1
	m._check_win(); check(m.result == "loss","evacuation loses when survival quota impossible")

func _duel() -> void:
	var m = mission("r_seventh"); var boss: Dictionary = m.unit_by_id(int(m.objective_state.boss_id))
	check(int(boss.hp) >= 18,"Sith Lord has boss health")
	check(m.abilities.has("lordLightning11"),"phase two grants Force lightning ability")
	m.apply_damage(boss,ceili(float(boss.hp)/2.0),m.living("player")[0])
	check(m.objective_state.boss_phase == 2 and not m.pressure_state.pending.is_empty(),"half health triggers phase two and adds")
	m.phase = "enemy"; boss.awake = true; var target: Dictionary = m.living("player")[0]
	target.x = int(boss.x)+1; target.y = int(boss.y)
	var before := int(target.hp); Enemy.act(m,boss,{})
	check(int(target.hp) < before,"phase two lightning damages target")
	m.apply_damage(boss,99,m.living("player")[0]); check(m.result == "win","defeating Lord wins duel")

func _enemies() -> void:
	var m = mission("r_caves")
	var assassin: Dictionary = m.living("enemy").filter(func(u): return u.kind == "assassin11")[0]
	check(Enemy.hidden(m,assassin),"assassin begins hidden")
	var p: Dictionary = m.living("player")[0]; p.x = int(assassin.x)+1; p.y = int(assassin.y)
	check(not Enemy.hidden(m,assassin) and assassin.spotted,"adjacent scout reveals assassin")
	var droid: Dictionary = m.living("enemy").filter(func(u): return u.kind == "shield_droid11")[0]
	p.x = int(droid.x); p.y = int(droid.y)+3
	check(Enemy.intercept_damage(m,droid,3,p) == 0 and int(droid.shield_front) == 3,"frontal shield blocks and wears down")
	p.y = int(droid.y)-3
	check(Enemy.intercept_damage(m,droid,3,p) == 3,"rear attack bypasses shield")
	var healer: Dictionary = m.living("enemy").filter(func(u): return u.kind == "alchemist11")[0]
	var ally: Dictionary = m.living("enemy").filter(func(u): return u.kind != "alchemist11")[0]
	ally.x = int(healer.x)+1; ally.y = int(healer.y); ally.hp = int(ally.hp)-2
	m.phase = "enemy"; healer.ap = 3; var before := int(ally.hp); Enemy.act(m,healer,{})
	check(int(ally.hp) > before,"alchemist heals a nearby ally")
	var beast_map = mission("r_ravine"); var beast: Dictionary = beast_map.living("enemy").filter(func(u): return u.kind == "beast11")[0]
	check(int(beast.mob) >= 8 and "creature" in beast.tags,"beast is fast melee creature")
	beast_map.phase = "enemy"; beast.ap = 3; beast.awake = true
	var prey: Dictionary = beast_map.living("player")[0]; prey.x = int(beast.x); prey.y = int(beast.y)+3
	var obstacle := Shot.pos(beast)+Vector2i.DOWN; beast_map.set_tile(obstacle,"c")
	Enemy.act(beast_map,beast,{})
	check(beast_map.tile(obstacle) == "r","beast charge smashes half cover")
