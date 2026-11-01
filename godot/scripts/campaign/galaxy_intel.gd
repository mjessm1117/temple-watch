extends RefCounted
## Read-only presentation estimates; never changes mission IDs, rewards or combat rules.
const Data = preload("res://scripts/campaign/data.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const COLORS = [Color("7fd99a"), Color("79d3e2"), Color("e0bd78"), Color("ef6a5d")]
static var catalog: Dictionary = {}

static func planet_for(mission: Dictionary) -> String:
	var title := str(mission.get("where", "")).split("·")[-1].strip_edges()
	return title if Data.get_table("galaxy", "PLANETS").has(title) else "Mid Rim"

static func resources(values: Dictionary) -> String:
	var parts := PackedStringArray()
	for key in values: parts.append("%s %s" % [str(int(values[key])) if values[key] is float and is_equal_approx(float(values[key]),float(int(values[key]))) else str(values[key]), str(key).capitalize()])
	return " · ".join(parts) if not parts.is_empty() else "None"

static func darkness(campaign) -> int:
	var value := int(campaign.state.get("orderDark", 0))
	for r in campaign.state.roster:
		if r.status == "active" and bool(Data.get_table("core", "CLASS").get(r.cls, {}).get("jedi", false)):
			value += 4 * int(r.get("dark", 0))
	return mini(100, value)

static func unrest(campaign, region: String) -> int:
	var values: Dictionary = campaign.state.get("unrest", {})
	return clampi(int(values.get("r", values).get(region, 0)), 0, 5)

static func region_name(region: String) -> String:
	for row in Data.get_table("galaxy", "REGIONS"):
		if row[0] == region: return str(row[1])
	return region

static func foes(m: Dictionary) -> Array:
	var list := []
	for f in m.get("foes", []): list.append(str(f[0]))
	for wave in m.get("waves", {}).values(): list.append_array(wave)
	for key in ["boss", "bossKey"]:
		if m.has(key) and not list.has(m[key]): list.append(m[key])
	return list

static func risk(campaign, m: Dictionary, option: Dictionary) -> Dictionary:
	if catalog.is_empty(): catalog = JSON.parse_string(FileAccess.get_file_as_string("res://assets/galaxy/intel.json"))
	var diff: Dictionary = Data.get_table("missions", "DIFF").get(campaign.state.diff, {})
	var id := str(option.get("mission", ""))
	var tune: Dictionary = catalog.tune.get(id + ":0", catalog.tune.get(id, {}))
	var rules: Dictionary = Data.get_table("galaxy", "RISK_W")
	var power := 0.0; var counts := {}; var missing := false
	for key in foes(m):
		var f: Dictionary = catalog.foes.get(key, {})
		if f.is_empty(): missing = true; continue
		var title := str(f.get("n", key)); counts[title] = int(counts.get(title, 0)) + 1
		var hp := float(f.get("hp", 0)) + float(tune.get("hp", 0)) + float(diff.get("enemyHp", 0)) + 2 * float(f.get("armor", 0))
		var aim := (float(f.get("aim", 65)) + float(tune.get("aim", 0)) + float(diff.get("enemyAim", 0))) / 65.0
		power += hp * aim * (1.4 if f.get("horror", false) else 1.0) * (float(rules.boss) if key in [m.get("boss"),m.get("bossKey")] or f.get("boss", false) else 1.0)
	power += (float(tune.get("extra", 0)) + float(diff.get("extra", 0)) * m.get("waves", {}).size()) * 4
	if rules.clock.has(m.get("type", "")): power += float(rules.threat)
	var modifiers := {"enemyAim":0.0,"enemyHp":0.0}
	for active in campaign.state.get("ops",{}).get("mods",[]):
		for key in modifiers: modifiers[key] += float(active.get("mod",{}).get(key,0))
	power *= 1.0+(float(modifiers.enemyAim)+float(modifiers.enemyHp)*8.0)/100.0
	var squad: Array = campaign.default_squad(option); var squad_power := 0.0
	for member in squad: squad_power += unit_power(campaign, str(member))
	var ratio := 100.0 * power / squad_power if squad_power > 0 else power / float(rules.solo)
	var band: Array = Data.get_table("galaxy", "RISK")[0]
	for row in Data.get_table("galaxy", "RISK"):
		if ratio >= float(row[0]): band = row
	var expected := PackedStringArray()
	for title in counts: expected.append("%d× %s" % [counts[title], title])
	if missing: expected.append("unidentified contacts")
	return {"name":band[1], "level":int(band[2]), "color":COLORS[int(band[2])-1], "enemy":roundi(power),
		"squad":roundi(squad_power), "count":squad.size(), "expected":", ".join(expected) if not expected.is_empty() else "Unknown"}

static func unit_power(campaign, id: String) -> float:
	var u: Dictionary = Gear.battle_stats(campaign, id); var r: Dictionary = campaign.soldier(id)
	var w: Dictionary = Data.get_table("research", "POWER_W")
	var total := 0.0
	for key in ["hp", "armor", "crit", "mob", "deflect", "dodge"]: total += float(u.get(key, 0)) * float(w.get(key, 0))
	total += (float(u.get("aim",50))-50)*float(w.aim)
	var damage: Array = u.get("dmg", [0,0]); total += (float(damage[0])+float(damage[1]))*0.5*float(w.dmg)
	total += float(u.get("maxF",0))*float(w.focus)+minf(float(u.get("range",0)),float(w.rangeCap))*float(w.range)
	total += float(u.get("kits",0))*float(w.kit)+float(u.get("nades",0))*float(w.nade)
	for i in r.get("picks", []).size(): total += mini(3, 1 + maxi(0, int(r.rank)-i-1)/2)*float(w.skill)
	if r.get("spec", "") != "": total += float(w.spec)
	return roundf(total)

static func deadline(option: Dictionary, options: Array) -> String:
	if option.get("story", false): return "No deadline · the war moves while you wait"
	if not option.get("adv", false): return "Stays open while the unit is free" if option.has("quest") or option.has("redeem") else "Stays open this step"
	var advancing := 0
	for o in options:
		if o.get("adv", false): advancing += 1
	return "Expires when you launch another mission" if advancing > 1 else "Last chance"

static func goal(m: Dictionary) -> String:
	var text := str(m.get("goal", ""))
	if text.is_empty():
		text = {"defend":"Hold for %d turns" % int(m.get("turns", 0)), "rescue":"Free the prisoner and reach evac", "investigate":"Scan the terminals and extract", "sabotage":"Plant the charges and extract", "escort":"Get the VIP to evac"}.get(str(m.get("type", "")), "Take down the target")
	if m.has("par"): text += " · par %d turns" % int(m.par)
	return text

static func operation_planet(campaign, operation: Dictionary) -> String:
	var planets: Dictionary = Data.get_table("galaxy","PLANETS")
	if planets.has(str(operation.get("planet",""))): return str(operation.planet)
	var list: Array = Data.get_table("galaxy","FIELD_PLANETS").get(str(campaign.state.era),Data.get_table("galaxy","FIELD_PLANETS")["1"])
	# Same stable signed 32-bit hash as the web opPlanet function.
	var value := 0
	for code in str(operation.get("id",operation.get("k",""))).to_utf32_buffer().to_int32_array():
		value = (value*31+code)&0xffffffff
		if value > 0x7fffffff: value -= 0x100000000
	return str(list[absi(value)%list.size()])
