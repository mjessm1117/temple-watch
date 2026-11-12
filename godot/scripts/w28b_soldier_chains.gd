extends RefCounted
## Shared wording for the Soldier rank tree's squad tag contract.
const CLASSES = ["trooper", "scout", "medic"]

static func ranked_ids(row: Dictionary) -> Array:
	var tree: Dictionary = row.get("tree", {})
	var out: Array = []
	for rank in ["1", "2"]:
		out.append_array(tree.get("trunk", {}).get(rank, []))
	for branch in tree.get("specs", {}).values():
		out.append(branch.get("sig", ""))
		for rank in ["4", "5", "6", "7"]:
			out.append_array(branch.get(rank, []))
	return out

static func effect_signature(def: Dictionary) -> String:
	var fields := ["effect", "target", "range", "cooldown", "status", "damage", "damage_mod", "shots", "pierce", "ignore_cover", "friendly_fire", "clear_overwatch", "shield", "heal", "aim", "ally_aim", "defense", "ends_turn", "chance", "effects", "ap", "cost", "ammo_cost", "crit_mod", "no_los", "duration", "amount", "chain"]
	var signature := {}
	for field in fields:
		if def.has(field): signature[field] = def[field]
	return JSON.stringify(signature)
