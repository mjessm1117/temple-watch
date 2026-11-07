extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Roster = preload("res://scripts/campaign/strat_roster.gd")
const Progression = preload("res://scripts/campaign/progression.gd")

static func ensure(c) -> void:
	var f: Dictionary = c.state.field
	if not f.has("n"):
		f.n = f.list.size()
		for op in f.list: f.n = maxi(int(f.n), int(str(op.get("id", "f0")).trim_prefix("f")))
	if not f.has("spawn_month"):
		f.spawn_month = 0
		spawn(c)
	for op in f.list:
		if not op.has("planet"): op.planet = "Coruscant"
		if not op.has("exp"): op.exp = 30

static func spawn(c) -> void:
	var f: Dictionary = c.state.field
	if int(f.get("spawn_month", 0)) == int(c.state.month): return
	f.spawn_month = c.state.month
	var pool: Dictionary = Data.get_table("galaxy", "FIELD_OPS")
	var keys: Array = pool.keys()
	var planets: Array = Data.get_table("galaxy", "FIELD_PLANETS").get(str(c.state.era), ["Coruscant"])
	var count := 0
	for offset in keys.size():
		var key: String = keys[(offset + (int(c.state.month) - 1) * 2) % keys.size()]
		if bool(pool[key].get("covert", false)): continue
		if f.list.any(func(op): return op.k == key and op.st in ["open", "team"]): continue
		_add(f, key, str(planets[count % planets.size()])); count += 1
		if count >= (2 if int(c.state.month) >= 3 else 1): break
	if int(c.state.month) >= 2:
		for key in ["vault", "mole", "kyberrun", "yard"]:
			if not f.list.any(func(op): return op.k == key and op.st in ["open", "team"]):
				_add(f, key, str(planets[int(c.state.month) % planets.size()])); break
	c.state.news.append("New field operations are available.")

static func _add(f: Dictionary, key: String, planet: String) -> void:
	f.n = int(f.n) + 1
	f.list.append({"id":"f%d" % f.n,"k":key,"st":"open","exp":30,"planet":planet})

static func offer(c, key: String) -> Dictionary:
	for op in c.state.field.list:
		if (op.id == key or op.k == key) and op.st == "open": return op
	return {}

static func risk(c, key: String, team: Array) -> Dictionary:
	var op := offer(c, key)
	var definition: Dictionary = Data.get_table("galaxy", "FIELD_OPS").get(str(op.get("k", key)), {})
	var out := {"success":0,"ambush":0,"wound":0,"capture":0,"why":[],"rewards":{}}
	if definition.is_empty(): return out
	var stars := int(definition.stars)
	var quiet: bool = "discretion" in c.state.strategy.edict
	out.ambush = maxi(0, 8 * stars - (10 if quiet else 0))
	out.wound_roll = 10 + 8 * stars
	out.wound = roundi(int(out.ambush) + (100 - int(out.ambush)) * int(out.wound_roll) / 100.0)
	out.capture = maxi(0, (25 if bool(definition.get("covert", false)) else 0) - (5 if quiet else 0))
	for k in definition.res:
		out.rewards[k] = roundi(int(definition.res[k]) * 0.5 * float(Data.get_table("missions", "DIFF")[c.state.diff].income)) if k == "credits" else int(definition.res[k])
	if team.size() < 2 or team.size() > 3 or _unique(team).size() != team.size(): return out
	var total := 45 - 12 * (stars - 1)
	out.why.append("Base 45; difficulty −%d" % (12 * (stars - 1)))
	var matches := 0
	for id in team:
		var r: Dictionary = c.soldier(str(id))
		if not Roster.ready(r) or c.state.pending_mission.get("squad", []).has(id): return out
		total += int(r.rank) * 5
		out.why.append("%s rank +%d" % [r.n, int(r.rank) * 5])
		if definition.want.has(r.cls) or (definition.want.has("jedi") and Progression.is_jedi(r)): matches += 1
		if int(r.fatigue) >= 34: total -= 8; out.why.append("%s tired −8" % r.n)
	total += mini(matches, 2) * 10 + (8 if team.size() == 3 else 0)
	out.why.append("Skills +%d; third member +%d" % [mini(matches, 2) * 10, 8 if team.size() == 3 else 0])
	var region: String = Data.get_table("galaxy", "PLANETS").get(op.get("planet", ""), {}).get("reg", "")
	if int(c.state.unrest.get(region, 0)) >= 3: total -= 10; out.why.append("Regional unrest −10")
	out.success = clampi(total, 10, 92)
	return out

static func _unique(team: Array) -> Array:
	var out := []
	for id in team:
		if id not in out: out.append(id)
	return out

static func send(c, key: String, team: Array) -> bool:
	var op := offer(c, key)
	if op.is_empty(): return false
	var odds := risk(c, key, team)
	if int(odds.success) == 0: return false
	var definition: Dictionary = Data.get_table("galaxy", "FIELD_OPS")[op.k]
	if not c.spend({"credits":int(definition.get("fee", 0))}): return false
	op.st = "team"; op.team = team.duplicate(); op.left = int(definition.days); op.ch = odds.success; op.risk = odds
	for id in team: c.soldier(str(id)).assign = "field:" + str(op.id)
	c.state.news.append("%s: team away for %d days (%d%%)." % [definition.n, op.left, op.ch])
	return true

static func tick(c) -> void:
	for op in c.state.field.list:
		if op.st == "open":
			op.exp = int(op.exp) - 1
			if int(op.exp) <= 0:
				op.st = "lapsed"; c.state.news.append("Field operation expired: " + str(op.k))
				c.change_unrest(str(Data.get_table("galaxy", "PLANETS").get(op.planet, {}).get("reg", "")), 1)
		elif op.st == "team":
			op.left = int(op.left) - 1
			if int(op.left) <= 0: resolve(c, op)
	# Keep current assignments and a bounded trail; logs survive pruning.
	var finished: Array = c.state.field.list.filter(func(op): return op.st not in ["open", "team"])
	for op in finished.slice(0, maxi(0, finished.size() - 12)): c.state.field.list.erase(op)

static func resolve(c, op: Dictionary, rolls: Array = []) -> void:
	if op.get("st", "") != "team": return
	var draws := rolls.duplicate()
	while draws.size() < 4: draws.append(randi_range(0, 99))
	var won := int(draws[0]) < int(op.ch)
	var risk_data: Dictionary = op.get("risk", {"ambush":16,"wound":26,"capture":25 if Data.get_table("galaxy", "FIELD_OPS")[op.k].get("covert", false) else 0})
	var ambush := int(draws[1]) < int(risk_data.ambush)
	var wound := ambush or int(draws[2]) < int(risk_data.get("wound_roll", risk_data.wound))
	var captured := not won and int(draws[3]) < int(risk_data.capture)
	var members := []
	for id in op.team:
		var r: Dictionary = c.soldier(str(id))
		if r.is_empty() or r.status != "active": continue
		if r.assign == "field:" + str(op.id): r.assign = ""
		r.fatigue = mini(100, int(r.fatigue) + 38)
		r.field_returns = int(r.get("field_returns", 0)) + 1
		if won: r.xp = int(r.xp) + 15; Progression.promote(r, c.state.roster)
		else: r.stress = mini(100, int(r.stress) + 15)
		members.append(r)
	if captured and not members.is_empty():
		var captive: Dictionary = members.pop_back(); captive.status = "captured"; captive.capT = int(Data.get_table("core", "CAPTIVE")); captive.covert_captive = true
	if wound and not members.is_empty(): members[0].wound = maxi(int(members[0].wound), 20 if ambush else 10)
	if won:
		var rewards: Dictionary = op.get("risk", {}).get("rewards", {})
		if rewards.is_empty():
			for key in Data.get_table("galaxy", "FIELD_OPS")[op.k].res:
				var amount := int(Data.get_table("galaxy", "FIELD_OPS")[op.k].res[key])
				rewards[key] = roundi(amount * 0.5 * float(Data.get_table("missions", "DIFF")[c.state.diff].income)) if key == "credits" else amount
		for key in rewards: c.gain(key, int(rewards[key]))
		c.change_unrest(str(Data.get_table("galaxy", "PLANETS").get(op.get("planet", ""), {}).get("reg", "")), -1)
	op.st = "won" if won else "lost"
	var line := "%s: %s%s%s%s" % [op.k, op.st, " · ambushed" if ambush else "", " · wounded" if wound else "", " · captured; rescue required" if captured else ""]
	c.state.news.append(line)
	c.state.field.log.push_front({"k":op.k,"win":won,"month":c.state.month,"text":line,"ambush":ambush,"wound":wound,"capture":captured})
	c.state.field.log.resize(mini(6, c.state.field.log.size())); c.refresh_options()

static func team_risk(c, team: Dictionary, option: Dictionary, excluded: Array = []) -> Dictionary:
	var members := []
	for id in [team.get("lead", "")] + team.get("mem", []):
		var r: Dictionary = c.soldier(str(id))
		if Roster.ready(r) and id not in excluded and not members.has(r): members.append(r)
	var out := {"success":0,"why":[],"members":members,"wound":25,"capture":30,"death":7}
	if members.size() < 2: return out
	var total := 47
	var why: Array = out.why
	why.append("Base 47")
	if members.any(func(r): return r.id == team.lead): total += 8; why.append("Leader +8")
	var ranks := 0; var tired := 0; var bonds := 0
	for r in members:
		ranks += int(r.rank)
		if int(r.fatigue) >= 34: tired += 1
	for i in members.size():
		for j in range(i + 1, members.size()):
			var a: String = members[i].id; var b: String = members[j].id
			var key := a + "|" + b if a < b else b + "|" + a
			if int(c.state.bonds.get(key, {}).get("lvl", 0)) > 0: bonds += 3
	var diff := int(Data.get_table("galaxy", "TAUTO").diff.get(c.state.diff, 0))
	var short := maxi(0, 4 - members.size()) * 6
	var intel = preload("res://scripts/campaign/galaxy_intel.gd")
	var danger: Dictionary = intel.risk(c, c.story.mission(str(option.get("mission", "rescue"))), option)
	var strength := 0.0
	for r in members: strength += intel.unit_power(c, str(r.id)) * 1.5
	var ratio := 100.0 * int(danger.enemy) / maxf(1.0, strength)
	var level := 1
	for band in Data.get_table("galaxy", "RISK"):
		if ratio >= float(band[0]): level = int(band[2])
	var risk_mod := int(Data.get_table("galaxy", "TAUTO").risk[level])
	total += ranks * 3 - tired * 5 + mini(9, bonds) + diff - short + risk_mod
	why.append("Ranks +%d; bonds +%d; tired −%d; short −%d; difficulty %+d; risk %+d" % [ranks * 3, mini(9, bonds), tired * 5, short, diff, risk_mod])
	out.success = clampi(total, 10, 85)
	return out
