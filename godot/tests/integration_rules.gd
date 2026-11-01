extends RefCounted
const Campaign = preload("res://scripts/campaign/state.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Fronts = preload("res://scripts/mission_fronts.gd")
const Shot = preload("res://scripts/shot.gd")

func launch(c, offer: Dictionary, seed_value: int = 3):
	c.state.options = [offer]
	c.select_mission(0)
	return Battle.create(c,seed_value)

func run(check: Callable) -> void:
	var c = Campaign.new("normal")
	c.state.strategy.squad_upgrades = 2
	c.state.pairs.u2 = "u1"
	c.soldier("u1").picks.append("flurry")
	c.soldier("u1").extra_picks.append("saberThrow")
	var m = launch(c,{"mission":"archive","map_variant":0})
	check.call(m.living("player").size() == 6,"six-unit bridge deployment")
	var tiles := {}
	for u in m.living("player"): tiles[Shot.pos(u)] = true
	check.call(tiles.size() == 6,"six distinct spawns")
	var master: Dictionary = m.living("player")[0]
	var student: Dictionary = m.living("player")[1]
	check.call("flurry" in master.kit and "saberThrow" in master.kit,"learned and training-center abilities reach combat")
	check.call(m.identity.aim(m,student) > 0,"nearby live mentor grants Padawan aim")
	student.x = 1; student.y = 1
	check.call(m.identity.aim(m,student) == 0,"distant mentor grants no aim")
	master.focus_left = 0; m.identity.kill(m,student)
	check.call(master.focus_left > 0,"Padawan kill restores mentor focus")
	master.hp = 0
	check.call(m.identity.aim(m,student) == 0,"downed mentor grants no aim")
	c = Campaign.new("normal")
	var offer: Dictionary = c.sith.offer("stronghold","Test stronghold","sabotage",{"rival_id":"korr"})
	m = launch(c,offer)
	var rival: Dictionary = m.unit_by_id(int(m.spec.rival_required))
	check.call(m.spec.family == "destroy_relay" and rival.name == "Lord Korr Vash","stronghold uses relay objective and named rival")
	m.damage_objective(999)
	check.call(m.objective_state.phase == "primary","stronghold cannot extract with guardian alive")
	m.apply_damage(rival,999,m.living("player")[0])
	check.call(m.objective_state.phase == "evac","destroyed focus and defeated guardian unlock extraction")
	for i in m.living("player").size():
		var at: Array = m.spec.evac[i]; m.living("player")[i].x = at[0]; m.living("player")[i].y = at[1]
	m._check_win()
	check.call(m.result == "win","stronghold requires actual evacuation")
	c.apply_mission_result(Battle.result(c,m))
	check.call(c.sith.s.rivals.korr.phase == "pursuit","real battle result advances rival arc")
	c = Campaign.new("normal")
	offer = c.sith.offer("retaliation","Sanctuary defense","shrine")
	m = launch(c,offer)
	check.call(m.spec.family == "retaliation" and m.objective_state.civilians.size() == 6,"Sith retaliation uses civilian family")
	c = Campaign.new("normal")
	c.sith.s.mods.append({"mod":{"squadAim":3,"enemyAim":4,"enemyHp":2,"extraEnemies":1},"left":2})
	m = launch(c,{"mission":"archive","map_variant":0})
	m.queue_reinforcement(["trooper"],1)
	check.call(m.pressure_state.pending[0].kinds.size() == 2,"Dark Event adds enemies to announced waves")
	var enemy_count: int = m.units.size(); m.turn += 1; m.Pressure.player_start(m)
	check.call(m.units.size() == enemy_count+2,"announced extra enemies arrive")
	var reinforcement: Dictionary = m.units[-1]
	check.call(reinforcement.hp == int(m.catalog.trooper.hp)+int(m.difficulty.enemy_hp)+2,"reinforcements carry Sith HP modifier")
	c.sith.s.jams.medical = 1
	check.call(not c.Modules.ready(c,"medical"),"Sith jam disables Temple module")
	c = Campaign.new("normal")
	c.soldier("u6").status = "captured"; c.soldier("u6").covert_captive = true; c.refresh_options()
	var rescue: Dictionary = c.state.options.filter(func(o): return o.get("hostages",[]).has("u6"))[0]
	c.state.options = [rescue]; c.select_mission(0)
	c.apply_mission_result({"mission_id":"rescue","win":true,"units":[]})
	check.call(c.soldier("u6").status == "active" and not c.soldier("u6").has("covert_captive"),"covert captive returns through rescue settlement")
	c = Campaign.new("normal")
	c.soldier("u6").status = "captured"; c.soldier("u6").sith_captor = "veyra"; c.soldier("u6").capT = 1
	c.advance_mission()
	check.call(c.soldier("u6").status == "captured","Sith captive never auto-releases")
	_rival_counters(check)
	_tactical_contracts(check)
	_two_fronts(check)

func _two_fronts(check: Callable) -> void:
	var c = Campaign.new("normal")
	c.state.era = 2; c._migrate()
	for i in range(7,11):
		var r: Dictionary = c.state.roster[-1].duplicate(true); r.id = "reserve%d" % i; r.assign = ""; r.wound = 0; r.fatigue = 0
		c.state.roster.append(r)
	var plan: Array = c.Integration.plan(c)
	c.state.step = Fronts.late_steps(plan)[-1]; c.refresh_options()
	check.call(Fronts.available(c.state,plan),"late crisis unlocks two fronts")
	var index := 0
	for i in c.state.options.size():
		if c.state.options[i].has("crisis") and c.state.options[i].get("adv",false): index = i; break
	var start_day := int(c.state.elapsed_days); var start_step := int(c.state.step)
	var first: Dictionary = c.select_mission(index)
	var used: Array = first.squad.duplicate()
	c.apply_mission_result({"mission_id":first.mission_id,"win":true,"units":[]})
	check.call(c.state.twin.stage == "b" and c.state.elapsed_days == start_day and c.state.step == start_step,"Front A settlement defers date and story step")
	check.call(c.select_mission(0,used).is_empty(),"Front A soldiers cannot redeploy on Front B")
	var second: Dictionary = c.select_mission(0,c.default_squad())
	check.call(not second.is_empty() and second.squad.size() <= 4 and second.fewer == 1,"Front B launches fresh smaller patrol mission")
	c.apply_mission_result({"mission_id":second.mission_id,"win":true,"units":[]})
	check.call(not c.state.has("twin") and c.state.step == start_step+1 and c.state.elapsed_days > start_day,"two fronts settle exactly one date and story step")

func _tactical_contracts(check: Callable) -> void:
	var c = Campaign.new("normal")
	c.soldier("u1").dark = 4
	var m = launch(c,{"mission":"archive","map_variant":0})
	var actor: Dictionary = m.living("player")[0]
	var ally: Dictionary = m.living("player")[1]
	actor.x = 4; actor.y = 4; ally.x = 5; ally.y = 4
	m.set_tile(Vector2i(4,4),"."); m.set_tile(Vector2i(5,4),".")
	for i in 2:
		actor.ap = 3; ally.hp = int(ally.max_hp)-4
		check.call(m.use_ability(int(actor.id),"medpac",int(ally.id)),"actual healing succeeds")
	check.call(m.mercy_events.size() == 2 and m.mercy_events[0].action_id != m.mercy_events[1].action_id,"verified mercy gets distinct action IDs")
	var result_id: String = c.state.pending_mission.result_id
	c.apply_mission_result(Battle.result(c,m))
	check.call(c.soldier("u1").dark == 3,"mercy applies after tactical Darkness copying")
	check.call(c.sith.mercy("u1",result_id,"action_1") == 0,"settled mercy cannot be credited twice")
	c = Campaign.new("normal")
	m = launch(c,{"mission":"archive","map_variant":0})
	actor = m.living("player")[0]
	var terminal: Vector2i = m.interactables()[0]
	actor.x = terminal.x-1; actor.y = terminal.y; actor.ap = 3
	var options: Dictionary = m.Hack.options(m,actor,terminal)
	check.call(not options.is_empty() and options.has("safe") and options.has("risky"),"objective terminal offers independent reward hacks")
	check.call(m.use_ability(int(actor.id),"rewardSafe",-1,terminal) and int(actor.ap) == 2 and m.objective_state.done.is_empty(),"reward hack spends one AP without copying primary terminal")
	check.call(m.living("enemy").any(func(u): return bool(u.get("droid",false))),"authored hack map contains a hackable security droid")
	var barrel := Vector2i(4,4)
	actor.x = 5; actor.y = 4
	m.set_tile(barrel,"c"); m.spec.prop_overrides[barrel] = "barrel"
	var hp := int(actor.hp); m.damage_cover(barrel,4)
	check.call(m.tile(barrel) == "r" and int(actor.hp) == hp-3,"destroyed barrel applies three-damage area blast")
	c = Campaign.new("normal")
	m = launch(c,{"mission":"dock","map_variant":0})
	actor = m.living("player")[2]
	var relay: Vector2i = m.interactables()[0]
	actor.x = relay.x-1; actor.y = relay.y; actor.ap = 3
	var ammo := int(actor.ammo); var integrity := int(m.objective_state.relay_hp)
	check.call(m.use_ability(int(actor.id),"relayAttack",-1,relay),"weapon can target relay")
	check.call(int(actor.ap) == 1 and int(actor.ammo) == ammo-1 and int(m.objective_state.relay_hp)<integrity,"relay weapon attack charges AP and ammo once")
	c = Campaign.new("normal")
	m = launch(c,{"mission":"rescue","map_variant":0})
	m.units = m.units.filter(func(u): return u.side == "player")
	actor = m.living("player")[0]
	var first: Vector2i = m.Maps.point(m.spec.evac[0])
	actor.x = first.x; actor.y = first.y
	m.prisoner.freed = true; m.prisoner.escort_id = actor.id; m.prisoner.x = first.x; m.prisoner.y = first.y-1
	m._civilian_advance()
	check.call(m.Objectives.at_evac(m,Shot.pos(m.prisoner)),"escort chooses a free evac tile when the first is occupied")

func _rival_counters(check: Callable) -> void:
	var c = Campaign.new("normal")
	c.sith.s.rivals.nyss.revealed = c.sith.data.rivals[2].countermeasures.duplicate(true)
	var m = launch(c,c.sith.offer("pursuit","Nyss pursuit","archive",{"rival_id":"nyss"}))
	var rival: Dictionary = m.unit_by_id(int(m.spec.rival_required))
	var actor: Dictionary = m.living("player")[0]
	actor.x = 4; actor.y = 4; rival.x = 5; rival.y = 4; rival.hp = 100; rival.max_hp = 100
	m.set_tile(Vector2i(4,4),"."); m.set_tile(Vector2i(5,4),".")
	check.call(m.spec.family == "pursuit" and not m.living("enemy").any(func(u): return u.has("runner_exit")),"rival pursuit replaces courier objective")
	check.call(preload("res://scripts/campaign/battle_sith.gd").aim(actor,rival,true) == 25,"Nyss close weakness and learned aim counter combine")
	actor.kit.append("flurry"); m.abilities.flurry.chance = 100
	check.call(m.use_ability(int(actor.id),"flurry",int(rival.id)) and int(rival.hp)<100,"melee technique hits named rival")
	check.call(int(rival.get("siphon_stopped",0)) == m.turn+1,"melee technique interrupts siphon just like basic strike")
