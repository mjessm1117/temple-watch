extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Base = preload("res://scripts/campaign/strat_base.gd")
const Roster = preload("res://scripts/campaign/strat_roster.gd")

static func edicts(c, cards: Array) -> bool:
	if int(c.state.strategy.edict_month) == int(c.state.month) or cards.size() > 2: return false
	var seen := []
	for id in cards:
		if not Data.get_table("temple", "EDICTS").has(id) or id in seen: return false
		seen.append(id)
	c.state.strategy.edict = cards.duplicate(); c.state.strategy.edict_month = c.state.month
	return true

static func vote(c, id: String, choice: int) -> bool:
	var vote_data: Dictionary = Data.get_table("temple", "VOTES").get(id, {})
	var stamp := "%d:%s" % [c.state.month, id]
	if vote_data.is_empty() or choice < 0 or choice >= vote_data.opts.size() or c.state.strategy.votes.has(stamp): return false
	var option: Dictionary = vote_data.opts[choice]
	var costs := {}
	for key in option.fx:
		if key not in ["orderDark", "stress"] and int(option.fx[key]) < 0: costs[key] = -int(option.fx[key])
	if not c.can_afford(costs): return false
	for key in option.fx:
		if key == "stress":
			for r in c.state.roster: r.stress = clampi(int(r.stress) + int(option.fx[key]), 0, 100)
		else: c.gain(key, int(option.fx[key]))
	var agreement := 0
	for seat in Data.get_table("temple", "SEATS").values():
		if int(seat.era) == int(c.state.era): agreement += 5 if seat.stance in option.pleases else -3
	c.state.strategy.loyalty = clampi(int(c.state.strategy.loyalty) + agreement, 0, 100)
	c.state.strategy.votes[stamp] = choice; c.state.news.append("Council: " + str(option.t))
	return true

static func support(c, id: String) -> bool:
	var r: Dictionary = c.soldier(id)
	if id in c.state.strategy.support: c.state.strategy.support.erase(id); return true
	if c.state.strategy.support.size() >= 1 or r.is_empty() or r.status != "retired" or r.get("role", "") not in ["council", "general"] or int(r.wound) > 0: return false
	if int(c.state.strategy.loyalty) < 10 or int(c.state.strategy.support_used.get(id, -1)) == int(c.state.month): return false
	if r.role == "general" and c.state.strategy.support_used.has(id): return false
	c.state.strategy.support.append(id); return true

static func consume_support(c) -> Dictionary:
	var buffs := {}
	for id in c.state.strategy.support:
		var r: Dictionary = c.soldier(id)
		if r.is_empty() or r.status != "retired": continue
		buffs["will"] = 5; buffs["aim"] = 5
		c.state.strategy.support_used[id] = c.state.month
		c.state.strategy.loyalty = maxi(0, int(c.state.strategy.loyalty) - 10)
		c.state.news.append("%s supports the next deployment (+5 aim / will)." % r.n)
	c.state.strategy.support = []
	return buffs

static func month(c) -> void:
	var effects := Base.effects(c.state)
	for key in ["credits", "intel", "kyber", "favor", "recruits", "orderDark"]: c.gain(key, int(effects.get(key, 0)))
	var kept := []
	for id in c.state.strategy.edict:
		var card: Dictionary = Data.get_table("temple", "EDICTS")[id]
		var cost := {"credits":int(card.cost)}
		if id == "scholarship": cost["intel"] = 2
		if c.spend(cost):
			kept.append(id)
			if id == "reclamation": c.gain("orderDark", 1)
		else: c.state.news.append("Edict suspended: " + str(card.n))
	c.state.strategy.edict = kept
	Roster.refresh_recruits(c.state)
