extends SceneTree
const Classes = preload("res://scripts/class_registry.gd")
const Modules = preload("res://scripts/effects_soldier.gd")
const Chains = preload("res://scripts/ability_chains.gd")
const Mission = preload("res://scripts/mission.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Promotion = preload("res://scripts/campaign/promotion_screen.gd")
const Loadout = preload("res://scripts/combat_loadout.gd")
const BattleBridge = preload("res://scripts/campaign/battle_bridge.gd")
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

func _mechanical_signature(def: Dictionary) -> String:
	var fields := ["effect", "target", "range", "cooldown", "status", "damage", "damage_mod", "shots", "pierce", "bounce", "ignore_cover", "friendly_fire", "clear_overwatch", "droid_damage", "shield", "heal", "aim", "ally_aim", "defense", "distance", "collision_damage", "ends_turn", "chance", "effects", "ap", "cost", "ammo_cost", "crit_mod", "tech", "no_los", "duration", "amount"]
	var signature := {}
	for field in fields:
		if def.has(field) and field != "effects": signature[field] = def[field]
	if def.has("effects"):
		var mechanics := []
		for effect in def.effects:
			var shape: Dictionary = effect.duplicate()
			shape.erase("tag")
			mechanics.append(shape)
		signature.effects = mechanics
	return JSON.stringify(signature)

func _promotion_text(node: Node) -> String:
	var result := ""
	if node is Label: result += node.text + "\n"
	if node is Button: result += node.text + "\n"
	for child in node.get_children(): result += _promotion_text(child)
	return result

func run() -> void:
	check(Classes.validate().is_empty(), "class schema: " + str(Classes.validate()))
	var shipped: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/soldier18_shipped.json"))
	var ids: Dictionary = {}
	var signatures: Dictionary = {}
	var capstone_templates: Dictionary = {}
	var capstone_count := 0
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
		check(row.get("kit", []).has(row.get("signature", "")) or (shipped.has(class_id) and row.tree.trunk["1"].has(row.signature)), class_id + " exposes its signature")
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
				var signature := _mechanical_signature(def)
				check(not signatures.has(signature), id + " distinct mechanical signature")
				signatures[signature] = id
			if bool(def.get("capstone", false)):
				capstone_count += 1
				capstone_templates[str(def.get("capstone_template", ""))] = true
				check(bool(def.get("once_per_mission", false)) and "Once per mission" in str(def.get("description", "")), id + " labelled once per mission")
				check(str(def.get("charges", "")) in ["soldier_capstone", "med_beacon"] and not def.has("cooldown"), id + " uses a mission charge without a long cooldown")
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
	check(signatures.size() == 78, "zero duplicate signatures among 78 new abilities")
	check(capstone_count == 16 and capstone_templates.size() == 8, "sixteen capstones have eight path templates")
	var all_capstones := {}
	var all_capstone_signatures := {}
	var all_capstone_count := 0
	for path in Classes.IDS.soldier:
		for id in Classes.class_data(path).abilities:
			var ability: Dictionary = Classes.class_data(path).abilities[id]
			if not bool(ability.get("capstone", false)): continue
			all_capstone_count += 1
			all_capstones[str(ability.get("capstone_template", ""))] = true
			all_capstone_signatures[_mechanical_signature(ability)] = true
	check(all_capstone_count == 16 and all_capstones.size() == 8 and all_capstone_signatures.size() == 16, "16 distinct capstones use eight class templates")
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
	var module_battle = Mission.new(23)
	module_battle._spawn("droid", 4, 4, -1)
	var battle_droid: Dictionary = module_battle.units.back()
	battle_droid.rid = "u1"
	Loadout.setup(module_battle, campaign.state)
	check("droid_flamer_module" in battle_droid.kit and "droid_shield_module" not in battle_droid.kit, "campaign Droid swap changes battle kit")
	var heavy_recruit: Dictionary = campaign.soldier("u1")
	heavy_recruit.cls = "Heavy"; heavy_recruit.classes = ["heavy"]
	var heavy_pending: Dictionary = campaign.select_mission(0, ["u1", "u2"])
	var heavy_battle: RefCounted = BattleBridge.create(campaign, 24) if not heavy_pending.is_empty() else null
	var heavy_deployed := false
	if heavy_battle != null:
		for member in heavy_battle.living("player"):
			if str(member.get("rid", "")) == "u1": heavy_deployed = str(member.kind) == "heavy_soldier" and "heavy_rocket" in member.kit
	check(heavy_deployed, "Heavy deploys with Rocket and its own chassis")
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
	var mechanics = Mission.new(19)
	var shooter: Dictionary = mechanics.living("player")[0]
	var targets: Array[Dictionary] = mechanics.living("enemy")
	if targets.size() >= 3:
		for i in 3:
			targets[i].x = 5 + i; targets[i].y = 5; targets[i].hp = 20; targets[i].max_hp = 20; targets[i].shield = 0
		shooter.active_ability = "sniper_ricochet"
		mechanics.apply_damage(targets[0], 4, shooter)
		check(int(targets[0].hp) == 16 and int(targets[1].hp) == 18 and int(targets[2].hp) == 20, "Ricochet bounces to exactly one second target")
		shooter.active_ability = "sniper_execution_order"
		targets[0].hp = 10
		mechanics.apply_damage(targets[0], 3, shooter)
		check(int(targets[0].hp) == 4, "Execution Order doubles damage below half HP")
		shooter.active_ability = "tech_override"
		targets[2].droid = true
		mechanics.apply_damage(targets[2], 1, shooter)
		check(str(targets[2].side) == "player" and int(targets[2].hp) == 20, "Override turns a Droid into an ally")
		shooter.erase("active_ability")
	var override_battle = Mission.new(29)
	var tech_actor: Dictionary = override_battle.living("player")[0]
	var hostile_droid: Dictionary = override_battle.living("enemy")[0]
	tech_actor.kit.append("tech_override")
	hostile_droid.droid = true; hostile_droid.awake = true; hostile_droid.spotted = true
	hostile_droid.x = int(tech_actor.x) + 1; hostile_droid.y = int(tech_actor.y)
	check(override_battle.use_ability(int(tech_actor.id), "tech_override", int(hostile_droid.id)) and str(hostile_droid.side) == "player", "Tech Override converts through ability engine")
	var spotter_battle = Mission.new(33)
	var spotter_actor: Dictionary = spotter_battle.living("player")[0]
	var spotter_ally: Dictionary = spotter_battle.living("player")[1]
	var spotter_target: Dictionary = spotter_battle.living("enemy")[0]
	for member in spotter_battle.living("player"): member.ammo = 0
	spotter_actor.ammo = 1
	spotter_ally.ammo = 2
	spotter_actor.kit.append("sniper_spotter_round")
	spotter_target.x = int(spotter_actor.x) + 1; spotter_target.y = int(spotter_actor.y)
	spotter_target.hp = 20; spotter_target.max_hp = 20; spotter_target.shield = 0
	spotter_target.awake = true; spotter_target.spotted = true
	Chains.apply_tag(spotter_target, "EXPOSED")
	spotter_battle.abilities.sniper_spotter_round.chance = 100
	check(spotter_battle.use_ability(int(spotter_actor.id), "sniper_spotter_round", int(spotter_target.id)) and int(spotter_target.hp) <= 17 and int(spotter_ally.ammo) == 1 and not Chains.has_tag(spotter_target, "EXPOSED"), "Spotter Round consumes setup and calls one allied shot")
	var once_battle = Mission.new(31)
	once_battle._spawn("sniper", 4, 4, -1)
	var cap_actor: Dictionary = once_battle.units.back()
	var cap_target: Dictionary = once_battle.living("enemy")[0]
	cap_target.x = 5; cap_target.y = 4; cap_target.awake = true; cap_target.spotted = true
	cap_actor.kit.append("sniper_one_shot")
	once_battle.abilities.sniper_one_shot.chance = 100
	check(int(cap_actor.get("soldier_capstone", 0)) == 1 and once_battle.use_ability(int(cap_actor.id), "sniper_one_shot", int(cap_target.id)), "capstone fires from starter mission charge")
	cap_actor.ap = 2
	check(int(cap_actor.soldier_capstone) == 0 and once_battle.ability_reason(int(cap_actor.id), "sniper_one_shot") == "No charges", "capstone cannot fire twice in one mission")
	var stealth_battle = Mission.new(41, "res://data/maps/h_hetzal.json")
	stealth_battle._spawn("scout", 4, 4, -1)
	var scout_actor: Dictionary = stealth_battle.units.back()
	scout_actor.kit.append("scout_concealment")
	scout_actor.kit.append("scout_vanish")
	check(stealth_battle.use_ability(int(scout_actor.id), "scout_concealment") and bool(scout_actor.concealed), "Scout Concealment survives modern mission wrapper")
	stealth_battle.break_concealment("test")
	scout_actor.ap = 2
	check(stealth_battle.use_ability(int(scout_actor.id), "scout_vanish") and bool(scout_actor.concealed), "Scout Vanish restores concealment")
	var screen := Promotion.new()
	root.add_child(screen)
	var soldier: Dictionary = campaign.soldier("u1")
	soldier.cls = "Sniper"; soldier.classes = ["sniper"]; soldier.pick = 1
	screen.setup(campaign, "u1")
	var promotion_text := _promotion_text(screen)
	check("Squadsight" in promotion_text and "Paths: Sniper" in promotion_text and not "sniper_squadsight" in promotion_text, "promotion shows ability and path names, not ids")
	screen.queue_free()
	soldier.cls = "Droid"; soldier.classes = ["droid"]; soldier.rank = 4
	var module_screen := Promotion.new()
	root.add_child(module_screen)
	module_screen.setup(campaign, "u1")
	var module_text := _promotion_text(module_screen)
	check("DROID MODULES" in module_text and "Slot 1 → Jetpack" in module_text, "Droid module choices are visible")
	check("Train Trooper" in module_text and not "Train Soldier" in module_text, "Droid path picker uses Trooper name")
	module_screen.queue_free()
	print("SOLDIER18: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
