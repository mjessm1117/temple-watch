extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Progression = preload("res://scripts/campaign/progression.gd")

static func bond_key(a: String, b: String) -> String:
	return "%s|%s" % [mini_string(a, b), maxi_string(a, b)]

static func mini_string(a: String, b: String) -> String:
	return a if a < b else b

static func maxi_string(a: String, b: String) -> String:
	return b if a < b else a

static func bond_points(campaign, a: String, b: String, points: int) -> int:
	if a == b or campaign.soldier(a).is_empty() or campaign.soldier(b).is_empty() or points <= 0: return 0
	var key := bond_key(a, b)
	var bond: Dictionary = campaign.state.bonds.get(key, {"lvl": 0, "n": 0, "dr": []})
	bond.n = int(bond.n) + points
	var rules: Dictionary = Data.get_table("temple", "BOND")
	while int(bond.lvl) < int(rules.max) and int(bond.n) >= int(rules.need[int(bond.lvl)]):
		bond.n = int(bond.n) - int(rules.need[int(bond.lvl)])
		bond.lvl = int(bond.lvl) + 1
	campaign.state.bonds[key] = bond
	return int(bond.lvl)

static func choose_drill(campaign, pair: String, drill: String) -> bool:
	var bond: Dictionary = campaign.state.bonds.get(pair, {})
	var info: Dictionary = Data.get_table("legacy", "DRILLS").get(drill, {})
	if bond.is_empty() or info.is_empty() or int(bond.lvl) < int(info.min) or bond.dr.has(drill): return false
	bond.dr.append(drill)
	return true

static func retire(campaign, id: String, role: String = "veteran", region: String = "") -> bool:
	var r: Dictionary = campaign.soldier(id)
	var rules: Dictionary = Data.get_table("legacy", "LEGACY")
	if r.is_empty() or str(r.status) != "active" or int(r.rank) < int(rules.retireRank) or str(r.get("assign", "")) != "" or campaign.state.pending_mission.get("squad", []).has(id): return false
	if role == "council" and (not Progression.is_jedi(r) or int(r.rank) < int(rules.councilRank)): return false
	if role == "general" and region == "": return false
	r.status = "retired"; r.role = role; r.assign = ""
	campaign.state.legacy.retired.append(id)
	if role == "general": campaign.state.legacy.generals[id] = region
	return true

static func set_nickname(campaign, id: String, nickname: String) -> bool:
	var r: Dictionary = campaign.soldier(id)
	if r.is_empty(): return false
	var clean := nickname.strip_edges().substr(0, int(Data.get_table("legacy", "NICK_MAX")))
	for bad in ["<", ">", "&", "\""]: clean = clean.replace(bad, "")
	r.nick = clean
	return true

static func add_deed(campaign, id: String, key: String, count: int = 1) -> void:
	var r: Dictionary = campaign.soldier(id)
	if r.is_empty(): return
	if not r.has("deeds"): r.deeds = {}
	r.deeds[key] = int(r.deeds.get(key, 0)) + count
