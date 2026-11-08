extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Classes = preload("res://scripts/class_registry.gd")
const TITLES = ["", "Recruit", "Private", "Corporal", "Sergeant", "Lieutenant", "Captain", "Commander", "Veteran Commander", "Elite Commander", "Legend"]

static func is_jedi(r: Dictionary) -> bool:
	return Classes.side(str(r.get("cls", ""))) == "jedi" or bool(Data.get_table("core", "CLASS").get(str(r.get("cls", "")), {}).get("jedi", false))

static func promote(r: Dictionary, roster: Array = [], campaign = null) -> bool:
	var before := int(r.get("rank", 1))
	var side_name := "jedi" if is_jedi(r) else "soldier"
	var ranks := Classes.ranks(side_name)
	while int(r.get("rank", 1)) < ranks.size() and int(r.get("xp", 0)) >= int(ranks[int(r.rank)].xp):
		if side_name == "jedi" and int(r.rank) == 7 and roster.any(func(other): return other != r and str(other.get("status", "")) == "active" and is_jedi(other) and int(other.get("rank", 1)) >= 8): break
		var previous := int(r.rank)
		r.rank = int(r.rank) + 1
		r.title = str(Classes.rank_data(side_name, int(r.rank)).get("title", r.get("title", "")))
		r.tier = str(Classes.rank_data(side_name, int(r.rank)).get("tier", r.title))
		if campaign != null: campaign.rank_advanced(r, previous, int(r.rank))
	r.pick = pending_rank(r)
	return int(r.rank) > before

static func tree_options(r: Dictionary, rank: int) -> Array:
	var tree: Dictionary = Classes.class_data(str(r.get("cls", ""))).get("tree", Data.get_table("research", "TREES").get(str(r.get("cls", "")), {}))
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
		var specs: Dictionary = Classes.class_data(str(r.cls)).get("tree", Data.get_table("research", "TREES").get(str(r.cls), {})).get("specs", {})
		for key in specs:
			if str(specs[key].sig) == pick: r.spec = key
	r.pick = pending_rank(r)
	return true

static func battle_stats(r: Dictionary) -> Dictionary:
	var base: Dictionary = Classes.class_data(str(r.get("cls", ""))).get("base_stats", Data.get_table("core", "CLASS").get(str(r.get("cls", "")), {})).duplicate(true)
	if base.is_empty(): return {}
	for rank in range(2, int(r.get("rank", 1)) + 1):
		var gain: Dictionary = Data.get_table("core", "RANK_GAIN").get(str(rank), {})
		for key in ["hp", "aim", "will"]: base[key] = int(base.get(key, 0)) + int(gain.get(key, 0))
		var special: Dictionary = gain.get("jedi" if is_jedi(r) else "troop", {})
		for key in special:
			if base.has(key): base[key] = int(base[key]) + int(special[key])
	if is_jedi(r) and int(r.get("rank", 1)) >= 5:
		base.hp = int(base.get("hp", 0)) + 2
		base.aim = int(base.get("aim", 0)) + 10
		base.maxF = int(base.get("maxF", 0)) + 2
	var applied := []
	for pick in r.get("picks", []) + r.get("extra_picks", []):
		if pick in applied: continue
		applied.append(pick)
		var perk: Dictionary = Data.get_table("temple", "PERKS").get(str(pick), {})
		_add_mod(base, perk.get("mod", {}))
	return base

static func _add_mod(stats: Dictionary, mod: Dictionary) -> void:
	for key in mod:
		if key == "dmg":
			stats.dmg = [int(stats.dmg[0]) + int(mod[key]), int(stats.dmg[1]) + int(mod[key])]
		elif key == "dmgHi": stats.dmg[1] = int(stats.dmg[1]) + int(mod[key])
		else: stats[key] = int(stats.get(key, 0)) + int(mod[key])

static func battle_abilities(r: Dictionary) -> Array:
	## Merge this into the tactical kit at spawn; passive picks are handled by battle_stats.
	var catalog: Dictionary = Classes.ability_catalog()
	var out := []
	for pick in r.get("picks", []) + r.get("extra_picks", []):
		if catalog.has(pick) and pick not in out: out.append(pick)
	for pick in r.get("cross_picks", []):
		if catalog.has(pick) and pick not in out: out.append(pick)
	if str(r.get("taught_ability", "")) != "" and catalog.has(str(r.taught_ability)): out.append(str(r.taught_ability))
	for legacy in r.get("legacies", []):
		if catalog.has(str(legacy.get("ability", ""))) and str(legacy.ability) not in out: out.append(str(legacy.ability))
	return out

static func cross_options(r: Dictionary) -> Array:
	var out := []
	var primary: Dictionary = Classes.class_data(str(r.get("cls", "")))
	var known: Array = primary.get("kit", []) + primary.get("bonus_kit", []) + r.get("picks", []) + r.get("extra_picks", []) + r.get("cross_picks", [])
	for path_name in r.get("classes", []):
		if Classes.class_id(str(path_name)) == Classes.class_id(str(r.get("cls", ""))): continue
		var row := Classes.class_data(str(path_name))
		for id in row.get("abilities", {}):
			var def: Dictionary = row.get("abilities", {}).get(id, {})
			if def.is_empty() or int(def.get("rank", 1)) > mini(int(r.get("rank", 1)), Classes.ability_cap(r, str(path_name))) or bool(def.get("capstone", false)): continue
			if id not in known and id not in out: out.append(id)
	return out

static func choose_cross(r: Dictionary, id: String) -> bool:
	if id not in cross_options(r): return false
	r.cross_picks.append(id)
	return true
