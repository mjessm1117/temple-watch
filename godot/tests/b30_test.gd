extends SceneTree

const Mission = preload("res://scripts/mission.gd")
const Classes = preload("res://scripts/class_registry.gd")
const Chains = preload("res://scripts/ability_chains.gd")
const Ability = preload("res://scripts/abilities_engine.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("B30: " + label)

func fixture() -> RefCounted:
	var m = Mission.new(1)
	m.spec.width = 12; m.spec.height = 12; m.board.clear()
	for row in 12: m.board.append("............")
	m.units.clear(); m.next_id = 0
	m._spawn("soldier", 2, 2, -1); m._spawn("trooper", 4, 2, -1)
	m.units[1].awake = true; m.units[1].spotted = true
	return m

func run() -> void:
	var plan = fixture()
	var officer: Dictionary = plan.units[0]
	var ally: Dictionary = {"id": 99, "side": "player", "status": "ok", "hp": 8, "max_hp": 8, "ap": 0, "x": 3, "y": 2, "name": "Ally"}
	plan.units.append(ally)
	plan.abilities["officer_battle_plan"] = Classes.class_data("officer").abilities.officer_battle_plan.duplicate(true)
	officer.kit.append("officer_battle_plan")
	var start_ap := int(officer.ap)
	check(not Ability.targets(plan, officer, "officer_battle_plan").has(officer), "Battle Plan hides self from valid targets")
	check(not plan.use_ability(int(officer.id), "officer_battle_plan", int(officer.id)) and int(officer.ap) == start_ap, "Battle Plan rejects self without spending AP")
	check(plan.use_ability(int(officer.id), "officer_battle_plan", int(ally.id)), "Battle Plan can target another ally")
	check(int(officer.ap) <= 2 and int(ally.ap) == 1, "Battle Plan grants one ally action within cap")
	check(plan.ability_reason(int(officer.id), "officer_battle_plan") == "Used this turn", "Battle Plan availability reports the turn limit")
	check(not plan.use_ability(int(officer.id), "officer_battle_plan", int(ally.id)) and int(officer.ap) <= 2, "Battle Plan rejects a second use this turn")
	plan.turn += 1
	officer.ap = 2
	check(plan.use_ability(int(officer.id), "officer_battle_plan", int(ally.id)), "Battle Plan use record expires next turn")

	var grants = fixture()
	var actor: Dictionary = grants.units[0]
	actor.ap = 2
	Chains.resolve(grants, actor, {}, Vector2i.ZERO, {"effects":[{"type":"action", "target":"self", "amount":1}]})
	check(int(actor.ap) == 2, "ability chain action grant respects 2 AP cap")
	grants.abilities["b30_end_turn"] = {"name":"End Turn", "effect":"buff", "target":"self", "cost":0, "ends_turn":true, "effects":[{"type":"action", "target":"self", "amount":1}]}
	actor.kit.append("b30_end_turn")
	check(grants.use_ability(int(actor.id), "b30_end_turn") and int(actor.ap) == 0, "ends_turn consumes the chain action grant")

	var miss = fixture()
	var striker: Dictionary = miss.units[0]
	var foe: Dictionary = miss.units[1]
	striker.kit.append("b30_attack")
	miss.abilities["b30_attack"] = {"name":"Miss Probe", "effect":"attack", "target":"enemy", "range":5, "cost":1, "ends_turn":false, "chance":0, "damage":[1,1], "effects":[{"type":"damage", "target":"target", "amount":5}, {"type":"action", "target":"self", "amount":1}]}
	var hp_before := int(foe.hp)
	check(miss.use_ability(int(striker.id), "b30_attack", int(foe.id)), "miss probe executes")
	check(int(foe.hp) == hp_before, "flat damage is skipped when attack misses")
	check(int(striker.ap) == 1, "attack miss does not refund an action")
	miss.abilities["b30_attack"].chance = 100
	check(miss.use_ability(int(striker.id), "b30_attack", int(foe.id)) and int(striker.ap) == 1, "attack hit refunds action after spending it")
	check(int(foe.hp) <= hp_before - 6, "flat damage applies on attack hit")
	print("B30 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
