extends SceneTree
const Classes = preload("res://scripts/class_registry.gd")
const Modules = preload("res://scripts/effects_soldier.gd")
const Chains = preload("res://scripts/ability_chains.gd")
const Mission = preload("res://scripts/mission.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const TAGS = ["ATTUNED", "BURNING", "EXPOSED", "INSPIRED", "IONIZED", "LIFTED", "MARKED", "PINNED", "READY", "SHIELDED", "STAGGERED", "TAUNTED"]
const PROXY_KITS = ["shoot", "overwatch", "mark", "deadeye", "hack", "scan", "shieldDrone", "rapidFire", "rally", "barrage", "holdLine"]
const PROXY_CLASSES = ["heavy", "sniper", "tech", "droid", "officer"]
const LEGACY_REUSED = ["hunker", "overwatch", "shoot", "strike", "push", "meditate", "choke", "subdue", "disarm", "guard", "pull", "breach"]
const SHIPPED_KITS = {"trooper":["shoot","overwatch","hunker","suppress","rapidFire","rally"],"scout":["shoot","overwatch","mark","runGun","deadeye"],"medic":["shoot","overwatch","heal","smoke","hack","reviveStim","protocol","shieldDrone","hackDroid","scan"]}
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("SOLDIER18: " + label)

func _tag(entry: Variant) -> String:
	return str(entry.get("tag", "")) if entry is Dictionary else str(entry)

func run() -> void:
	check(Classes.validate().is_empty(), "class schema: " + str(Classes.validate()))
	var shipped: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/soldier18_shipped.json"))
	var ids: Dictionary = {}
	var signatures: Dictionary = {}
	var total := 0
	for side in Classes.IDS:
		for class_id in Classes.IDS[side]:
			var row: Dictionary = Classes.class_data(class_id)
			for id in row.get("abilities", {}):
				if not ids.has(id): ids[id] = []
				ids[id].append(class_id)
	for id in ids:
		if ids[id].size() > 1: check(id in LEGACY_REUSED, id + " is a pre-existing shared ID")
	for class_id in Classes.IDS.soldier:
		var row: Dictionary = Classes.class_data(class_id)
		var abilities: Dictionary = row.get("abilities", {})
		total += abilities.size()
		check(row.get("schema") == 1 and row.get("implemented") == true, class_id + " valid implementation")
		check(abilities.size() == 13, class_id + " has 13 abilities")
		check(row.get("kit", []).has(row.get("signature", "")), class_id + " starts with signature")
		var applies: Dictionary = {}
		var consumes: Dictionary = {}
		for id in abilities:
			var def: Dictionary = abilities[id]
			for entry in def.get("chain", {}).get("apply", []):
				var tag := _tag(entry)
				check(tag in TAGS, id + " applies known tag")
				applies[tag] = true
			for entry in def.get("chain", {}).get("consume", []):
				var tag := _tag(entry)
				check(tag in TAGS, id + " consumes known tag")
				consumes[tag] = true
			if str(id).begins_with(class_id + "_"):
				check(ids[id].size() == 1, id + " unique across 15 class files")
				var signature := JSON.stringify({"effect":def.get("effect"), "target":def.get("target"), "range":def.get("range"), "damage":def.get("damage"), "damage_mod":def.get("damage_mod"), "chain":def.get("chain")})
				check(not signatures.has(signature), id + " distinct effect signature")
				signatures[signature] = id
		check(applies.size() >= 3 and consumes.size() >= 3, class_id + " chains at least three tags each way")
		if class_id in PROXY_CLASSES:
			check(str(row.signature).begins_with(class_id + "_"), class_id + " owns its signature")
			check(row.kit.all(func(id): return id not in PROXY_KITS), class_id + " has no proxy kit")
		if shipped.has(class_id):
			check(SHIPPED_KITS[class_id].all(func(id): return row.kit.has(id)), class_id + " keeps every shipped tactical button")
			for id in shipped[class_id]:
				var preserved := abilities.has(id)
				if preserved:
					for field in shipped[class_id][id]:
						if not abilities[id].has(field) or abilities[id][field] != shipped[class_id][id][field]: preserved = false
				check(preserved, class_id + " keeps shipped values for " + id)
		for branch in row.tree.specs.values():
			for id in branch["7"]: check(bool(abilities[id].get("capstone", false)), class_id + " rank 7 capstone " + id)
	check(total == 104, "104 soldier abilities")
	var droid: Dictionary = Classes.class_data("droid")
	var data: Dictionary = droid.get("modules", {})
	check(int(data.get("slots", 0)) == 3 and data.get("choices", {}).size() == 6, "three slots and six modules")
	var unit := {"cls":"Droid"}
	check(Modules.module_abilities(unit).size() == 3, "default three module abilities")
	check(Modules.swap_module(unit, 1, "flamer"), "swap Shield for Flamer")
	check(Modules.selected_modules(unit) == ["repeater", "flamer", "sensor"], "module swap stored")
	check(Modules.module_abilities(unit).has("droid_flamer_module") and not Modules.module_abilities(unit).has("droid_shield_module"), "swapped module changes kit")
	check(not Modules.swap_module(unit, 0, "sensor"), "duplicate module rejected")
	var campaign = Campaign.new()
	var saved_droid: Dictionary = campaign.soldier("u1")
	saved_droid.cls = "Droid"
	check(Modules.swap_module(saved_droid, 1, "flamer"), "campaign Droid swaps a module")
	var save_path := "user://soldier18-modules.json"
	var restored = Campaign.new()
	check(campaign.save(save_path) and restored.load_save(save_path), "Droid module save loads")
	check(Modules.selected_modules(restored.soldier("u1")) == ["repeater", "flamer", "sensor"], "Droid module load preserves swap")
	var body := {"class_name":"Droid", "hp":5, "shield":2, "ap":2, "overwatch":true}
	check(Modules.damage_amount(body, 10) == 6 and body.wrecked and body.ap == 0, "lethal damage wrecks recoverable droid")
	check(Classes.power("soldier", 1) > Classes.power("jedi", 1) and Classes.power("soldier", 1) > Classes.power("jedi", 3), "fresh soldier beats Padawan and under-trained Knight")
	check(Classes.power("jedi", 5) > Classes.power("soldier", 7), "Master outgrows Commander")
	var mission = Mission.new(18)
	check(mission.catalog.has("heavy_soldier") and mission.catalog["heavy_soldier"].side == "player", "Heavy catalog is a player class")
	for class_id in PROXY_CLASSES:
		for id in Classes.class_data(class_id).kit: check(mission.abilities.has(id), class_id + " kit ability loads in battle")
	var actor: Dictionary = mission.living("player")[0]
	var enemy: Dictionary = mission.living("enemy")[0]
	var enemy_tile := Vector2i(int(enemy.x), int(enemy.y))
	Chains.resolve(mission, actor, enemy, enemy_tile, Classes.class_data("tech").abilities.tech_emp_burst)
	check(Chains.has_tag(enemy, "IONIZED"), "Tech EMP primes Heavy")
	Chains.resolve(mission, actor, enemy, enemy_tile, Classes.class_data("heavy").abilities.heavy_rocket)
	check(not Chains.has_tag(enemy, "IONIZED") and int(mission.chain_momentum) >= 1, "Heavy Rocket consumes Tech ionization")
	Chains.resolve(mission, actor, enemy, enemy_tile, Classes.class_data("officer").abilities.officer_command_mark)
	check(Chains.has_tag(enemy, "MARKED"), "Officer primes Scout")
	Chains.resolve(mission, actor, enemy, enemy_tile, Classes.class_data("scout").abilities.scout_ambush)
	check(not Chains.has_tag(enemy, "MARKED") and int(mission.chain_momentum) >= 2, "Scout Ambush consumes Officer mark")
	enemy.hp = int(enemy.max_hp)
	actor.kit.append("sniper_squadsight")
	actor.class_name = "Sniper"
	enemy.x = int(actor.x) + 2
	enemy.y = int(actor.y)
	enemy.awake = true
	enemy.spotted = true
	check(mission.use_ability(int(actor.id), "sniper_squadsight", int(enemy.id)), "Squadsight fires through tactical engine")
	print("SOLDIER18: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
