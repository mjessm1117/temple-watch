extends SceneTree
const Classes = preload("res://scripts/class_registry.gd")
const Chains = preload("res://scripts/ability_chains.gd")
const SoldierChains = preload("res://scripts/w28b_soldier_chains.gd")
const Mission = preload("res://scripts/mission.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("SOLDIER28: " + label)

func _tags(entries: Array) -> Dictionary:
	var out := {}
	for entry in entries:
		out[str(entry.get("tag", ""))] = true
	return out

func _battle_combo(class_id: String, setup_id: String, finish_id: String, tag: String, droid: bool = false) -> void:
	var battle = Mission.new(280)
	var allies: Array[Dictionary] = battle.living("player")
	var enemies: Array[Dictionary] = battle.living("enemy")
	check(allies.size() >= 2 and not enemies.is_empty(), class_id + " battle actors exist")
	if allies.size() < 2 or enemies.is_empty(): return
	var setter: Dictionary = allies[0]
	var finisher: Dictionary = allies[1]
	var target: Dictionary = enemies[0]
	setter.kit.append(setup_id)
	finisher.kit.append(finish_id)
	setter.class_name = class_id.capitalize()
	finisher.class_name = class_id.capitalize()
	target.x = int(setter.x) + 1
	target.y = int(setter.y)
	target.hp = 100
	target.max_hp = 100
	target.shield = 0
	target.awake = true
	target.spotted = true
	if droid: target.droid = true
	battle.abilities[setup_id].chance = 100
	battle.abilities[finish_id].chance = 100
	check(battle.use_ability(int(setter.id), setup_id, int(target.id)), class_id + " setup fires in battle")
	check(Chains.has_tag(target, tag) and int(Chains.tags(target)[tag]) == int(setter.id), class_id + " first soldier applies " + tag)
	var before: int = int(battle.chain_momentum)
	check(battle.use_ability(int(finisher.id), finish_id, int(target.id)), class_id + " finisher fires in battle")
	check(not Chains.has_tag(target, tag) and int(battle.chain_momentum) > before, class_id + " second soldier consumes " + tag)

func run() -> void:
	check(Classes.validate().is_empty(), "class schema valid: " + str(Classes.validate()))
	for class_id in SoldierChains.CLASSES:
		var row: Dictionary = Classes.class_data(class_id)
		var ids: Array = SoldierChains.ranked_ids(row)
		check(ids.size() == 13, class_id + " has 13 ranked choices")
		var seen_ids := {}
		var signatures := {}
		for id in ids:
			var key := str(id)
			check(not seen_ids.has(key), class_id + " ranked id unique: " + key)
			seen_ids[key] = true
			check(row.abilities.has(key), class_id + " ranked definition exists: " + key)
			if not row.abilities.has(key): continue
			var def: Dictionary = row.abilities[key]
			check(def.has("chain") and not def.get("chain", {}).is_empty(), key + " has a chain")
			var signature := SoldierChains.effect_signature(def)
			check(not signatures.has(signature), class_id + " effect signature unique: " + key)
			signatures[signature] = key
			var apply := _tags(def.get("chain", {}).get("apply", []))
			var consume := _tags(def.get("chain", {}).get("consume", []))
			var self_chain := false
			for tag in apply:
				if consume.has(tag): self_chain = true
			check(not self_chain, key + " does not chain with itself")
	_battle_combo("trooper", "suppress", "rapidFire", "PINNED")
	_battle_combo("scout", "mark", "deadeye", "MARKED")
	_battle_combo("medic", "medic_toxin_dart", "protocol", "STAGGERED", true)
	check(FileAccess.get_sha256("res://data/classes/soldier/droid.json") == "1a61844eb578895b786c8bdaab7de88cb91094306dec67d143ddd28c2a1f3165", "Droid modules match base SHA")
	print("SOLDIER28: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
