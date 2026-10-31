extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const TITLES = ["", "Recruit", "Private", "Corporal", "Sergeant", "Lieutenant", "Captain", "Commander", "Veteran Commander", "Elite Commander", "Legend"]

static func is_jedi(r: Dictionary) -> bool:
	return bool(Data.get_table("core", "CLASS").get(str(r.get("cls", "")), {}).get("jedi", false))

static func promote(r: Dictionary) -> bool:
	var before := int(r.get("rank", 1))
	var ranks: Array = Data.get_table("core", "RANKS")
	while int(r.get("rank", 1)) < ranks.size() and int(r.get("xp", 0)) >= int(ranks[int(r.rank)].xp):
		r.rank = int(r.rank) + 1
	if int(r.rank) > before and not is_jedi(r):
		r.title = TITLES[min(int(r.rank), TITLES.size() - 1)]
	r.pick = pending_rank(r)
	return int(r.rank) > before

static func tree_options(r: Dictionary, rank: int) -> Array:
	var tree: Dictionary = Data.get_table("research", "TREES").get(str(r.get("cls", "")), {})
	if tree.is_empty(): return []
	if rank <= 2: return tree.get("trunk", {}).get(str(rank), [])
	if rank == 3:
		var out := []
		for spec in tree.get("specs", {}).values(): out.append(spec.sig)
		return out
	return tree.get("specs", {}).get(str(r.get("spec", "")), {}).get(str(rank), [])

static func pending_rank(r: Dictionary) -> int:
	var rank: int = r.get("picks", []).size() + 1
	return rank if rank <= int(r.get("rank", 1)) and not tree_options(r, rank).is_empty() else 0

static func choose(r: Dictionary, pick: String) -> bool:
	var rank := pending_rank(r)
	if rank == 0 or not tree_options(r, rank).has(pick): return false
	r.picks.append(pick)
	if rank == 3:
		var specs: Dictionary = Data.get_table("research", "TREES").get(str(r.cls), {}).get("specs", {})
		for key in specs:
			if str(specs[key].sig) == pick: r.spec = key
	r.pick = pending_rank(r)
	return true

static func battle_stats(r: Dictionary) -> Dictionary:
	var base: Dictionary = Data.get_table("core", "CLASS").get(str(r.get("cls", "")), {}).duplicate(true)
	if base.is_empty(): return {}
	for rank in range(2, int(r.get("rank", 1)) + 1):
		var gain: Dictionary = Data.get_table("core", "RANK_GAIN").get(str(rank), {})
		for key in ["hp", "aim", "will"]: base[key] = int(base.get(key, 0)) + int(gain.get(key, 0))
		var special: Dictionary = gain.get("jedi" if is_jedi(r) else "troop", {})
		for key in special:
			if base.has(key): base[key] = int(base[key]) + int(special[key])
	for pick in r.get("picks", []):
		var perk: Dictionary = Data.get_table("temple", "PERKS").get(str(pick), {})
		_add_mod(base, perk.get("mod", {}))
	return base

static func _add_mod(stats: Dictionary, mod: Dictionary) -> void:
	for key in mod:
		if key == "dmg":
			stats.dmg = [int(stats.dmg[0]) + int(mod[key]), int(stats.dmg[1]) + int(mod[key])]
		elif key == "dmgHi": stats.dmg[1] = int(stats.dmg[1]) + int(mod[key])
		else: stats[key] = int(stats.get(key, 0)) + int(mod[key])
