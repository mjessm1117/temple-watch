extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Roster = preload("res://scripts/campaign/strat_roster.gd")

static func ensure(c) -> void:
	if not c.state.has("pairs"): c.state.pairs = {}
	var voices: Dictionary = Data.get_table("legacy", "VOICES")
	var secrets: Dictionary = Data.get_table("legacy", "SECRETS")
	for i in c.state.roster.size():
		var r: Dictionary = c.state.roster[i]
		var who := "jedi" if Progression.is_jedi(r) else "troop"
		var pool := voices.keys().filter(func(key): return voices[key].who == who)
		if not voices.has(r.get("voice", "")): r.voice = pool[i % pool.size()]
		if not r.has("lore"):
			var options := secrets.keys().filter(func(key): return secrets[key].who in ["any", who])
			r.lore = {"secret":options[i % options.size()],"hints":[],"revealed":false}
		if not r.has("quotes"): r.quotes = []
		if r.get("title", "") == "Padawan" and r.status == "active" and not c.state.pairs.has(r.id):
			for mentor in c.state.roster:
				if mentor.id != r.id and mentor.status == "active" and Progression.is_jedi(mentor) and mentor.get("title", "") != "Padawan" and not c.state.pairs.values().has(mentor.id):
					c.state.pairs[r.id] = mentor.id; break

static func set_voice(c, id: String, voice: String) -> bool:
	var r: Dictionary = c.soldier(id)
	var v: Dictionary = Data.get_table("legacy", "VOICES").get(voice, {})
	if r.is_empty() or v.is_empty() or v.who != ("jedi" if Progression.is_jedi(r) else "troop"): return false
	r.voice = voice; return true

static func voice_line(c, id: String, event: String, index: int = 0) -> String:
	var r: Dictionary = c.soldier(id)
	var lines: Array = Data.get_table("legacy", "VOICES").get(r.get("voice", ""), {}).get(event, [])
	return "" if lines.is_empty() else str(lines[posmod(index, lines.size())])

static func proximity(c, padawan_id: String, distance: float, mentor_active: bool) -> Dictionary:
	var mentor: String = c.state.pairs.get(padawan_id, "")
	var rules: Dictionary = Data.get_table("legacy", "PAD")
	return {"mentor":mentor, "aim":int(rules.aim) if mentor != "" and mentor_active and distance <= int(rules.r) else 0,
		"kill_focus":int(rules.focus) if mentor != "" and mentor_active else 0, "radius":int(rules.r)}

static func reveal(c) -> void:
	for r in c.state.roster:
		var lore: Dictionary = r.lore
		var triggers := {"m3":int(r.missions) >= 3, "r3":int(r.rank) >= 3, "down":bool(r.get("survived_down", false)), "field":int(r.get("field_returns", 0)) > 0}
		var bonded := false
		for key in c.state.bonds:
			if str(r.id) in str(key).split("|") and int(c.state.bonds[key].lvl) >= 4: bonded = true
		triggers.bond = bonded
		for key in triggers:
			if triggers[key] and key not in lore.hints: lore.hints.append(key)
		if not lore.revealed and (lore.hints.size() >= 3 or int(r.rank) >= 4):
			lore.revealed = true
			var secret: Dictionary = Data.get_table("legacy", "SECRETS")[lore.secret]
			c.state.news.append(str(secret.reveal).replace("{n}", r.n))
			if r.status == "active" and c.state.quests.get(r.id, {}).get("st", "offer") == "offer": c.state.quests[r.id] = {"q":secret.quest,"st":"offer","sec":lore.secret}

static func quest_options(c) -> Array:
	var out := []
	# Opening story remains focused. Personal missions join the first crisis board.
	if int(c.state.step) == 0: return out
	var quests: Dictionary = Data.get_table("temple", "QUESTS")
	for r in c.state.roster:
		if r.status != "active" or int(r.rank) < 2: continue
		if not c.state.quests.has(r.id): c.state.quests[r.id] = {"q":"crystal" if Progression.is_jedi(r) else "family", "st":"offer"}
		var q: Dictionary = c.state.quests[r.id]
		if q.st != "offer" or int(q.get("tried", -1)) == int(c.state.step): continue
		var data: Dictionary = quests.get(q.q, {})
		if data.is_empty(): continue
		out.append({"n":"%s · %s" % [data.n, r.n],"kind":"Personal quest","mission":data.mission,"quest":r.id,"text":str(data.text).replace("{n}", r.n),"questTxt":str(data.txt).replace("{n}", r.n),"adv":false})
		if out.size() >= 2: break
	return out

static func after_mission(c, result: Dictionary) -> void:
	for entry in result.get("units", []):
		var r: Dictionary = c.soldier(str(entry.get("id", entry.get("rid", ""))))
		if r.is_empty(): continue
		if entry.get("downed", false) and r.status == "active": r.survived_down = true
		var line := str(entry.get("quote", voice_line(c, r.id, "kill" if int(entry.get("kills", 0)) > 0 else "hit", int(r.missions))))
		if line != "": r.quotes.push_front(line); r.quotes.resize(mini(3, r.quotes.size()))
	var id: String = c.state.pending_mission.get("quest", "")
	if c.state.quests.has(id):
		var quest: Dictionary = c.state.quests[id]; quest.tried = c.state.step
		var r: Dictionary = c.soldier(id)
		if result.get("win", false) and r.get("status", "") == "active" and result.get("units", []).any(func(u): return u.get("id", u.get("rid", "")) == id):
			quest.st = "done"
			var data: Dictionary = Data.get_table("temple", "QUESTS")[quest.q]
			for key in data.get("res", {}): c.gain(key, int(data.res[key]))
			for key in data.get("mod", {}): r.bonus[key] = int(r.bonus.get(key, 0)) + int(data.mod[key])
			r.dark = maxi(0, int(r.dark) + int(data.get("dark", 0)))
			if data.get("recruit", false): c.gain("recruits", 1); c.gain("credits", int(Data.get_table("core", "HIRE_COST")))
			c.state.news.append("Quest complete: " + str(data.n))
	reveal(c)
