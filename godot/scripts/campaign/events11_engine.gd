extends RefCounted
const PATH = "res://data/campaign/events11.json"
const Data = preload("res://scripts/campaign/data.gd")
const Crisis = preload("res://scripts/campaign/crisis11_engine.gd")

static func definitions() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return data if data is Dictionary else {}

static func ensure(s: Dictionary) -> void:
	if not s.has("events11"): s.events11 = {"missions":0,"next":2,"seen":[],"pending":"","modifier":{},"summary":{}}
	if not s.has("planet_threat11"): s.planet_threat11 = {}
	Crisis.ensure(s)

static func threat(s: Dictionary, planet: String) -> int:
	var region := str(Data.get_table("galaxy", "PLANETS").get(planet, {}).get("reg", ""))
	var baseline := maxi(int(Data.get_table("galaxy", "THREAT11").get(planet, 0)), int(s.unrest.get(region, 0)))
	return clampi(int(s.planet_threat11.get(planet, baseline)), 0, 5)

static func threat_snapshot(s: Dictionary) -> Dictionary:
	var snapshot := {}
	for planet in Data.get_table("galaxy", "PLANETS"): snapshot[planet] = threat(s, str(planet))
	return snapshot

static func effect_text(fx: Dictionary) -> String:
	var parts := PackedStringArray()
	for key in fx:
		if key == "mission_modifier":
			for stat in fx[key]: parts.append("next battle %s %+d" % [stat, int(fx[key][stat])])
		else: parts.append("%s %+d" % [str(key).capitalize(), int(fx[key])])
	return " · ".join(parts)

static func apply(c, planet: String, fx: Dictionary, enforce_cost: bool = true) -> bool:
	var cost := {}
	for key in fx:
		if key in ["threat","wound","heal","jedi_bonus","mission_modifier"]: continue
		if int(fx[key]) < 0: cost[key] = -int(fx[key])
	if enforce_cost and not c.can_afford(cost): return false
	for key in fx:
		match str(key):
			"threat": c.state.planet_threat11[planet] = clampi(threat(c.state, planet) + int(fx[key]), 0, 5)
			"mission_modifier":
				for stat in fx[key]: c.state.events11.modifier[stat] = int(c.state.events11.modifier.get(stat, 0)) + int(fx[key][stat])
			"wound", "heal", "jedi_bonus":
				var chosen: Dictionary = {}
				for r in c.state.roster:
					if not preload("res://scripts/campaign/progression.gd").is_jedi(r) or r.status != "active": continue
					if chosen.is_empty() or (key == "heal" and int(r.wound) > int(chosen.wound)): chosen = r
				if not chosen.is_empty():
					if key == "wound": chosen.wound = maxi(int(chosen.wound), int(fx[key]))
					elif key == "heal": chosen.wound = maxi(0, int(chosen.wound) - int(fx[key]))
					else: chosen.bonus.aim = int(chosen.bonus.get("aim", 0)) + int(fx[key])
			_: c.gain(str(key), int(fx[key]))
	return true

static func after_mission(c, before_res: Dictionary, before_threat: Dictionary, advanced: bool) -> void:
	ensure(c.state)
	if advanced:
		c.state.events11.modifier = {}
		c.state.events11.missions = int(c.state.events11.missions) + 1
		Crisis.after_mission(c)
		if str(c.state.events11.pending) == "" and int(c.state.events11.missions) >= int(c.state.events11.next): draw(c)
	var changes := []
	for key in c.state.res:
		var delta := int(c.state.res[key]) - int(before_res.get(key, 0))
		if delta != 0: changes.append("%s %s%d" % [str(key).capitalize(), "+" if delta > 0 else "", delta])
	for planet in c.state.planet_threat11:
		var delta := int(c.state.planet_threat11[planet]) - int(before_threat.get(planet, 0))
		if delta != 0: changes.append("%s threat %s%d" % [planet, "+" if delta > 0 else "", delta])
	c.state.events11.summary = {"month":c.state.month,"day":c.state.day,"changes":changes,"pending":c.state.events11.pending,"crises":Crisis.deadlines(c.state)}

static func draw(c) -> String:
	ensure(c.state)
	var deck: Array = definitions().get("EVENTS", [])
	var eligible := []
	for event in deck:
		if int(event.era) > int(c.state.era) or int(event.get("min_threat", 0)) > threat(c.state, str(event.planet)): continue
		if not c.state.events11.seen.has(event.id): eligible.append(event)
	if eligible.is_empty():
		c.state.events11.seen = []
		for event in deck:
			if int(event.era) <= int(c.state.era) and int(event.get("min_threat", 0)) <= threat(c.state, str(event.planet)): eligible.append(event)
	if eligible.is_empty(): return ""
	var event: Dictionary = eligible[(int(c.state.events11.missions) + int(c.state.era)) % eligible.size()]
	c.state.events11.pending = str(event.id)
	c.state.events11.next = int(c.state.events11.missions) + (3 if int(c.state.events11.missions) % 2 == 0 else 2)
	return str(event.id)

static func pending(s: Dictionary) -> Dictionary:
	var id := str(s.get("events11", {}).get("pending", ""))
	for event in definitions().get("EVENTS", []):
		if event.id == id: return event
	return {}

static func choose(c, index: int) -> bool:
	var event := pending(c.state)
	if event.is_empty() or index < 0 or index >= event.choices.size(): return false
	var choice: Array = event.choices[index]
	if not apply(c, str(event.planet), choice[1]): return false
	c.state.events11.seen.append(event.id); c.state.events11.pending = ""
	c.state.news.append("Galaxy event: %s — %s" % [event.title, choice[0]])
	return true
