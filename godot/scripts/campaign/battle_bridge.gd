extends RefCounted
const Mission = preload("res://scripts/mission.gd")
const Deployment = preload("res://scripts/campaign/strat_deployment.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Classes = preload("res://scripts/class_registry.gd")
const Settings = preload("res://scripts/settings.gd")
const Story = preload("res://scripts/story/story_engine.gd")

static func map_path(id: String) -> String:
	return preload("res://scripts/map_catalog.gd").resolve(id)

static func create(campaign, seed_value: int) -> RefCounted:
	Settings.difficulty = str(campaign.state.diff)
	var pending: Dictionary = campaign.state.pending_mission
	var path := preload("res://scripts/map_catalog.gd").select_layout(preload("res://scripts/campaign/battle_sith.gd").map_id(pending),seed_value,int(pending.get("map_variant",0 if pending.has("sith_offer_id") else -1)))
	if path == "":
		push_error("No map registered for campaign mission " + str(pending.mission_id))
		return null
	var m = Mission.new(seed_value, path)
	m.units = m.units.filter(func(u): return u.side != "player")
	var tiles := Deployment.spawn_tiles(m, pending.squad.size())
	if tiles.size() != pending.squad.size(): return null
	var players: Array[Dictionary] = []
	for i in pending.squad.size():
		var r: Dictionary = campaign.soldier(str(pending.squad[i]))
		var kind := str(r.cls).to_lower()
		if not m.catalog.has(kind) or m.catalog[kind].side != "player":
			kind = "guardian" if Progression.is_jedi(r) else "soldier"
		m._spawn(kind, tiles[i].x, tiles[i].y, -1)
		var u: Dictionary = m.units.pop_back()
		u.rid = r.id; u.name = r.n; u.class_name = r.cls; u.rank = r.rank
		if Progression.is_jedi(r):
			var tier: Dictionary = Classes.rank_data("jedi", int(r.rank))
			u.master_aura = int(tier.get("aura", 0))
			u.master_action_available = bool(tier.get("third_action_once", false)) or int(r.rank) > 5
		u.dark = r.get("dark", 0)
		var stats: Dictionary = preload("res://scripts/campaign/gear.gd").battle_stats(campaign, str(r.id))
		for key in ["hp", "aim", "mob", "range", "will", "crit", "deflect", "dodge", "armor"]:
			if stats.has(key): u[key] = stats[key]
		u.hp = int(u.hp) + int(m.difficulty.get("player_hp", 0)); u.max_hp = u.hp
		u.aim = int(u.aim) + int(m.difficulty.get("player_aim", 0))
		u.damage = stats.get("dmg", u.damage).duplicate()
		u.focus = int(stats.get("maxF", 0)); u.focus_left = u.focus
		u.guard_deflect = int(stats.get("guardDef", 0))
		Deployment.apply_identity(campaign, u, r)
		players.append(u)
	if int(pending.get("fewer",0)) > 0:
		for enemy in m.living("enemy").filter(func(u): return u.kind == "trooper").slice(0,int(pending.fewer)): m.units.erase(enemy)
	m.units = players + m.units
	for row in preload("res://scripts/campaign/temple_rooms.gd").active(campaign.state):
		var bonus: Dictionary = row.bonus
		effects(m, campaign, bonus)
		for u in players:
			u.will = int(u.will) + int(bonus.get("will", 0))
			if int(u.rank) <= 2: u.aim = int(u.aim) + int(bonus.get("rookieAim", 0))
			if int(u.focus) == 0: u.aim = int(u.aim) + int(bonus.get("troopAim", 0))
	effects(m, campaign, campaign.state.get("events11", {}).get("modifier", {}))
	if bool(m.prisoner.get("freed",false)) and not players.is_empty(): m.prisoner.escort_id = players[0].id
	effects(m, campaign, campaign.state.get("approach", {}))
	for fx in campaign.state.get("finale_effects", []): effects(m, campaign, fx)
	effects(m, campaign, campaign.state.get("battle_buffs", {}))
	preload("res://scripts/campaign/battle_sith.gd").setup(campaign,m)
	# --- wave10 gear ---
	var combat = preload("res://scripts/combat_mission.gd").adopt(m, campaign.state)
	preload("res://scripts/campaign/gear.gd").apply_campaign_effects(combat, campaign)
	return combat

static func effects(m, campaign, fx: Dictionary) -> void:
	for u in m.living("player"):
		var jedi := int(u.get("focus", 0)) > 0
		u.aim = int(u.aim) + int(fx.get("aim", 0)) + (int(fx.get("jediAim", 0)) if jedi else 0) + int(fx.get("clsAim", {}).get(u.class_name, 0))
		u.crit = int(u.get("crit", 0)) + int(fx.get("crit", 0))
		if jedi and fx.has("jdmg"): u.damage = [int(u.damage[0]) + int(fx.jdmg), int(u.damage[1]) + int(fx.jdmg)]
		if not jedi: u.armor = int(u.get("armor", 0)) + int(fx.get("tarmor", 0))
		u.medpacs = int(u.get("medpacs", 0)) + int(fx.get("kit", 0))
		u.mob = maxi(1, int(u.mob) + int(fx.get("mob", 0)))
		u.max_hp = maxi(1, int(u.max_hp) + int(fx.get("hp", 0)))
		u.hp = clampi(int(u.hp) + int(fx.get("hp", 0)) + int(fx.get("heal", 0)), 1, int(u.max_hp))
		if jedi: u.focus_left = int(u.focus_left) + int(fx.get("focus", 0))
		for who in fx.get("unitAim", {}):
			if u.get("rid", "") == campaign.state.saga.id.get(who): u.aim = int(u.aim) + int(fx.unitAim[who])
	var enemies: Array = m.living("enemy")
	for u in enemies:
		u.aim = int(u.aim) + int(fx.get("foeAim", 0))
		u.hp = maxi(1, int(u.hp) + int(fx.get("foeHp", 0))); u.max_hp = u.hp
	for u in enemies.slice(0, int(fx.get("foeStun", 0))): u.stunned = true; u.stunned_until = m.turn + 1
	for u in enemies.slice(0, 3):
		if fx.has("strafe"): m.apply_damage(u, int(fx.strafe))
	for u in enemies:
		if u.get("boss", false) and fx.has("hurtBoss"): m.apply_damage(u, int(fx.hurtBoss))
	# Detention Line has no boss locks; retain the modifier for maps that expose them.
	m.spec.story_locks = int(m.spec.get("story_locks", 0)) + int(fx.get("lock", 0))
	for u in enemies.slice(0, int(fx.get("cutFoe", 0)) + int(fx.get("remove", 0)) + int(fx.get("surrender", 0))): m.units.erase(u)
	if fx.has("ally"):
		var anchor: Dictionary = m.living("player")[0]
		m._spawn_near("soldier", Vector2i(int(anchor.x), int(anchor.y)), -1)
		m.units[-1].name = fx.get("allyName", "Republic support")
	if int(fx.get("threat", 0)) > 0:
		for u in enemies:
			if int(u.group) == 0: u.awake = true; u.spotted = true

static func result(campaign, m) -> Dictionary:
	var rows := []
	for u in m.units:
		if not u.has("rid"): continue
		rows.append({"id":u.rid, "status":"dead" if u.get("status") == "dead" else "active", "hp":u.hp, "max_hp":u.max_hp,
			"downed":bool(u.get("wounded", false)) or int(u.hp) <= 0,
			"hurt":int(u.hp) < int(u.max_hp), "kills":int(u.get("kills", 0)),
			"quote":u.get("quote", ""), "captures":int(u.get("captures", 0)), "dark":int(u.get("dark", 0)) + int(u.get("darkness", 0))})
	var pending: Dictionary = campaign.state.pending_mission
	# --- wave10 story ---
	var cohesion: Dictionary = {}
	if m.get("bond_pairs") != null:
		for pair in m.bond_pairs:
			if int(m.bond_pairs[pair].get("cohesion",0)) > 0: cohesion[pair] = int(m.bond_pairs[pair].cohesion)
	return {"mission_id":pending.mission_id, "win":m.result == "win", "units":rows,
		"bond_cohesion":cohesion,
		"mercy":m.get("mercy_events") if m.get("mercy_events") != null else [], "story":bool(pending.get("story", false)), "bonds_recorded":true,
		"family":m.spec.get("family","rescue"), "map_id":m.spec.get("id","rescue"),
		"objectives_completed":m.objective_state.get("done",{}).size(), "civilians_saved":int(m.objective_state.get("saved",0)),
		"metrics":preload("res://scripts/mission_metrics.gd").report(m) if m.modern else {}, "hack_intel":int(m.hack_state.get("intel",0)) + (maxi(0,m.objective_state.get("done",{}).size()-int(m.spec.objective.required)) if m.modern and m.spec.family == "hack_terminal" else 0)}

static func casualties(campaign, result: Dictionary) -> String:
	var rows := []
	for u in result.units:
		rows.append("%s · %s · %d kills" % [campaign.soldier(str(u.id)).n,
			"Wounded — recovering at the Temple" if u.downed or u.hurt else "Ready", int(u.kills)])
	return "\n".join(rows)
