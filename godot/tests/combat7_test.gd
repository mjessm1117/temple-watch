extends SceneTree
const Mission = preload("res://scripts/combat_mission.gd")
const Base = preload("res://scripts/mission.gd")
const Shot = preload("res://scripts/shot.gd")
const Ability = preload("res://scripts/abilities_engine.gd")
const AI = preload("res://scripts/ai.gd")
const Concealment = preload("res://scripts/combat_concealment.gd")
const Bonds = preload("res://scripts/combat_bonds.gd")
const Bot = preload("res://tests/loop_bot.gd")
const Settings = preload("res://scripts/settings.gd")
var checks := 0
var failures := 0

class ObjectiveMission extends "res://scripts/combat_mission.gd":
	var used := false
	func interactables() -> Array[Vector2i]: return [] if used else [Vector2i(3, 2)]
	func interact(_unit: Dictionary, tile_value: Vector2i) -> Dictionary:
		if tile_value != Vector2i(3, 2): return {"ok":false}
		used = true
		return {"ok":true}

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func arena(seed_value: int = 1) -> RefCounted:
	var m := Mission.adopt(Base.new(seed_value))
	for y in range(1, 25):
		for x in range(1, 25): m.set_tile(Vector2i(x,y), "_")
	var squad: Array = m.living("player")
	var enemy: Dictionary = m.living("enemy")[0]
	m.units.assign([squad[0], squad[1], squad[2], squad[3], enemy])
	for i in range(4): m.units[i].x = 2; m.units[i].y = 2 + i * 2
	enemy.x = 6; enemy.y = 6; enemy.awake = true; enemy.hp = 100; enemy.max_hp = 100
	return m

func run() -> void:
	Settings.difficulty = "normal"
	rules()
	ghost_rules()
	abilities()
	effect_families()
	await presentation()
	if "--bots" in OS.get_cmdline_user_args(): bots()
	print("COMBAT7 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func rules() -> void:
	var m := arena()
	var shooter: Dictionary = m.units[2]
	var enemy: Dictionary = m.units[4]
	shooter.ammo = 1
	check(m.shot(int(shooter.id), int(enemy.id)), "loaded weapon fires")
	check(int(shooter.ammo) == 0, "shot consumes one round")
	shooter.ap = 3
	var rng_state: int = m.rng.state
	check(not m.shot(int(shooter.id), int(enemy.id)) and int(shooter.ap) == 3 and m.rng.state == rng_state, "empty weapon rejects without AP or RNG changes")
	check(not m.overwatch(int(shooter.id)), "empty weapon cannot overwatch")
	check(m.use_ability(int(shooter.id), "reload") and int(shooter.ap) == 2 and int(shooter.ammo) == 4, "reload costs one AP and fills clip")
	check(not m.use_ability(int(shooter.id), "reload"), "full clip cannot waste reload")
	var info := Shot.calculate(m, shooter, enemy)
	var armor := int(enemy.get("armor",0)); enemy.armor = 2
	var preview := Shot.damage_preview(shooter, enemy)
	check(preview.normal == [1,4] and preview.critical == [3,6] and preview.graze == [1,1], "normal crit graze bands include armor")
	var force_hit := info.duplicate(); force_hit.hit = 100; force_hit.crit = 0
	m._apply_attack(shooter, enemy, force_hit, "shoot")
	check(int(enemy.armor) == 1 and int(m.action_events.back().armor_lost) == 1, "hit shreds armor and event reports actual shred")
	force_hit.hit = 0
	var grazed := false
	for i in range(100):
		shooter.ammo = 4; enemy.armor = 0
		m._apply_attack(shooter, enemy, force_hit, "shoot")
		if m.action_events.back().outcome == "grazes": grazed = true; break
	check(grazed, "graze branch resolves and reports a graze")
	enemy.armor = armor
	m.set_tile(Vector2i(5,6), "c")
	check(int(Shot.calculate(m, shooter, enemy).cover) == 20, "half cover costs 20 aim")
	m.set_tile(Vector2i(5,6), "#")
	check(int(Shot.calculate(m, shooter, enemy).cover) == 40, "full cover costs 40 aim")
	shooter.x = 9
	check(bool(Shot.calculate(m, shooter, enemy).flanked), "opposite side removes directional cover and flanks")
	enemy.hunkered = true
	check(int(Shot.calculate(m, shooter, enemy).crit) == 0, "hunker blocks flank crit")
	for y in range(1,25): m.set_tile(Vector2i(4,y), "#")
	var trace := Shot.trace(m, Vector2i(2,2), Vector2i(6,2))
	check(not bool(trace.clear) and trace.blocker == Vector2i(4,2) and not Shot.los(m, Vector2i(2,2), Vector2i(6,2)), "blocked world trace uses the same LOS blocker")
	m = arena(); shooter = m.units[2]; enemy = m.units[4]
	m.defer_resolution = true
	var hp := int(enemy.hp)
	check(m.shot(int(shooter.id), int(enemy.id)) and int(enemy.hp) == hp and m.action_events.back().kind == "intent", "live attack defers damage until camera arrival")
	var event: Dictionary = m.action_events.pop_back(); event.info.hit = 100; event.info.crit = 0
	check(not m.resolve_intent(event).is_empty() and int(enemy.hp) < hp, "camera-ready intent resolves exactly once")
	m = arena(); m.spec.concealed = true; m.setup_combat(); enemy = m.units[4]; enemy.awake = false
	Concealment.observe(m)
	check(m.squad_concealed and bool(m.units[0].concealed) and not bool(enemy.awake), "mission flag conceals squad without activating patrol")
	check(not Concealment.detection_tiles(m).is_empty(), "spotted patrol has visible detection tiles")
	shooter = m.units[2]; shooter.overwatch = true
	Concealment.break_squad(m, m.units[0])
	check(not m.squad_concealed and not bool(shooter.concealed) and bool(enemy.awake), "breaking concealment activates ambush")
	check(m.action_events.any(func(e): return bool(e.get("reaction",false))), "prepared overwatch fires during ambush")
	m = arena(); shooter = m.units[2]; enemy = m.units[4]; shooter.overwatch = true
	enemy.combat_route = [Vector2i(5,6),Vector2i(18,6)]; enemy.x = 18
	m._reaction_fire(enemy)
	check(not bool(shooter.overwatch) and m.action_events.back().to == Vector2i(5,6), "overwatch triggers on first exposed route tile")
	m = arena(); enemy = m.units[4]; enemy.range = 1.5; enemy.x = 3; enemy.y = 3
	check(str(AI.choose_target(m, enemy).class_name) in ["Guardian","Consular"], "melee Sith prioritizes Jedi")
	m.units[0].x = 2; m.units[0].y = 5; m.units[1].x = 2; m.units[1].y = 7
	enemy.range = 8; enemy.x = 6; enemy.y = 6
	var first := AI.choose_target(m,enemy)
	check(int(AI.choose_target(m,enemy,{int(first.id):2}).id) != int(first.id), "AI spreads repeat attacks when alternatives exist")

func ghost_rules() -> void:
	var m := arena(); var scout: Dictionary=m.units[3]; var enemy: Dictionary=m.units[4]
	enemy.hp=1
	m._apply_attack(scout,enemy,{"hit":100,"crit":0},"shoot")
	check(bool(scout.get("concealed",false)), "Ghost reconceals after the killing shot breaks attack concealment")
	var ally: Dictionary=m.units[2]; ally.concealed=true
	Concealment.break_squad(m,scout)
	check(not bool(scout.concealed) and bool(ally.concealed), "individual reconcealment does not reveal another hidden ally")

func abilities() -> void:
	var m := arena()
	var u: Dictionary = m.units[0]
	var t: Dictionary = m.units[4]
	u.focus_left = 20; u.focus = 20
	t.x = 5; t.y = 2
	m.set_tile(Vector2i(4,2),"c")
	# Pull collision damages the obstacle and the victim.
	var hp := int(t.hp)
	m.abilities.pull.chance = 100
	check(m.use_ability(int(u.id),"pull",int(t.id)), "Pull is available to Jedi")
	check(m.tile(Vector2i(4,2)) == "r" and int(t.hp) == hp-2, "Pull collision destroys half cover")
	m.set_tile(Vector2i(3,2),"#")
	check(m.use_ability(int(u.id),"breach",-1,Vector2i(3,2)) and m.tile(Vector2i(3,2)) == "r", "saber breach opens a full wall")
	u.ap = 3; m.set_tile(Vector2i(0,2),"#")
	check(Vector2i(0,2) not in Ability.tiles(m,u,"breach"), "breach cannot destroy map boundaries")
	check(m.ability_reason(int(u.id),"interact") != "", "Interact is defensive until missions contract exists")
	var obj := ObjectiveMission.new(); obj.setup_combat(); var actor: Dictionary = obj.units[0]; actor.x = 2; actor.y = 2
	check(obj.use_ability(int(actor.id),"interact",-1,Vector2i(3,2)) and obj.used and int(actor.ap)==2, "Interact invokes mission contract for exactly one AP")
	check(not obj.use_ability(int(actor.id),"interact",-1,Vector2i(3,2)), "completed objective cannot be used twice")
	m = arena(); u = m.units[2]; var partner: Dictionary = m.units[3]
	u.rid = "a"; partner.rid = "b"
	Bonds.setup(m,{"bonds":{"a|b":{"lvl":4,"dr":[],"n":0}}})
	partner.ap = 0; partner.stunned = true
	check(m.use_ability(int(u.id),"bondAid",int(partner.id)) and int(partner.ap)==1 and not partner.has("stunned"), "legacy bond provides AP aid and clears conditions")
	u.ap = 3
	check(not m.use_ability(int(u.id),"bondAid",int(partner.id)), "bond aid has one shared charge per mission")
	check(m.use_ability(int(u.id),"bondStrike",int(m.units[4].id)), "level four legacy bond grants crossfire")
	check(not m.use_ability(int(u.id),"bondStrike",int(m.units[4].id)), "bond crossfire cannot repeat")
	# Every web ability identifier is represented. Specialized effects are exercised below.
	for id in ["grenade","stabilize","liftUp","door","console","plant","sense","executioner","shadowStep","pathfinder","wildBond","beastCalm","pull","ionNade","holdLine","disarm","flurry","mightyBlow","precisionStrike","massHeal","forceWave","stasisField","tremor","chainShot","medBeacon","backup","coverFire","handoff","moSurge","moRally","moStrike","snipe","barrage","shieldWall","taunt","fanFire","shredder"]:
		check(m.abilities.has(id), "web ability coverage: " + id)
	m = arena(); u = m.units[0]; t = m.units[4]; u.kit.append("grenade"); u.grenades=1
	t.x=3; t.y=2; m.set_tile(Vector2i(3,3),"c")
	check(m.use_ability(int(u.id),"grenade",-1,Vector2i(3,2)) and int(u.grenades)==0 and int(u.hp)<int(u.max_hp) and m.tile(Vector2i(3,3))=="r", "grenade has charges friendly fire and cover destruction")
	m = arena(); u=m.units[0]; t=m.units[4]; u.kit.append("disarm"); u.focus_left=10
	t.x=5; t.y=2; m.abilities.disarm.chance=100
	check(m.use_ability(int(u.id),"disarm",int(t.id)) and bool(t.get("disarmed",false)), "disarm applies")
	m.phase="enemy"; t.ap=3
	check(not m.shot(int(t.id),int(u.id)), "disarm prevents enemy weapon fire")

func effect_families() -> void:
	for id in ["flurry","mightyBlow","precisionStrike","chainShot","snipe","fanFire"]:
		var m := arena(); var u: Dictionary=m.units[2]; var t: Dictionary=m.units[4]
		u.kit.append(id); u.focus_left=20; u.ammo=4; t.x=3; t.y=6
		m.abilities[id].chance=100
		var hp := int(t.hp)
		check(m.use_ability(int(u.id),id,int(t.id)) and int(t.hp)<hp, id+" resolves its attack")
		check(int(u.ammo)==4-int(m.abilities[id].get("ammo_cost",0)), id+" spends declared ammunition")
	for id in ["massHeal","medBeacon"]:
		var m := arena(); var u: Dictionary=m.units[0]; var t: Dictionary=m.units[1]
		u.kit.append(id); u.focus_left=20; t.hp=1
		check(m.use_ability(int(u.id),id) and int(t.hp)==3, id+" heals nearby allies")
	var m := arena(); var u: Dictionary=m.units[0]; var t: Dictionary=m.units[4]
	u.kit.append_array(["shadowStep","stabilize","forceWave","stasisField","root","beastCalm"]); u.focus_left=30
	check(m.use_ability(int(u.id),"shadowStep",-1,Vector2i(3,2)) and bool(u.concealed) and int(u.leap_aim)==20, "Shadow Step grants concealment and strike aim")
	u.ap=3; m.units[1].hp=0; m.units[1].status="down"; m.units[1].x=3; m.units[1].y=3
	check(m.use_ability(int(u.id),"stabilize",int(m.units[1].id)) and bool(m.units[1].stable), "Stabilize records a stable downed ally")
	for id in ["forceWave","stasisField","root","beastCalm"]:
		u.ap=3; t.x=5; t.y=2; t.tags=["creature"]; t.erase("stunned"); m.abilities[id].chance=100
		check(m.use_ability(int(u.id),id,int(t.id)) and bool(t.get("rooted" if id=="root" else "stunned",false)), id+" applies its control effect")
	m.phase="enemy"; t.ap=3
	check(not m.move(int(t.id),Vector2i(6,2)), "rooted enemy cannot move")
	m.turn=2; m.tick_combat_status()
	check(not bool(t.get("rooted",false)), "root expires at the next player turn")
	m=arena(); u=m.units[2]; t=m.units[3]; t.ap=0
	check(m.use_ability(int(u.id),"handoff",int(t.id)) and int(t.ap)==1, "Hand Off transfers one AP")
	check(not m.use_ability(int(u.id),"handoff",int(t.id)), "Hand Off cannot repeat this turn")
	m.momentum=10; u.ap=0
	check(m.use_ability(int(u.id),"moSurge") and int(u.ap)==1 and m.momentum==7, "Surge spends three momentum for one AP")
	check(m.use_ability(int(u.id),"moRally") and m.momentum==2 and int(t.buff_aim)==10, "Momentum Rally uses web cost and aim bonus")
	m=arena(); u=m.units[2]; t=m.units[4]
	check(m.use_ability(int(u.id),"backup",int(t.id)) and int(m.units[3].ammo)==3, "Backup uses a real ally's ammunition")
	check(not m.use_ability(int(u.id),"backup",int(t.id)), "Backup shared squad limit prevents repeats")
	u.kit.append("holdLine"); u.ap=3
	check(m.use_ability(int(u.id),"holdLine") and bool(u.hold_line), "Hold the Line arms multiple reactions")
	m._reaction_fire(t); var ammo:=int(u.ammo); m._reaction_fire(t)
	check(int(u.ammo)==ammo, "Hold the Line only shoots a given mover once")
	m=arena(); u=m.units[2]; t=m.units[4]; u.kit.append("ionNade"); t.droid=true; t.x=4; t.y=6
	m.set_tile(Vector2i(4,5),"c"); var hp:=int(t.hp)
	check(m.use_ability(int(u.id),"ionNade",-1,Vector2i(4,6)) and int(t.hp)==hp-4 and bool(t.stunned) and m.tile(Vector2i(4,5))=="c", "Ion grenade stuns droids and preserves cover")
	m=arena(); u=m.units[2]; u.kit.append_array(["shieldWall","taunt"])
	check(m.use_ability(int(u.id),"shieldWall") and int(u.buff_defense)==20, "Shield Wall applies defense")
	check(m.use_ability(int(u.id),"taunt") and bool(u.taunt), "Draw Fire marks the actor as a preferred target")

func presentation() -> void:
	var packed = load("res://scenes/rescue.tscn")
	var game = packed.instantiate(); root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.animate_headless = true
	var shooter: Dictionary = game.mission.living("player")[2]
	var enemy: Dictionary = game.mission.living("enemy")[0]
	for y in range(18,24):
		for x in range(2,13): game.mission.set_tile(Vector2i(x,y),"_")
	enemy.x=8; enemy.y=22; enemy.awake=true; enemy.hp=30; enemy.max_hp=30
	game.selected_id=int(shooter.id); game._refresh()
	var hp := int(enemy.hp); var ammo := int(shooter.ammo)
	game._attack(int(enemy.id),"shoot")
	check(game.player_attack_pending and int(shooter.ammo)==ammo and int(enemy.hp)==hp, "camera begins before spending ammo or revealing damage")
	await create_timer(0.2).timeout
	check(int(shooter.ammo)==ammo, "blend still gates shot at 0.2 seconds")
	game._skip_activity()
	while game.player_attack_pending: await process_frame
	check(int(shooter.ammo)==ammo-1 and not game.cinematic, "skipping resolves one shot and restores camera")
	check(game.cam.trace.find("camera_skipped") < game.cam.trace.find("resolve_%d" % int(shooter.id)), "skip precedes resolution in timeline")
	shooter.ap=3; game.selected_id=int(shooter.id); game.cam.trace.clear()
	var started := Time.get_ticks_msec()
	await game._attack(int(enemy.id),"shoot")
	check(Time.get_ticks_msec()-started >= 600 and game.cam.trace.find("camera_ready") < game.cam.trace.find("resolve_%d" % int(shooter.id)), "full 0.6-second blend arrives before resolution")
	game.action_camera=false
	game.cam.trace.clear()
	game._end_turn()
	game._skip_activity()
	while game.playing_enemy_events: await process_frame
	check(game.mission.phase=="player" or game.mission.result!="", "skipped enemy timeline completes all logic")
	var last_actor := ""
	var last_resolve := -1
	for i in range(game.cam.trace.size()):
		var beat: String = game.cam.trace[i]
		if beat.begins_with("actor_"):
			if last_resolve >= 0: check(game.cam.trace.slice(last_resolve,i).any(func(item): return item.begins_with("impact_")), "next enemy waits for preceding impact")
			last_actor=beat; last_resolve=-1
		if beat.begins_with("resolve_") and last_actor!="": last_resolve=i
	game.mission = arena(7)
	var next_enemy: Dictionary = game.mission.units[4].duplicate(true)
	next_enemy.id=100; next_enemy.x=7; next_enemy.y=7; next_enemy.awake=true
	game.mission.units.append(next_enemy)
	for u in game.mission.units: u.hp=100; u.max_hp=100
	game.action_camera=true; game.cam.trace.clear(); game._refresh()
	game._end_turn()
	check(game.playing_enemy_events and game.mission.turn==1 and "actor_100" not in game.cam.trace, "second enemy cannot decide while first camera is arriving")
	game._skip_activity()
	while game.playing_enemy_events: await process_frame
	var first_impact: int = game.cam.trace.find("impact_%d" % int(game.mission.units[4].id))
	check(first_impact >= 0 and game.cam.trace.find("actor_100") > first_impact, "first enemy impact completes before second enemy decision")
	game.queue_free(); await process_frame

func bots() -> void:
	for difficulty in ["story","normal","hard","legend"]:
		if OS.get_cmdline_user_args().has("--normal") and difficulty != "normal": continue
		if OS.get_cmdline_user_args().has("--hard") and difficulty != "hard": continue
		if OS.get_cmdline_user_args().has("--legend") and difficulty != "legend": continue
		Settings.difficulty=difficulty
		var wins:=0
		for seed_value in range(1,21):
			var m := Mission.adopt(Base.new(seed_value))
			var guard:=0
			while m.result=="" and guard<24:
				for u in m.living("player"):
					if u.has("ammo") and int(u.ammo)==0: m.use_ability(int(u.id),"reload")
				Bot._bot_turn(m); guard+=1
			if m.result=="win": wins+=1
			check(m.result!="", "%s bot %d terminates" % [difficulty,seed_value])
		print("combat7 bot %s: %d/20 wins" % [difficulty,wins])
		var low: int = {"story":14,"normal":9,"hard":4,"legend":1}[difficulty]
		var high: int = {"story":20,"normal":12,"hard":7,"legend":3}[difficulty]
		check(wins>=low and wins<=high, "%s combat band %d–%d got %d" % [difficulty,low,high,wins])
	Settings.difficulty="normal"
