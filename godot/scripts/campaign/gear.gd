extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const MOD_KEY = {"w": "mods", "a": "amods", "s": "smods"}
const POOL_KEY = {"w": "W_MODS", "a": "AMODS", "s": "SMODS"}

static func price(campaign, cost: int) -> int:
	return roundi(cost * (0.8 if Base.staff_count(campaign.state, "armory") > 0 else 1.0) * (0.85 if campaign.researched("supply") else 1.0))

static func unlocked(campaign, item: Dictionary) -> bool:
	if not campaign.researched(str(item.get("res", ""))): return false
	var need: Array = item.get("need", [])
	return need.is_empty() or int(campaign.state.wings.get(str(need[0]), 0)) >= int(need[1])

static func buy_weapon(campaign, id: String) -> bool:
	var r: Dictionary = campaign.soldier(id)
	if r.is_empty() or Progression.is_jedi(r): return false
	var weapons: Array = Data.get_table("gear", "WEAPONS")
	var next := int(r.gear.w) + 1
	if next >= weapons.size(): return false
	var item: Dictionary = weapons[next]
	if not unlocked(campaign, item) or not campaign.spend({"credits": price(campaign, int(item.get("cost", 0)))}): return false
	r.gear.w = next
	return true

static func buy_armor(campaign, id: String, key: String) -> bool:
	var r: Dictionary = campaign.soldier(id)
	var item: Dictionary = Data.get_table("gear", "ARMOR").get(key, {})
	if r.is_empty() or item.is_empty() or str(r.gear.armor) == key: return false
	var who := "jedi" if Progression.is_jedi(r) else "troop"
	if str(item.get("who", "any")) not in ["any", who] or not unlocked(campaign, item): return false
	if not campaign.spend({"credits": price(campaign, int(item.get("cost", 0)))}): return false
	r.gear.armor = key
	while r.gear.amods.size() > int(item.get("slots", 0)): r.gear.amods.pop_back()
	return true

static func craft_saber(campaign, id: String) -> bool:
	var r: Dictionary = campaign.soldier(id)
	if r.is_empty() or not Progression.is_jedi(r): return false
	var sabers: Array = Data.get_table("gear", "SABERS")
	var next := int(r.gear.saber) + 1
	if next >= sabers.size(): return false
	var item: Dictionary = sabers[next]
	var kyber := maxi(1, int(item.get("kyber", 0)) - (1 if Base.staff_count(campaign.state, "forge") > 0 else 0) - (1 if campaign.researched("kyberLore") else 0))
	if not unlocked(campaign, item) or not campaign.spend({"credits": int(item.get("cost", 0)), "kyber": kyber}): return false
	r.gear.saber = next
	return true

static func buy_utility(campaign, id: String, key: String) -> bool:
	var r: Dictionary = campaign.soldier(id)
	var item: Dictionary = Data.get_table("gear", "UTIL").get(key, {})
	if r.is_empty() or item.is_empty() or str(r.gear.get("util", "none")) == key or not unlocked(campaign, item): return false
	if not campaign.spend({"credits": price(campaign, int(item.get("cost", 0)))}): return false
	r.gear.util = key
	return true

static func set_form(campaign, id: String, key: String) -> bool:
	var r: Dictionary = campaign.soldier(id)
	var form: Dictionary = Data.get_table("gear", "FORMS").get(key, {})
	if r.is_empty() or not Progression.is_jedi(r) or form.is_empty() or not campaign.researched(str(form.get("res", ""))): return false
	r.gear.form = key
	return true

static func slots(r: Dictionary, kind: String) -> int:
	if kind == "w": return 0 if Progression.is_jedi(r) else int(Data.get_table("gear", "WEAPONS")[int(r.gear.w)].slots)
	if kind == "s": return int(Data.get_table("gear", "SABERS")[int(r.gear.saber)].slots) if Progression.is_jedi(r) else 0
	if kind == "a": return int(Data.get_table("gear", "ARMOR").get(str(r.gear.armor), {}).get("slots", 0))
	return 0

static func fit_module(campaign, id: String, kind: String, key: String) -> bool:
	var r: Dictionary = campaign.soldier(id)
	if r.is_empty() or not MOD_KEY.has(kind): return false
	var item: Dictionary = Data.get_table("gear", POOL_KEY[kind]).get(key, {})
	if item.is_empty() or not unlocked(campaign, item): return false
	if item.has("who") and str(item.who) != ("jedi" if Progression.is_jedi(r) else "troop"): return false
	var equipped: Array = r.gear[MOD_KEY[kind]]
	if equipped.has(key) or equipped.size() >= slots(r, kind): return false
	if not campaign.spend({"credits": price(campaign, int(item.cost))}): return false
	equipped.append(key); r.gear.mk["%s.%s" % [kind, key]] = 1
	return true

static func upgrade_module(campaign, id: String, kind: String, key: String) -> bool:
	var r: Dictionary = campaign.soldier(id)
	if r.is_empty() or not MOD_KEY.has(kind) or not r.gear[MOD_KEY[kind]].has(key): return false
	var lv := int(r.gear.mk.get("%s.%s" % [kind, key], 1))
	var research: Array = Data.get_table("gear", "MK_RES")[kind]
	if lv >= 3 or not campaign.researched(str(research[lv - 1])): return false
	var cost := price(campaign, int(Data.get_table("gear", "MK_COST")[lv]))
	if not campaign.spend({"credits": cost}): return false
	r.gear.mk["%s.%s" % [kind, key]] = lv + 1
	return true

static func evolve(campaign, id: String) -> bool:
	var r: Dictionary = campaign.soldier(id)
	if r.is_empty() or bool(r.get("evo", false)) or int(r.rank) < int(Data.get_table("gear", "EVO_RANK")): return false
	if not campaign.researched("mastery" if Progression.is_jedi(r) else "eliteProgram"): return false
	if not campaign.spend(Data.get_table("gear", "EVO_COST")): return false
	r.evo = true
	return true

static func battle_stats(campaign, id: String) -> Dictionary:
	var r: Dictionary = campaign.soldier(id)
	if r.is_empty(): return {}
	var stats: Dictionary = Progression.battle_stats(r)
	var g: Dictionary = r.gear
	var base_items: Array = Data.get_table("gear", "SABERS") if Progression.is_jedi(r) else Data.get_table("gear", "WEAPONS")
	for tier in range(1, int(g.saber if Progression.is_jedi(r) else g.w) + 1): Progression._add_mod(stats, base_items[tier].get("mod", {}))
	Progression._add_mod(stats, Data.get_table("gear", "ARMOR").get(str(g.armor), {}).get("mod", {}))
	Progression._add_mod(stats, Data.get_table("gear", "UTIL").get(str(g.get("util", "none")), {}).get("mod", {}))
	if Progression.is_jedi(r): Progression._add_mod(stats, Data.get_table("gear", "FORMS").get(str(g.get("form", "shiiCho")), {}).get("mod", {}))
	for kind in MOD_KEY:
		for key in g.get(MOD_KEY[kind], []):
			var item: Dictionary = Data.get_table("gear", POOL_KEY[kind]).get(str(key), {})
			var lv := int(g.mk.get("%s.%s" % [kind, key], 1))
			if item.has("mk"): Progression._add_mod(stats, item.mk[lv - 1])
	if bool(r.get("evo", false)): Progression._add_mod(stats, Data.get_table("gear", "EVO").get(str(r.cls), {}).get("mod", {}))
	Progression._add_mod(stats, r.get("bonus", {}))
	if int(r.get("fatigue", 0)) >= 34: Progression._add_mod(stats, {"aim":-5, "will":-10})
	if "weave" in campaign.state.get("strategy", {}).get("projects", []): Progression._add_mod(stats, {"armor":1})
	if "focus" in campaign.state.get("strategy", {}).get("projects", []) and Progression.is_jedi(r): Progression._add_mod(stats, {"maxF":1})
	Progression._add_mod(stats, {"will":int(Base.effects(campaign.state).get("will", 0)) + int(campaign.state.get("battle_buffs", {}).get("will", 0))})
	return stats
