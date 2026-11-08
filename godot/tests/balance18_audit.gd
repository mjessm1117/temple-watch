extends SceneTree
## Shared numeric audit for all fifteen class paths.
const Classes = preload("res://scripts/class_registry.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("BALANCE18: " + label)

func number(value: Variant) -> float:
	if value is Array:
		if value.is_empty(): return 0.0
		var total := 0.0
		for part in value: total += number(part)
		return total / float(value.size())
	return float(value) if value is int or value is float else 0.0

func ability_score(def: Dictionary) -> float:
	# Twelve points are the common value of spending a tactical action. All
	# other terms use the same coefficients regardless of class or rank.
	var damage := number(def.get("damage", 0)) * number(def.get("chance", 100)) / 100.0 * maxf(1.0, number(def.get("shots", 1)))
	damage += number(def.get("collision_damage", 0)) + number(def.get("damage_mod", 0))
	var healing := number(def.get("heal", 0))
	var shields := number(def.get("shield", 0))
	var control := 0.0
	if str(def.get("effect", "")) in ["status", "displace", "wave", "blast"]: control += 1.0
	if def.has("status"): control += 1.0
	for effect in def.get("effects", []):
		if not effect is Dictionary: continue
		match str(effect.get("type", "")):
			"damage": damage += number(effect.get("amount", 0))
			"heal", "repair": healing += number(effect.get("amount", 0))
			"shield": shields += number(effect.get("amount", 0))
			"stun", "hold", "disarm", "tag", "suppress": control += 1.0
	return 12.0 + damage + 0.8 * healing + 0.65 * shields + 2.0 * control

func normalized(value: Variant) -> Variant:
	if value is Dictionary:
		var output := {}
		var keys: Array = value.keys()
		keys.sort()
		for key in keys:
			if str(key) in ["name", "promotion_name", "description", "tag", "tags"]: continue
			if str(key) == "apply" and value[key] is String: continue # Adaptive rider's tag label.
			output[key] = normalized(value[key])
		return output
	if value is Array:
		var output := []
		for item in value: output.append(normalized(item))
		return output
	if value is int or value is float: return "N"
	return value

func median(values: Array[float]) -> float:
	values.sort()
	var middle := values.size() / 2
	return values[middle] if values.size() % 2 else (values[middle - 1] + values[middle]) * 0.5

func tree_rank(row: Dictionary, ability_id: String) -> int:
	var tree: Dictionary = row.get("tree", {})
	for rank_key in tree.get("trunk", {}):
		if ability_id in tree.trunk[rank_key]: return int(rank_key)
	for branch in tree.get("specs", {}).values():
		if str(branch.get("sig", "")) == ability_id: return 3
		for rank_key in ["4", "5", "6", "7", "8"]:
			if ability_id in branch.get(rank_key, []): return int(rank_key)
	return 0

func run() -> void:
	var bands: Dictionary = {}
	var rows: Dictionary = {}
	var signatures: Dictionary = {}
	var count := 0
	var scored := 0
	for side in Classes.IDS:
		for class_id in Classes.IDS[side]:
			var class_row: Dictionary = Classes.class_data(class_id)
			var by_rank: Dictionary = {}
			for ability_id in class_row.get("abilities", {}):
				var def: Dictionary = class_row.abilities[ability_id]
				var rank := int(def.get("rank", tree_rank(class_row, str(ability_id))))
				if str(ability_id).begins_with(class_id + "_"):
					count += 1
					check(rank >= 1 and rank <= (8 if side == "jedi" else 7), ability_id + " has a valid rank")
					var chain: Dictionary = def.get("chain", {})
					var adaptive := false
					for effect in def.get("effects", []):
						if str(effect.get("type", "")) == "adaptive_consume" and str(effect.get("apply", "")) != "": adaptive = true
					check(adaptive or not chain.get("apply", []).is_empty() or not chain.get("consume", []).is_empty(), ability_id + " applies or consumes a tag")
					var signature := JSON.stringify(normalized(def))
					check(not signatures.has(signature), ability_id + " unique structure vs " + str(signatures.get(signature, "")))
					signatures[signature] = ability_id
				if rank < 1: continue # Unranked base kit, not a promotion choice.
				scored += 1
				var score := ability_score(def)
				if not by_rank.has(rank): by_rank[rank] = []
				by_rank[rank].append(score)
				if not bands.has(rank): bands[rank] = []
				bands[rank].append({"id": ability_id, "score": score})
			var cumulative := 0.0
			var collected := 0
			var scores: Array[float] = []
			for rank in range(1, 9 if side == "jedi" else 8):
				for score in by_rank.get(rank, []):
					cumulative += float(score); collected += 1
				var power := float(Classes.power(side, rank)) + cumulative / maxf(1.0, float(collected))
				scores.append(snappedf(power, 0.1))
				if scores.size() > 1: check(scores[-1] >= scores[-2], class_id + " non-decreasing at rank " + str(rank))
			rows[class_id] = scores
	check(count == 176 and signatures.size() == 176, "176 unique class-prefixed abilities")
	check(scored == 202, "all 202 ranked promotion definitions scored")
	for rank in bands:
		var values: Array[float] = []
		for entry in bands[rank]: values.append(float(entry.score))
		var middle := median(values)
		for entry in bands[rank]:
			check(float(entry.score) <= middle * 1.6 + 0.0001, "%s score %.2f exceeds rank %d median %.2f x1.6" % [entry.id, entry.score, rank, middle])
	for soldier_id in Classes.IDS.soldier:
		for jedi_id in Classes.IDS.jedi:
			check(rows[soldier_id][0] > rows[jedi_id][0], soldier_id + " rank 1 beats " + jedi_id + " Padawan I")
			check(rows[soldier_id][2] > rows[jedi_id][2], soldier_id + " rank 3 beats " + jedi_id + " Knight I")
			check(rows[jedi_id][4] > rows[soldier_id][4], jedi_id + " Master I beats " + soldier_id + " rank 5")
			for ability_id in Classes.class_data(soldier_id).get("abilities", {}):
				var capstone: Dictionary = Classes.class_data(soldier_id).abilities[ability_id]
				if int(capstone.get("rank", 0)) != 7 or not bool(capstone.get("capstone", false)): continue
				var capstone_power := float(Classes.power("soldier", 7)) + ability_score(capstone)
				check(rows[jedi_id][7] > capstone_power, jedi_id + " Grand Master beats " + ability_id)
	for class_id in rows:
		print("BALANCE18 POWER %s %s" % [class_id, JSON.stringify(rows[class_id])])
	print("BALANCE18 UNIQUENESS: %d/%d distinct; all chain; %d ranked abilities scored; %d checks, %d failures" % [signatures.size(), count, scored, checks, failures])
	quit(1 if failures else 0)
