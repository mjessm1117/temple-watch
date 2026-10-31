extends RefCounted
const Mission = preload("res://scripts/mission.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Settings = preload("res://scripts/settings.gd")
const Story = preload("res://scripts/story/story_engine.gd")

static func map_path(id: String) -> String:
	var path := "res://data/%s.json" % id
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary and data.has("rows") and data.has("squad"): return path
	return "res://data/rescue.json"

static func create(campaign, seed_value: int) -> RefCounted:
	Settings.difficulty = str(campaign.state.diff)
	var pending: Dictionary = campaign.state.pending_mission
	var m = Mission.new(seed_value, map_path(str(pending.mission_id)))
	var spawns: Array = m.spec.squad
	m.units = m.units.filter(func(u): return u.side != "player")
	var players: Array[Dictionary] = []
	for i in pending.squad.size():
		var r: Dictionary = campaign.soldier(str(pending.squad[i]))
		var kind := str(r.cls).to_lower()
		if not m.catalog.has(kind) or m.catalog[kind].side != "player":
			kind = "guardian" if Progression.is_jedi(r) else "soldier"
		var spawn: Array = spawns[i % spawns.size()]
		m._spawn(kind, int(spawn[1]), int(spawn[2]), -1)
		var u: Dictionary = m.units.pop_back()
		u.rid = r.id; u.name = r.n; u.class_name = r.cls; u.rank = r.rank
		u.dark = r.get("dark", 0)
		var stats: Dictionary = preload("res://scripts/campaign/gear.gd").battle_stats(campaign, str(r.id))
		for key in ["hp", "aim", "mob", "range", "will", "crit", "deflect", "dodge", "armor"]:
			if stats.has(key): u[key] = stats[key]
		u.hp = int(u.hp) + int(m.difficulty.get("player_hp", 0)); u.max_hp = u.hp
		u.aim = int(u.aim) + int(m.difficulty.get("player_aim", 0))
		u.damage = stats.get("dmg", u.damage).duplicate()
		u.focus = int(stats.get("maxF", 0)); u.focus_left = u.focus
		u.guard_deflect = int(stats.get("guardDef", 0))
		players.append(u)
	m.units = players + m.units
	effects(m, campaign, campaign.state.get("approach", {}))
	for fx in campaign.state.get("finale_effects", []): effects(m, campaign, fx)
	effects(m, campaign, campaign.state.get("battle_buffs", {}))
	return m

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
			"captures":int(u.get("captures", 0)), "dark":int(u.get("dark", 0)) + int(u.get("darkness", 0))})
	var pending: Dictionary = campaign.state.pending_mission
	return {"mission_id":pending.mission_id, "win":m.result == "win", "units":rows,
		"story":bool(pending.get("story", false)), "bonds_recorded":true}

static func casualties(campaign, result: Dictionary) -> String:
	var rows := []
	for u in result.units:
		rows.append("%s · %s · %d kills" % [campaign.soldier(str(u.id)).n,
			"Wounded — recovering at the Temple" if u.downed or u.hurt else "Ready", int(u.kills)])
	return "\n".join(rows)
