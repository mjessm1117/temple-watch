extends SceneTree
const Mission = preload("res://scripts/mission.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Validator = preload("res://scripts/map_validator.gd")
const Objectives = preload("res://scripts/mission_objectives.gd")
const Pressure = preload("res://scripts/mission_pressure.gd")
const Hack = preload("res://scripts/mission_hack.gd")
const Fronts = preload("res://scripts/mission_fronts.gd")
const Presentation = preload("res://scripts/map_presentation.gd")
const Shot = preload("res://scripts/shot.gd")
const Settings = preload("res://scripts/settings.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; print("FAIL: ",label)

func run() -> void:
	Settings.difficulty = "normal"
	var manifest := Maps.manifest()
	var story := Story.new()
	var missions: Dictionary = story.table("BASE_MISSIONS"); missions.merge(story.table("MISSIONS"),true)
	var unique := {}; var geometry := {}; var families := {}; var paths: Array = []
	for id in missions:
		var path := Battle.map_path(str(id))
		check(path != "" and path != "res://data/rescue.json", "campaign resolves " + str(id))
		check(not unique.has(path), "unique mission map " + str(id)); unique[path] = true; paths.append(path)
	paths.append_array(manifest.web_variants)
	for path in paths:
		var m = Mission.new(11,str(path))
		var signature: String = "\n".join(m.board)
		check(not geometry.has(signature),"distinct geometry: " + str(m.spec.id)); geometry[signature] = true
		var report := Validator.validate(m)
		check(report.ok, "%s: %s" % [m.spec.id,report.errors])
		families[m.spec.family] = true
		print("MAP %s %dx%d routes=%d cover=%s high=%d sight=%d/%d" % [m.spec.id,m.spec.width,m.spec.height,report.routes,report.cover,report.high,report.long_sight,report.blocked_sight])
	check(Maps.layouts("archive").size() == 5,"archive selects own plot plus all four web variants")
	check(Maps.select_layout("archive",3) == Maps.select_layout("archive",3),"seeded layout selection reproducible")
	check(Maps.read(Maps.select_layout("archive",1)).web_source.base == "archive","selected web variant belongs to mission")
	for f in ["rescue","vip_extract","hack_terminal","destroy_relay","defend","retaliation","sabotage","ambush","operation"]: check(families.has(f),"family represented: "+f)
	_validation_failures()
	_rules()
	_operations()
	_hacks_and_swarm()
	_fronts()
	await _assets()
	print("MISSIONS RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)

func mission(id: String) -> RefCounted:
	return Mission.new(17,Maps.resolve(id) if not id.begins_with("web_") else "res://data/maps/%s.json" % id)

func adjacent(m: RefCounted, u: Dictionary, p: Vector2i) -> void:
	for d in Shot.DIRS:
		if m.passable(p+d) and not m.occupied(p+d,int(u.id)):
			u.x = p.x+d.x; u.y = p.y+d.y; u.ap = 2; return
	check(false,"objective has an interaction tile")

func extract(m: RefCounted) -> void:
	var squad: Array = m.living("player")
	for i in squad.size(): squad[i].x = m.spec.evac[i][0]; squad[i].y = m.spec.evac[i][1]
	if m.spec.family in ["rescue","vip_extract"]: m.prisoner.x = m.spec.evac[0][0]; m.prisoner.y = m.spec.evac[0][1]
	m._check_win()

func _rules() -> void:
	check(Battle.map_path("unknown") == "","unknown id cannot silently select rescue")
	for id in ["rescue","escort","envoy","sabotage","dock","h_valo"]:
		var m = mission(id); var u: Dictionary = m.living("player")[0]
		var before := int(u.ap)
		check(not m.interact(u,Vector2i(-1,-1)).ok and int(u.ap) == before,id+" invalid interaction free")
		if not m.interactables().is_empty():
			var p: Vector2i = m.interactables()[0]
			check(not m.interact(u,p).ok,id+" distant interaction rejected")
			adjacent(m,u,p); var copy := u.duplicate(true)
			check(not m.interact(copy,p).ok,id+" foreign actor rejected")
			u.ap = 0; check(not m.interact(u,p).ok,id+" no AP rejected"); u.ap = 2
			m.phase = "enemy"; check(not m.interact(u,p).ok,id+" enemy phase rejected"); m.phase = "player"
			var response: Dictionary = m.interact(u,p)
			check(response.ok and int(u.ap) == 1,id+" interact spends exactly one AP")
			if id != "dock": check(not m.interact(u,p).ok,id+" cannot repeat completed objective")
		var safety := 0
		while m.objective_state.phase == "primary" and not m.interactables().is_empty() and safety < 10:
			safety += 1
			var p: Vector2i = m.interactables()[0]; adjacent(m,u,p); m.interact(u,p)
		m._check_win()
		check(m.result == "" and m.objective_state.phase == "evac",id+" primary leads to evacuation, not instant win")
		if id == "envoy" and not m.interactables().is_empty():
			var bonus_tile: Vector2i = m.interactables()[0]; adjacent(m,u,bonus_tile); m.interact(u,bonus_tile)
			check(m.objective_state.done.size() == 3,"optional third terminal remains available during evac")
		extract(m); check(m.result == "win",id+" family can finish")
		check(int(m.metrics.objective_turn) > 0 and int(m.metrics.evac_turn) > 0,id+" objective and evac telemetry")
	var recon = mission("sabotage")
	recon.units = recon.units.filter(func(u): return u.side == "player")
	var scout: Dictionary = recon.living("player")[2]
	for offset in [1,2,3,4,5]: recon.set_tile(Shot.pos(scout)+Vector2i(0,-offset),".")
	recon._spawn("trooper",int(scout.x),int(scout.y)-5,0)
	var patrol: Dictionary = recon.units[-1]; recon._wake_groups()
	check(patrol.spotted and not patrol.awake,"concealed squad can scout a pod without activating it")
	recon.break_concealment("test"); recon._wake_groups()
	check(patrol.awake,"revealed squad activates the visible pod")
	var attacker_mission = mission("sabotage")
	var shooter: Dictionary = attacker_mission.living("player")[2]
	for offset in [1,2,3]: attacker_mission.set_tile(Shot.pos(shooter)+Vector2i(0,-offset),".")
	attacker_mission._spawn("trooper",int(shooter.x),int(shooter.y)-3,90)
	check(attacker_mission.shot(int(shooter.id),int(attacker_mission.units[-1].id)) and not bool(shooter.concealed) and attacker_mission.objective_state.clock_start == 1,"attack reveals squad and starts concealment clock")
	var timed = mission("envoy")
	timed.turn = int(timed.spec.turn_limit)+1; Objectives.player_start(timed)
	check(timed.result == "loss","hack mission deadline fails")
	var hidden = mission("sabotage")
	hidden.turn = 20; Objectives.player_start(hidden)
	check(hidden.result == "" and hidden.objective_state.clock_start == 0,"concealment clock waits for reveal")
	hidden.break_concealment("test")
	check(hidden.objective_state.clock_start == 20 and hidden.living("player").all(func(u): return not u.concealed),"reveal starts clock and clears squad flags")
	hidden.turn = 30; Objectives.player_start(hidden); check(hidden.result == "loss","sabotage expires from reveal")
	var defense = mission("relay")
	defense.turn = 200; Objectives.player_start(defense); check(defense.result == "","defense has no global timer")
	defense.damage_objective(99); check(defense.result == "loss","defense relay loss fails")
	defense = mission("relay")
	for turn in [2,4,6,8]: defense.turn = turn; Pressure.player_start(defense)
	check(defense.pressure_state.waves == 4,"four defense waves queued")
	var sizes: Array = defense.pressure_state.pending.map(func(w): return w.kinds.size())
	# Previous waves landed on later calls; final wave remains largest.
	check(sizes[-1] == 5 and defense.living("enemy").size() > 6,"defense waves escalate")
	var pods := {}
	for enemy in defense.living("enemy"):
		if int(enemy.group) >= 1000: pods[enemy.group] = int(pods.get(enemy.group,0))+1
	check(pods.values().all(func(n): return n <= 2),"reinforcement pods fit the smallest difficulty active cap")
	defense.units = defense.units.filter(func(u): return u.side == "player")
	Objectives.enemy_end(defense); check(defense.objective_state.phase == "primary","defense waits for announced wave")
	defense.pressure_state.pending.clear(); Objectives.enemy_end(defense)
	check(defense.objective_state.phase == "evac","defense final clear leads to evac")
	extract(defense); check(defense.result == "win","defense extracts")
	var raid = mission("h_valo")
	raid.objective_state.lost = 3; raid._check_win(); check(raid.result == "loss","retaliation impossible quota fails")
	var escort = mission("escort")
	escort.prisoner.hp = 0; escort._check_win(); check(escort.result == "loss","VIP loss fails")
	escort = mission("escort")
	check(abs(int(escort.spec.evac[0][1])-int(escort.prisoner.y)) > 15,"VIP evac requires crossing the map")
	var attacker: Dictionary = escort.living("enemy")[0]
	adjacent(escort,attacker,Shot.pos(escort.prisoner)); attacker.awake = true
	Objectives.enemy_end(escort); check(int(escort.prisoner.hp) == 6,"exposed evacuee takes real incoming damage")
	var wave = mission("rescue")
	wave.queue_reinforcement(["trooper"],1,"test")
	var incoming: Dictionary = wave.pressure_state.pending[0].duplicate(true)
	var count: int = wave.units.size(); Pressure.player_start(wave)
	check(wave.units.size() == count and incoming.turn == incoming.announced+1,"lane announced exactly one turn ahead")
	wave.turn += 1; Pressure.player_start(wave)
	check(wave.units.size() == count+1 and wave.pressure_state.pending.is_empty(),"announced wave lands next turn")
	var previous := int(wave.pressure_state.last_entry); wave.queue_reinforcement(["heavy"],1)
	check(int(wave.pressure_state.last_entry) != previous,"inbound lanes rotate away from previous entry")
	var staged = mission("rescue")
	var first: Dictionary = staged.spec.groups[0][0].duplicate() if staged.spec.groups[0][0] is Dictionary else {}
	check(first.is_empty() and staged.spec.groups[0][0][2] > staged.spec.objective.points[0][1]+6,"objective lies beyond first contact")

func _operations() -> void:
	var m = mission("web_antenna_ridge")
	var u: Dictionary = m.living("player")[0]; var p := Maps.point(m.spec.operation[0].at)
	u.x = p.x; u.y = p.y; m._check_win()
	check(m.objective_state.step == 1,"reach advances to hold")
	m.units = m.units.filter(func(member): return member.side == "player")
	m._spawn("trooper",p.x+1,p.y,80)
	Objectives.enemy_end(m); check(m.objective_state.held == 0,"contested hold does not progress")
	m.units = m.units.filter(func(member): return member.side == "player")
	Objectives.enemy_end(m); check(m.objective_state.held == 1,"hold ticks once at enemy phase end")
	Objectives.enemy_end(m); check(m.objective_state.phase == "evac","hold completes into extract")
	extract(m); check(m.result == "win","operation extract wins")
	var chase = mission("web_rooftop_chase")
	var runner: Dictionary = chase.unit_by_id(int(chase.objective_state.runner_id))
	runner.stunned = true; chase._check_win()
	check(chase.objective_state.phase == "evac","stunning courier completes chase")
	var ambush = mission("adraasHunt")
	runner = ambush.unit_by_id(int(ambush.objective_state.runner_id))
	runner.x = runner.runner_exit[0]; runner.y = runner.runner_exit[1]; runner.ap = 2; ambush.phase = "enemy"
	Objectives.runner_turn(ambush,runner)
	check(ambush.result == "loss","runner reaches exit: ambush fails")
	ambush = mission("adraasHunt")
	runner = ambush.unit_by_id(int(ambush.objective_state.runner_id))
	ambush.apply_damage(runner,999,ambush.living("player")[0]); check(ambush.objective_state.phase == "evac","courier kill starts evac")

func _hacks_and_swarm() -> void:
	var m = mission("envoy"); var u: Dictionary = m.living("player")[4]
	var p := Shot.pos(u)+Vector2i(0,-2); m.set_tile(p,"k")
	var options := Hack.options(m,u,p)
	check(options.safe == 95 and options.risky == 55,"Medic hack bonus and safe cap")
	var before := int(u.ap); var outcome: Dictionary = m.hack(u,p,"safe")
	check(outcome.ok and int(u.ap) == before-1,"hack spends one action")
	check(not m.hack(u,p,"safe").ok,"console reward cannot be farmed")
	check(m.objective_state.done.is_empty(),"optional reward failure cannot consume required terminal")
	var seed_found := false
	for seed_value in range(1,20):
		var test = mission("envoy"); test.rng.seed = seed_value
		var actor: Dictionary = test.living("player")[0]; var at := Shot.pos(actor)+Vector2i(0,-2); test.set_tile(at,"k")
		var result: Dictionary = test.hack(actor,at,"risky")
		if not result.success:
			check(test.pressure_state.pending[0].turn == test.turn+2,"risky alarm has two-turn delay"); seed_found = true; break
	check(seed_found,"deterministic failed hack covered")
	m = mission("rescue"); u = m.living("player")[2]
	m.units = m.units.filter(func(member): return member.side == "player")
	m._spawn("trooper",int(u.x),int(u.y)-2,0); var droid: Dictionary = m.units[-1]; droid.droid = true; droid.controlled_until = m.turn+1
	m._spawn("trooper",int(u.x)+2,int(u.y)-2,1); var target: Dictionary = m.units[-1]
	droid.aim = 200; droid.ap = 2; m.phase = "enemy"
	var hp := int(target.hp); Hack.controlled_turn(m,droid)
	check(droid.side == "enemy" and not droid.has("controlled_until") and int(target.hp) < hp,"controlled droid attacks an enemy then restores allegiance")
	droid.aim = 80; droid.hack_aim_until = 3; m.turn = 3; Hack.player_start(m)
	check(droid.aim == 60 and not droid.has("hack_aim_until"),"droid overclock expires exactly once")
	var swarm = mission("shrine"); swarm.turn = 2
	Pressure.brood(swarm)
	check(swarm.living("enemy").filter(func(e): return bool(e.get("swarm",false))).is_empty(),"dormant horrors do not brood")
	for e in swarm.living("enemy"):
		if bool(e.get("horror",false)): e.awake = true
	Pressure.brood(swarm)
	check(swarm.living("enemy").filter(func(e): return bool(e.get("swarm",false))).size() == 2,"brood creates two husks")
	Pressure.brood(swarm)
	check(swarm.living("enemy").filter(func(e): return bool(e.get("swarm",false))).size() == 2,"brood once per turn")
	for turn in [4,6,8]: swarm.turn = turn; Pressure.brood(swarm)
	check(swarm.living("enemy").filter(func(e): return bool(e.get("swarm",false))).size() == 6,"swarm cap six")
	var horror: Dictionary = swarm.living("enemy").filter(func(e): return bool(e.get("horror",false)) and not bool(e.get("swarm",false)))[0]
	swarm.pressure_state.calm_turn = swarm.turn
	Pressure.on_kill(swarm,horror,swarm.living("player")[0]); check(swarm.pressure_state.chain_count == 0,"calm blocks kill surge")
	swarm.pressure_state.calm_turn = 0
	for i in 4: Pressure.on_kill(swarm,horror,swarm.living("player")[0])
	check(swarm.pressure_state.chain_count == 2,"swarm kill chains capped at two per turn")
	var troops: Array = swarm.living("player").filter(func(a): return a.class_name not in ["Guardian","Consular"])
	var husk: Dictionary = swarm.living("enemy").filter(func(e): return bool(e.get("swarm",false)))[0]
	swarm.units = swarm.units.filter(func(a): return a.side == "enemy" or a.class_name not in ["Guardian","Consular"])
	var health: Array = troops.map(func(a): return a.hp)
	Pressure.horror_turn(swarm,husk); check(troops.map(func(a): return a.hp) == health,"troops screen Jedi-only horrors")
	check(swarm.apply_damage(troops[0],99,husk) == 0,"horror immunity enforced in damage contract")

func _fronts() -> void:
	var plan := [{"crises":["a","b"]},{"story":"x"},{"crises":["a","b"]},{"crises":["a","b"]}]
	var state := {"era":2,"step":2,"wings":{},"roster":[],"options":[{"mission":"a","crisis":"a","adv":true},{"mission":"b","crisis":"b","adv":true}],"pending_mission":{}}
	for i in 10: state.roster.append({"id":"u%d" % i,"cls":"Soldier","status":"active","rank":2,"xp":0,"wound":0,"assign":""})
	check(Fronts.late_steps(plan) == [2,3] and Fronts.available(state,plan),"two fronts available on last two crisis steps")
	check(Fronts.launch(state,state.options[0],["u0","u1","u2","u3","u4","u5"],plan).defer_ignored,"front A defers ignored crises")
	var receipt := Fronts.finish(state)
	check(not receipt.advance and state.twin.stage == "b" and state.step == 2,"front A opens B without advancing time")
	check(not Fronts.finish(state).advance and state.twin.stage == "b","replayed front A settlement cannot advance time")
	check(not Fronts.launch(state,state.options[0],["u0","u7"],plan).ok,"front B excludes A soldiers")
	var roundtrip: Dictionary = JSON.parse_string(JSON.stringify(state))
	check(Fronts.squad_rule(roundtrip).max == 4 and Fronts.free_roster(roundtrip).size() == 4,"two-front state survives save roundtrip")
	var random := RandomNumberGenerator.new(); random.seed = 5
	receipt = Fronts.auto_resolve(state,0,["u6","u7","u8","u9"],random)
	check(receipt.ok and receipt.advance and receipt.odds == 70 and not state.has("twin"),"auto-resolution settles once with capped odds")
	check(not Fronts.auto_resolve(state,0,["u6","u7"],random).ok,"cannot replay auto rewards")
	state = roundtrip
	check(Fronts.stand_down(state).ignored.size() == 1 and not state.has("twin"),"standing down settles remaining crises")

func _assets() -> void:
	var renderer := Presentation.new(); root.add_child(renderer)
	check(renderer.themes.size() == 8,"eight web theme palettes")
	for file in DirAccess.get_files_at("res://assets/maps"):
		if file.ends_with(".glb"): check(load("res://assets/maps/"+file) is PackedScene,"prop import "+file)
	var m = mission("envoy"); var u: Dictionary = m.living("player")[2]; u.overwatch = true
	var zones := renderer.overwatch_zones(m)
	check(not zones.is_empty(),"overwatch yields visible tiles")
	for zone in zones: check(m.passable(zone.at) and Shot.los(m,Shot.pos(u),zone.at),"overwatch zone obeys LOS and walkability")
	renderer.queue_free(); await process_frame

func _validation_failures() -> void:
	var narrow := ["#######","#..#..#","#.....#","#..#..#","#######"]
	var disconnected := ["#######","#..#..#","#..#..#","#######"]
	check(not Validator.topology(narrow).cuts.is_empty(),"validator rejects a bridge chokepoint")
	check(Validator.topology(disconnected).components == 2,"validator finds disconnected rooms")
	check(Validator.path(narrow,Vector2i(1,1),Vector2i(5,1),3).is_empty(),"narrow endpoint cannot count as wide route")
	var m = mission("rescue")
	m.spec.route_validation.via = [m.spec.route_validation.via[0],m.spec.route_validation.via[0]]
	check(not Validator.validate(m).ok,"duplicated lane cannot count twice")

	var water = mission("rescue")
	water.set_tile(Vector2i(3,3),"w")
	check(not water.passable(Vector2i(3,3)) and Shot.los(water,Vector2i(2,3),Vector2i(4,3)),"deep water blocks movement but not sight")
