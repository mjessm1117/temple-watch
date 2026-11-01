extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Council = preload("res://scripts/campaign/strat_council.gd")
const Progression = preload("res://scripts/campaign/progression.gd")

static func ensure(campaign) -> void:
	if not campaign.state.has("modules"): campaign.state.modules = {"cd": {}, "next": {}, "log": []}

static func ready(campaign, wing: String) -> bool:
	if campaign.sith != null and campaign.sith.wing_jammed(wing): return false
	ensure(campaign)
	return Base.operational(campaign.state, wing) and int(campaign.state.modules.cd.get(wing, 0)) == 0

static func use(campaign, wing: String) -> bool:
	ensure(campaign)
	var action: Dictionary = Data.get_table("temple", "MOD_ACTS").get(wing, {})
	if action.is_empty() or not ready(campaign, wing) or not campaign.spend(action.get("cost", {})): return false
	match str(action.get("now", "")):
		"heal":
			var wounded := []
			for r in campaign.state.roster:
				if str(r.status) == "active" and int(r.wound) > 0: wounded.append(r)
			wounded.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.wound) > int(b.wound))
			for r in wounded.slice(0, 2 if int(campaign.state.wings.medical) >= 2 else 1): r.wound = 0
		"intel": campaign.gain("intel", 3)
		"calm":
			var darkest: Dictionary = {}
			for r in campaign.state.roster:
				r.stress = maxi(0, int(r.stress) - 20)
				if Progression.is_jedi(r) and (darkest.is_empty() or int(r.dark) > int(darkest.dark)): darkest = r
			if not darkest.is_empty(): darkest.dark = maxi(0, int(darkest.dark) - 1)
		"recruit": campaign.gain("recruits", 1)
	if action.has("next"):
		for key in action.next: campaign.state.modules.next[key] = int(campaign.state.modules.next.get(key, 0)) + int(action.next[key])
	campaign.state.modules.cd[wing] = maxi(1, int(action.cd) - (1 if int(campaign.state.wings[wing]) >= 2 else 0))
	campaign.state.modules.log.push_front("%s used" % action.n)
	if campaign.state.modules.log.size() > 10: campaign.state.modules.log.resize(10)
	return true

static func advance_mission(campaign) -> void:
	ensure(campaign)
	for wing in campaign.state.modules.cd:
		campaign.state.modules.cd[wing] = maxi(0, int(campaign.state.modules.cd[wing]) - 1)

static func take_next_battle_buffs(campaign) -> Dictionary:
	ensure(campaign)
	var buffs: Dictionary = campaign.state.modules.next.duplicate(true)
	campaign.state.modules.next.clear()
	var support := Council.consume_support(campaign)
	for key in support: buffs[key] = int(buffs.get(key, 0)) + int(support[key])
	return buffs
