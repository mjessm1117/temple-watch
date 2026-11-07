extends SceneTree
const Classes = preload("res://scripts/class_registry.gd")
const Chains = preload("res://scripts/ability_chains.gd")
const Mission = preload("res://scripts/mission.gd")
const PATHS := ["guardian", "knight", "duelist", "sage", "consular", "sentinel", "wayseeker"]
const TAGS := ["ATTUNED", "BURNING", "EXPOSED", "INSPIRED", "IONIZED", "LIFTED", "MARKED", "PINNED", "READY", "SHIELDED", "STAGGERED", "TAUNTED"]
const SHARED_LEGACY := ["shoot", "overwatch", "mark", "deadeye", "hack", "scan", "shieldDrone", "rapidFire", "rally", "hunker", "strike", "push", "meditate", "choke", "subdue", "disarm", "guard", "pull", "breach"]
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("JEDI18: " + label)

func _signature(def: Dictionary) -> String:
	var result := def.duplicate(true)
	for key in ["name", "rank", "capstone"]: result.erase(key)
	return JSON.stringify(result)

func run() -> void:
	check(Classes.validate().is_empty(), "all 15 class schemas: " + str(Classes.validate()))
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/jedi18_legacy.json"))
	var all_ids: Dictionary = {}
	var all_signatures: Dictionary = {}
	var total_new := 0
	for side in Classes.IDS:
		for id in Classes.IDS[side]:
			var row: Dictionary = Classes.class_data(id)
			check(not row.is_empty(), "class exists: " + id)
			for ability_id in row.abilities:
				var def: Dictionary = row.abilities[ability_id]
				if all_ids.has(ability_id):
					check(ability_id in SHARED_LEGACY and all_ids[ability_id] == def, "no conflicting or new duplicate ID: " + ability_id)
				else: all_ids[ability_id] = def
			if side != "jedi": continue
			check(bool(row.implemented) and not row.unit_stats.is_empty() and not row.base_stats.is_empty(), id + " playable tactical and campaign data")
			check(str(row.unit_kind) == id and row.kit.size() >= 2, id + " unit kind and kit")
			for old_id in legacy[id]: check(row.abilities.get(old_id, {}) == legacy[id][old_id], id + "/" + old_id + " shipped definition unchanged")
			var picks: Array = row.tree.trunk.get("1", []) + row.tree.trunk.get("2", [])
			for spec in row.tree.specs.values():
				picks.append(spec.sig)
				for rank in range(4, 8): picks.append_array(spec.get(str(rank), []))
			var unique_picks: Dictionary = {}
			for pick in picks: unique_picks[pick] = true
			check(picks.size() == 13 and unique_picks.size() == 13, id + " has 13 distinct rank 1–7 choices")
			check(str(row.signature).begins_with(id + "_") and picks.has(row.signature), id + " new signature in tree")
			var applied: Dictionary = {}
			var consumed: Dictionary = {}
			var gm := ""
			for ability_id in row.abilities:
				if not str(ability_id).begins_with(id + "_"): continue
				total_new += 1
				var def: Dictionary = row.abilities[ability_id]
				check(def.has("rank") and def.has("chain"), ability_id + " ranked chain ability")
				if int(def.rank) <= 7: check(picks.has(ability_id), ability_id + " appears in promotion tree")
				if int(def.rank) == 8:
					gm = ability_id
					check(bool(def.get("capstone", false)) and int(def.get("cooldown", 0)) >= 90, ability_id + " limited Grand Master signature")
				for entry in def.chain.get("apply", []):
					check(str(entry.tag) in TAGS, ability_id + " applies shared tag")
					applied[str(entry.tag)] = true
				for entry in def.chain.get("consume", []):
					check(str(entry.tag) in TAGS, ability_id + " consumes shared tag")
					consumed[str(entry.tag)] = true
				var signature := _signature(def)
				check(not all_signatures.has(signature), ability_id + " unique effect and number pattern")
				all_signatures[signature] = ability_id
			check(applied.size() >= 3 and consumed.size() >= 3, id + " applies and consumes at least three shared tags")
			check(gm != "" and row.tree.specs.values().all(func(spec): return spec.get("8", []) == [gm]), id + " both branches award one Grand Master signature")
	check(total_new == 98, "seven paths have 13 choices and one Grand Master ability each")
	check(Classes.power("jedi", 1) < Classes.power("soldier", 1), "Padawan below fresh soldier")
	check(Classes.power("jedi", 5) > Classes.power("soldier", 7) and Classes.power("jedi", 8) == 420, "Master and Grand Master power curve")
	check(Classes.rank_data("jedi", 1).get("starting_kit", []) == ["strike", "guard"], "Padawan starts with two basics")
	var m = Mission.new(18)
	var actor: Dictionary = m.living("player")[0]
	var enemy: Dictionary = m.living("enemy")[0]
	for path in ["knight", "duelist", "sage"]:
		m._spawn(path, int(actor.x), int(actor.y), -1)
		var deployed: Dictionary = m.units.back()
		check(str(deployed.kind) == path and deployed.kit.has("strike") and deployed.kit.has("guard") and m.abilities.has(Classes.class_data(path).signature), path + " can deploy with its signature in the catalog")
	Chains.apply_tag(enemy, "PINNED", int(actor.id))
	Chains.resolve(m, actor, enemy, Vector2i.ZERO, Classes.class_data("guardian").abilities.guardian_djem_so_riposte)
	check(Chains.has_tag(enemy, "STAGGERED") and not Chains.has_tag(enemy, "PINNED") and int(m.chain_momentum) == 1, "Guardian consumes squad PINNED and applies STAGGERED")
	actor.ap = 1
	enemy.hp = 0
	Chains.apply_tag(enemy, "EXPOSED", int(actor.id))
	Chains.resolve(m, actor, enemy, Vector2i.ZERO, Classes.class_data("duelist").abilities.duelist_kill_chain)
	check(int(actor.ap) == 2 and int(m.chain_momentum) == 2, "Duelist kill refunds one action and advances Momentum")
	Chains.resolve(m, actor, enemy, Vector2i.ZERO, Classes.class_data("duelist").abilities.duelist_kill_chain)
	check(int(actor.ap) == 2, "kill refund limited to once per turn")
	var live = Mission.new(19)
	var duelist: Dictionary = live.living("player")[0]
	var victim: Dictionary = live.living("enemy")[0]
	var adjacent := Vector2i(int(duelist.x), int(duelist.y))
	for delta in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var candidate: Vector2i = Vector2i(int(duelist.x), int(duelist.y)) + delta
		if live.passable(candidate): adjacent = candidate; break
	victim.x = adjacent.x; victim.y = adjacent.y
	victim.hp = 1; victim.shield = 0; victim.armor = 0; victim.awake = true; victim.spotted = true
	duelist.kit.append("duelist_kill_chain")
	duelist.ap = 2
	live.abilities.duelist_kill_chain.chance = 100
	check(live.use_ability(int(duelist.id), "duelist_kill_chain", int(victim.id)) and int(duelist.ap) == 1, "real killing blow leaves refunded AP")
	var convert: Dictionary = live.living("enemy")[0]
	convert.x = adjacent.x; convert.y = adjacent.y
	convert.awake = true; convert.spotted = true
	duelist.kit.append("consular_mind_trick")
	duelist.ap = 2; duelist.focus_left = 3
	live.abilities.consular_mind_trick.chance = 100
	Chains.apply_tag(convert, "STAGGERED", int(duelist.id))
	check(live.use_ability(int(duelist.id), "consular_mind_trick", int(convert.id)) and bool(convert.get("tricked", false)) and int(live.chain_momentum) >= 1, "Mind Trick turns a staggered foe and advances Momentum")
	var switcher: Dictionary = live.living("player")[0]
	Chains.resolve(live, switcher, {}, Vector2i.ZERO, Classes.class_data("knight").abilities.knight_form_switch)
	check(str(switcher.get("jedi_form", "")) == "force_adept" and int(switcher.buff_aim) == 8, "Form Switch enters Force Adept stance")
	Chains.resolve(live, switcher, {}, Vector2i.ZERO, Classes.class_data("knight").abilities.knight_form_switch)
	check(str(switcher.get("jedi_form", "")) == "shii_cho" and int(switcher.buff_defense) == 8, "Form Switch returns to Shii-Cho stance")
	var adaptive: Dictionary = live.living("enemy")[0]
	adaptive.hp = 10; adaptive.max_hp = 10
	adaptive.combo_tags = {}
	Chains.apply_tag(adaptive, "BURNING", int(switcher.id))
	Chains.resolve(live, switcher, adaptive, Vector2i.ZERO, Classes.class_data("knight").abilities.knight_adaptive_mastery)
	check(not Chains.has_tag(adaptive, "BURNING") and Chains.has_tag(adaptive, "STAGGERED"), "Adaptive Mastery consumes any existing tag before applying its own")
	print("JEDI18 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
