extends SceneTree
const Classes = preload("res://scripts/class_registry.gd")
const Chains = preload("res://scripts/ability_chains.gd")
const Mission = preload("res://scripts/mission.gd")
const Promotion = preload("res://scripts/campaign/promotion_screen.gd")
const PATHS := ["guardian", "knight", "duelist", "sage", "consular", "sentinel", "wayseeker"]
const TAGS := ["ATTUNED", "BURNING", "EXPOSED", "INSPIRED", "IONIZED", "LIFTED", "MARKED", "PINNED", "READY", "SHIELDED", "STAGGERED", "TAUNTED"]
const SHARED_LEGACY := ["shoot", "overwatch", "mark", "deadeye", "hack", "scan", "shieldDrone", "rapidFire", "rally", "hunker", "strike", "push", "meditate", "choke", "subdue", "disarm", "guard", "pull", "breach"]
# A30 intentionally refreshed these 49 pinned legacy ability definitions.
const A30_LEGACY_OVERRIDES := """
{
  "guardian": {
    "strike": {"chain":{"consume":[{"tag":"MARKED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"EXPOSED","target":"target"}]},"description":"Hit MARKED foes; EXPOSED primes the next attack."},
    "guard": {"chain":{"consume":[{"tag":"ATTUNED","target":"self","bonus":[{"type":"shield","target":"self","amount":2}]}],"apply":[{"tag":"SHIELDED","target":"self"}]},"description":"Spend ATTUNED; apply SHIELDED to yourself."},
    "push": {"chain":{"consume":[{"tag":"EXPOSED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"PINNED","target":"target"},{"tag":"MARKED","target":"target"}]},"description":"Push an EXPOSED foe; leave it PINNED and MARKED."},
    "meditate": {"chain":{"consume":[{"tag":"SHIELDED","target":"self","bonus":[{"type":"focus","target":"self","amount":1}]}],"apply":[{"tag":"ATTUNED","target":"self"},{"tag":"READY","target":"self"},{"tag":"INSPIRED","target":"self"}]},"description":"Spend SHIELDED; gain ATTUNED, READY, INSPIRED."},
    "saberThrow": {"chain":{"consume":[{"tag":"MARKED","target":"target","bonus":[{"type":"damage","target":"target","amount":3}]}],"apply":[{"tag":"PINNED","target":"target"}]},"description":"Strike a MARKED foe; leave it PINNED."},
    "leap": {"chain":{"consume":[{"tag":"ATTUNED","target":"self","bonus":[{"type":"shield","target":"self","amount":1}]}],"apply":[{"tag":"READY","target":"self"}]},"description":"Spend ATTUNED; gain READY for the landing."},
    "sweep": {"chain":{"consume":[{"tag":"READY","target":"self","bonus":[{"type":"shield","target":"self","amount":2}]}],"apply":[{"tag":"SHIELDED","target":"self"}]},"description":"Spend READY; gain SHIELDED while sweeping."},
    "choke": {"chain":{"consume":[{"tag":"PINNED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"STAGGERED","target":"target"}]},"description":"Choke a PINNED foe; leave it STAGGERED."},
    "subdue": {"chain":{"consume":[{"tag":"STAGGERED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"PINNED","target":"target"}]},"description":"Restrain a STAGGERED target; leave it PINNED."},
    "collapse": {"chain":{"consume":[{"tag":"ATTUNED","target":"self","bonus":[{"type":"shield","target":"self","amount":3}]}],"apply":[{"tag":"INSPIRED","target":"self"}]},"description":"Spend ATTUNED; gain INSPIRED as walls fall."},
    "defLine": {"chain":{"consume":[{"tag":"INSPIRED","target":"self","bonus":[{"type":"shield","target":"self","amount":1}]}],"apply":[{"tag":"SHIELDED","target":"self"}]},"description":"Spend INSPIRED; apply SHIELDED while defending."},
    "reflectM": {"chain":{"consume":[{"tag":"SHIELDED","target":"self","bonus":[{"type":"focus","target":"self","amount":1}]}],"apply":[{"tag":"ATTUNED","target":"self"}]},"description":"Spend SHIELDED; gain ATTUNED on the return."},
    "flurry": {"chain":{"consume":[{"tag":"PINNED","target":"target","bonus":[{"type":"damage","target":"target","amount":1}]}],"apply":[{"tag":"MARKED","target":"target"}]},"description":"Follow a PINNED foe; apply MARKED for the next strike."},
    "mightyBlow": {"chain":{"consume":[{"tag":"TAUNTED","target":"target","bonus":[{"type":"damage","target":"target","amount":1}]}],"apply":[{"tag":"STAGGERED","target":"target"}]},"description":"Break a TAUNTED foe; leave it STAGGERED."},
    "precisionStrike": {"chain":{"consume":[{"tag":"EXPOSED","target":"target","bonus":[{"type":"damage","target":"target","amount":3}]}],"apply":[{"tag":"STAGGERED","target":"target"}]},"description":"Exploit EXPOSED prey; leave it STAGGERED."}
  },
  "consular": {
    "strike": {"chain":{"consume":[{"tag":"MARKED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"EXPOSED","target":"target"}]},"description":"Hit MARKED foes; EXPOSED primes the next attack."},
    "push": {"chain":{"consume":[{"tag":"EXPOSED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"PINNED","target":"target"},{"tag":"MARKED","target":"target"}]},"description":"Push an EXPOSED foe; leave it PINNED and MARKED."},
    "meditate": {"chain":{"consume":[{"tag":"SHIELDED","target":"self","bonus":[{"type":"focus","target":"self","amount":1}]}],"apply":[{"tag":"ATTUNED","target":"self"},{"tag":"READY","target":"self"},{"tag":"INSPIRED","target":"self"}]},"description":"Spend SHIELDED; gain ATTUNED, READY, INSPIRED."},
    "stun": {"chain":{"consume":[{"tag":"MARKED","target":"target","bonus":[{"type":"damage","target":"target","amount":1}]}],"apply":[{"tag":"STAGGERED","target":"target"}]},"description":"Stun a MARKED foe; leave it STAGGERED."},
    "forceHeal": {"chain":{"consume":[{"tag":"INSPIRED","target":"target","bonus":[{"type":"shield","target":"target","amount":2}]}],"apply":[{"tag":"SHIELDED","target":"target"}]},"description":"Heal an INSPIRED ally; leave it SHIELDED."},
    "barrier": {"chain":{"consume":[{"tag":"ATTUNED","target":"target","bonus":[{"type":"shield","target":"target","amount":2}]}],"apply":[{"tag":"SHIELDED","target":"target"}]},"description":"Reinforce an ATTUNED ally; grant SHIELDED."},
    "battleMed": {"chain":{"consume":[{"tag":"READY","target":"self","bonus":[{"type":"shield","target":"all_allies","amount":2}]}],"apply":[{"tag":"INSPIRED","target":"all_allies"}]},"description":"Spend READY; INSPIRED allies gain the aura."},
    "mindTrick": {"chain":{"consume":[{"tag":"EXPOSED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"STAGGERED","target":"target"}]},"description":"Disrupt EXPOSED foes; leave them STAGGERED."},
    "forceRevive": {"chain":{"consume":[{"tag":"READY","target":"self","bonus":[]}],"apply":[{"tag":"INSPIRED","target":"target"}]},"description":"Spend READY; revive an ally with INSPIRED."},
    "choke": {"chain":{"consume":[{"tag":"PINNED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"STAGGERED","target":"target"}]},"description":"Choke a PINNED foe; leave it STAGGERED."},
    "subdue": {"chain":{"consume":[{"tag":"STAGGERED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"PINNED","target":"target"}]},"description":"Restrain a STAGGERED target; leave it PINNED."},
    "massHeal": {"chain":{"consume":[{"tag":"BURNING","target":"all_allies","bonus":[{"type":"shield","target":"target","amount":3}]}],"apply":[{"tag":"SHIELDED","target":"all_allies"}]},"description":"Cleanse BURNING allies; apply SHIELDED to the squad."},
    "forceWave": {"chain":{"consume":[{"tag":"READY","target":"self","bonus":[{"type":"focus","target":"self","amount":1}]}],"apply":[{"tag":"ATTUNED","target":"self"}]},"description":"Spend READY; gain ATTUNED from the force wave."},
    "stasisField": {"chain":{"consume":[{"tag":"ATTUNED","target":"self","bonus":[{"type":"focus","target":"self","amount":1}]}],"apply":[{"tag":"READY","target":"self"}]},"description":"Stasis stuns foes; spend ATTUNED, gain READY."},
    "disarm": {"chain":{"consume":[{"tag":"MARKED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"PINNED","target":"target"}]},"description":"Disarm a MARKED foe; leave it PINNED."}
  },
  "sentinel": {
    "strike": {"chain":{"consume":[{"tag":"MARKED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"EXPOSED","target":"target"}]},"description":"Hit MARKED foes; EXPOSED primes the next attack."},
    "guard": {"chain":{"consume":[{"tag":"ATTUNED","target":"self","bonus":[{"type":"shield","target":"self","amount":2}]}],"apply":[{"tag":"SHIELDED","target":"self"}]},"description":"Spend ATTUNED; apply SHIELDED to yourself."},
    "meditate": {"chain":{"consume":[{"tag":"SHIELDED","target":"self","bonus":[{"type":"focus","target":"self","amount":1}]}],"apply":[{"tag":"ATTUNED","target":"self"},{"tag":"READY","target":"self"},{"tag":"INSPIRED","target":"self"}]},"description":"Spend SHIELDED; gain ATTUNED, READY, INSPIRED."},
    "shadowStep": {"chain":{"consume":[{"tag":"INSPIRED","target":"self","bonus":[{"type":"shield","target":"self","amount":1}]}],"apply":[{"tag":"SHIELDED","target":"self"}]},"description":"Spend INSPIRED; gain SHIELDED while cloaked."},
    "disarm": {"chain":{"consume":[{"tag":"MARKED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"PINNED","target":"target"}]},"description":"Disarm a MARKED foe; leave it PINNED."},
    "pull": {"chain":{"consume":[{"tag":"STAGGERED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"EXPOSED","target":"target"}]},"description":"Pull a STAGGERED foe; leave it EXPOSED."},
    "breach": {"chain":{"consume":[{"tag":"INSPIRED","target":"self","bonus":[{"type":"shield","target":"self","amount":1}]}],"apply":[{"tag":"SHIELDED","target":"self"}]},"description":"Spend INSPIRED; gain SHIELDED at the breach."},
    "sense": {"chain":{"consume":[{"tag":"ATTUNED","target":"self","bonus":[{"type":"focus","target":"self","amount":1}]}],"apply":[{"tag":"READY","target":"self"}]},"description":"Spend ATTUNED; gain READY after the scan."},
    "executioner": {"chain":{"consume":[{"tag":"SHIELDED","target":"self","bonus":[{"type":"focus","target":"self","amount":1}]}],"apply":[{"tag":"ATTUNED","target":"self"}]},"description":"Spend SHIELDED; gain ATTUNED for wounded prey."}
  },
  "wayseeker": {
    "strike": {"chain":{"consume":[{"tag":"MARKED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"EXPOSED","target":"target"}]},"description":"Hit MARKED foes; EXPOSED primes the next attack."},
    "guard": {"chain":{"consume":[{"tag":"ATTUNED","target":"self","bonus":[{"type":"shield","target":"self","amount":2}]}],"apply":[{"tag":"SHIELDED","target":"self"}]},"description":"Spend ATTUNED; apply SHIELDED to yourself."},
    "meditate": {"chain":{"consume":[{"tag":"SHIELDED","target":"self","bonus":[{"type":"focus","target":"self","amount":1}]}],"apply":[{"tag":"ATTUNED","target":"self"},{"tag":"READY","target":"self"},{"tag":"INSPIRED","target":"self"}]},"description":"Spend SHIELDED; gain ATTUNED, READY, INSPIRED."},
    "beastCalm": {"chain":{"consume":[{"tag":"STAGGERED","target":"target","bonus":[{"type":"damage","target":"target","amount":1}]}],"apply":[{"tag":"EXPOSED","target":"target"}]},"description":"Calm a STAGGERED creature; leave it EXPOSED."},
    "pull": {"chain":{"consume":[{"tag":"STAGGERED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"EXPOSED","target":"target"}]},"description":"Pull a STAGGERED foe; leave it EXPOSED."},
    "push": {"chain":{"consume":[{"tag":"EXPOSED","target":"target","bonus":[{"type":"damage","target":"target","amount":2}]}],"apply":[{"tag":"PINNED","target":"target"},{"tag":"MARKED","target":"target"}]},"description":"Push an EXPOSED foe; leave it PINNED and MARKED."},
    "breach": {"chain":{"consume":[{"tag":"INSPIRED","target":"self","bonus":[{"type":"shield","target":"self","amount":1}]}],"apply":[{"tag":"SHIELDED","target":"self"}]},"description":"Spend INSPIRED; gain SHIELDED at the breach."},
    "tremor": {"chain":{"consume":[{"tag":"TAUNTED","target":"area_enemies","bonus":[{"type":"damage","target":"target","amount":3}]}],"apply":[{"tag":"STAGGERED","target":"area_enemies"}]},"description":"Exploit TAUNTED foes; apply STAGGERED across area."},
    "pathfinder": {"chain":{"consume":[{"tag":"READY","target":"self","bonus":[{"type":"shield","target":"self","amount":1}]}],"apply":[{"tag":"INSPIRED","target":"self"}]},"description":"Spend READY; gain INSPIRED for the route."},
    "wildBond": {"chain":{"consume":[{"tag":"ATTUNED","target":"self","bonus":[{"type":"focus","target":"self","amount":1}]}],"apply":[{"tag":"READY","target":"self"},{"tag":"SHIELDED","target":"self"}]},"description":"Spend ATTUNED; gain READY and SHIELDED."}
  }
}
"""
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("JEDI18: " + label)

func _signature(def: Dictionary) -> String:
	var result := {}
	for key in ["effect", "target", "damage", "heal", "shield", "aim", "enemy_aim", "defense", "range", "cooldown", "status", "chance", "shots", "pierce", "pull", "melee", "cover_damage", "next_strike_aim", "distance", "collision_damage"]:
		if def.has(key): result[key] = def[key]
	var riders := []
	for effect in def.get("effects", []):
		var rider := {"type": effect.get("type", ""), "target": effect.get("target", "target")}
		for key in ["amount", "status", "jumps", "range"]:
			if effect.has(key): rider[key] = effect[key]
		riders.append(rider)
	result["effects"] = riders
	return JSON.stringify(result)

func _template(def: Dictionary) -> String:
	var riders := []
	for effect in def.get("effects", []): riders.append(str(effect.get("type", "")) + ":" + str(effect.get("target", "target")))
	return str(def.get("effect", "")) + ":" + str(def.get("target", "")) + "|" + ",".join(riders) + "|" + str([def.get("shots", 1), def.get("pierce", false), def.get("pull", false), def.get("melee", false)])

func run() -> void:
	check(Classes.validate().is_empty(), "all 15 class schemas: " + str(Classes.validate()))
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/jedi18_legacy.json"))
	var overrides: Dictionary = JSON.parse_string(A30_LEGACY_OVERRIDES)
	for class_id in overrides:
		for ability_id in overrides[class_id]:
			var expected: Dictionary = legacy[class_id][ability_id]
			for property in overrides[class_id][ability_id]: expected[property] = overrides[class_id][ability_id][property]
	var all_ids: Dictionary = {}
	var all_signatures: Dictionary = {}
	var all_templates: Dictionary = {}
	var grand_templates: Dictionary = {}
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
					check(bool(def.get("capstone", false)) and bool(def.get("once_per_mission", false)) and int(def.get("cooldown", 0)) >= 1000000000 and "Once per mission" in str(def.name), ability_id + " once-per-mission Grand Master signature")
					var short_name := str(def.name).trim_suffix(" Once per mission")
					var fits := ThemeDB.fallback_font.get_string_size(short_name + " Once", HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x <= 92.0 and ThemeDB.fallback_font.get_string_size("per mission", HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x <= 92.0
					check(fits and short_name != str(def.name), ability_id + " once-per-mission text fits two battle-button lines")
					var template := _template(def)
					check(not grand_templates.has(template), ability_id + " distinct Grand Master effect template")
					grand_templates[template] = ability_id
				for entry in def.chain.get("apply", []):
					check(str(entry.tag) in TAGS, ability_id + " applies shared tag")
					applied[str(entry.tag)] = true
				for entry in def.chain.get("consume", []):
					check(str(entry.tag) in TAGS, ability_id + " consumes shared tag")
					consumed[str(entry.tag)] = true
				var signature := _signature(def)
				check(not all_signatures.has(signature), ability_id + " unique mechanics excluding chain tags and description")
				all_signatures[signature] = ability_id
				var shape := _template(def)
				check(not all_templates.has(shape), ability_id + " distinct effect mix beyond number tuning")
				all_templates[shape] = ability_id
			check(applied.size() >= 3 and consumed.size() >= 3, id + " applies and consumes at least three shared tags")
			check(gm != "" and row.tree.specs.values().all(func(spec): return spec.get("8", []) == [gm]), id + " both branches award one Grand Master signature")
	check(total_new == 98, "seven paths have 13 choices and one Grand Master ability each")
	check(all_signatures.size() == 98 and all_templates.size() == 98 and grand_templates.size() == 7, "98 unique mechanical signatures and effect mixes; seven Grand Master templates")
	var promotion := Promotion.new()
	check(promotion._ability_name("sage_shatterpoint").begins_with("Shatterpoint") and promotion._ability_name("guardian_living_rampart").begins_with("Living Rampart") and not "sage_shatterpoint" in promotion._ability_name("sage_shatterpoint"), "promotion choices show display names instead of raw IDs")
	check(promotion._ability_name("guardian_grand_aegis").begins_with("Aegis") and "Once per mission" in promotion._ability_name("guardian_grand_aegis"), "promotion shows full Grand Master name and once-per-mission label")
	promotion.free()
	check(Classes.power("jedi", 1) < Classes.power("soldier", 1), "Padawan below fresh soldier")
	check(Classes.power("jedi", 5) > Classes.power("soldier", 7) and Classes.power("jedi", 8) == 420, "Master and Grand Master power curve")
	check(Classes.rank_data("jedi", 1).get("starting_kit", []) == ["strike", "guard"], "Padawan starts with two basics")
	var grand = Mission.new(20)
	var leader: Dictionary = grand.living("player")[0]
	var foe: Dictionary = grand.living("enemy")[0]
	Chains.resolve(grand, leader, {}, Vector2i.ZERO, Classes.class_data("guardian").abilities.guardian_grand_aegis)
	check(int(leader.shield) >= 14 and Chains.has_tag(foe, "TAUNTED"), "Aegis shields the squad and taunts enemies")
	Chains.resolve(grand, leader, {}, Vector2i.ZERO, Classes.class_data("knight").abilities.knight_grand_convergence)
	check(int(leader.ap) == 2 and Chains.has_tag(leader, "INSPIRED"), "Convergence grants inspiration with AP capped at 2")
	foe.hp = 20
	Chains.resolve(grand, leader, {}, Vector2i(int(foe.x), int(foe.y)), Classes.class_data("sage").abilities.sage_grand_maelstrom)
	check(int(foe.hp) <= 12 and Chains.has_tag(foe, "LIFTED") and bool(foe.get("rooted", false)), "Maelstrom damages and lifts foes in its area")
	leader.hp = 1
	leader.disarmed = true
	Chains.resolve(grand, leader, {}, Vector2i.ZERO, Classes.class_data("consular").abilities.consular_grand_living_force)
	check(int(leader.hp) > 1 and not bool(leader.get("disarmed", false)) and Chains.has_tag(leader, "INSPIRED"), "Living Force heals, cleanses, and inspires")
	foe.spotted = false
	Chains.resolve(grand, leader, {}, Vector2i.ZERO, Classes.class_data("sentinel").abilities.sentinel_grand_eclipse)
	check(bool(foe.spotted) and Chains.has_tag(foe, "MARKED") and int(leader.buff_aim) >= 15, "Eclipse reveals and marks enemies while raising squad aim")
	foe.hp = 30
	Chains.resolve(grand, leader, {}, Vector2i(int(foe.x), int(foe.y)), Classes.class_data("wayseeker").abilities.wayseeker_grand_living_mountain)
	check(bool(foe.get("rooted", false)) and Chains.has_tag(foe, "PINNED") and int(leader.shield) >= 26, "Living Mountain pins enemies and shelters the squad")
	var chain_mission = Mission.new(22)
	var striker: Dictionary = chain_mission.living("player")[0]
	var victims: Array = chain_mission.living("enemy")
	if victims.size() >= 2:
		var first: Dictionary = victims[0]
		var second: Dictionary = victims[1]
		first.hp = 1
		second.hp = 15
		second.x = int(first.x) + 1
		second.y = int(first.y)
		Chains.resolve(chain_mission, striker, first, Vector2i.ZERO, Classes.class_data("duelist").abilities.duelist_grand_thousand_cuts)
		check(int(first.hp) <= 0 and int(second.hp) < 15, "Thousand Cuts jumps to a nearby enemy after a kill")
	else: check(false, "Grand Master chain has two enemy targets")
	var lock_mission = Mission.new(23)
	var caster: Dictionary = lock_mission.living("player")[0]
	caster.kit.append("guardian_grand_aegis")
	caster.focus = 4
	caster.focus_left = 4
	var first_cast := lock_mission.use_ability(int(caster.id), "guardian_grand_aegis")
	caster.focus_left = 4
	caster.ap = 2
	check(first_cast and lock_mission.ability_reason(int(caster.id), "guardian_grand_aegis").begins_with("Cooldown") and not lock_mission.use_ability(int(caster.id), "guardian_grand_aegis"), "Grand Master signature fires once and stays locked for the mission")
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
