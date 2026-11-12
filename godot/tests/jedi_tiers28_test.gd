extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Shot = preload("res://scripts/shot.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("JEDI28: " + label)

func deploy(c) -> RefCounted:
	c.state.options = [{"mission":"relay", "map_variant":0, "adv":false}]
	check(not c.select_mission(0).is_empty(), "relay squad selected")
	var battle = Battle.create(c, 28)
	check(battle != null, "live campaign battle created")
	return battle

func unit(m, id: String) -> Dictionary:
	for actor in m.living("player"):
		if str(actor.get("rid", "")) == id: return actor
	return {}

func aura_bonus(m, actor: Dictionary) -> int:
	var foe: Dictionary = m.living("enemy")[0]
	for line in Shot.calculate(m, actor, foe).lines:
		if line[0] == "Master aura": return int(line[1])
	return 0

func nearby_ally(m, source: Dictionary) -> Dictionary:
	for actor in m.living("player"):
		if actor == source: continue
		actor.x = int(source.x) + 1; actor.y = int(source.y)
		return actor
	return {}

func run() -> void:
	var c = Campaign.new("normal")
	var r: Dictionary = c.soldier("u1")
	r.rank = 2
	check(Gear.form_lock_reason(c, r, "makashi") == "Knight rank 3 required", "rank 2 form lock explains Knight requirement")
	check(not Gear.set_form(c, "u1", "makashi") and str(r.gear.form) == "shiiCho", "rank 2 cannot equip advanced form")
	var before = deploy(c)
	var before_u: Dictionary = unit(before, "u1")
	check(not before_u.is_empty() and int(before_u.focus) == 4, "rank 2 live battle has base Focus pool")
	r.xp = 80
	check(Progression.promote(r, c.state.roster, c) and int(r.rank) == 3, "rank 2 promotes to Knight at rank 3")
	check(Gear.set_form(c, "u1", "makashi") and str(r.gear.form) == "makashi", "Knight can equip advanced form")
	c.state.pending_mission = {}
	var after = deploy(c)
	var after_u: Dictionary = unit(after, "u1")
	check(int(after_u.focus) == int(before_u.focus) + 1 and int(after_u.focus_left) == int(after_u.focus), "Knight gains one Focus pip in live battle")
	check(int(after_u.aim) >= int(before_u.aim) + 10, "equipped Makashi changes Knight battle stats")
	var early = Campaign.new("normal")
	var padawan: Dictionary = early.soldier("u2")
	padawan.rank = 1
	check(not Gear.set_form(early, "u2", "soresu"), "rank 1 cannot equip advanced form")
	var basic_stats: Dictionary = Gear.battle_stats(early, "u2")
	padawan.gear.form = "soresu"
	check(Gear.battle_stats(early, "u2") == basic_stats, "old save cannot grant advanced form stats to Padawan")
	padawan.gear.form = "shiiCho"
	var padawan_battle = deploy(early)
	var guarder: Dictionary = unit(padawan_battle, "u2")
	check(guarder.get("kit", []).has("guard") and padawan_battle.use_ability(int(guarder.id), "guard") and bool(guarder.get("guard", false)), "Padawan can activate Guard")
	guarder.guard_deflect = 100
	guarder.hp = 20; guarder.max_hp = 20
	var shooter: Dictionary = padawan_battle.living("enemy")[0]
	shooter.damage = [3, 3]
	padawan_battle._apply_attack(shooter, guarder, {"hit":100, "crit":0}, "shoot")
	check(int(guarder.hp) == 20 and padawan_battle.log_lines.back().contains("deflected"), "Padawan Guard turns a blaster bolt aside")
	var other = Campaign.new("normal")
	other.soldier("u2").cls = "Sentinel"
	other.soldier("u2").classes = ["sentinel"]
	other.soldier("u2").rank = 1
	var other_battle = deploy(other)
	var other_guard: Dictionary = unit(other_battle, "u2")
	check(other_battle.use_ability(int(other_guard.id), "guard"), "Sentinel Padawan activates Guard")
	other_guard.guard_deflect = 100; other_guard.hp = 20; other_guard.max_hp = 20
	var other_shooter: Dictionary = other_battle.living("enemy")[0]
	other_shooter.damage = [3, 3]
	other_battle._apply_attack(other_shooter, other_guard, {"hit":100, "crit":0}, "shoot")
	check(int(other_guard.hp) == 20 and other_battle.log_lines.back().contains("deflected"), "every Jedi Padawan Guard deflects blaster fire")
	var master = Campaign.new("normal")
	var master_r: Dictionary = master.soldier("u1")
	master_r.rank = 4
	var rank4 = deploy(master)
	var rank4_u: Dictionary = unit(rank4, "u1")
	check(aura_bonus(rank4, nearby_ally(rank4, rank4_u)) == 0 and not rank4_u.get("kit", []).has("masterAction"), "rank 4 has no Master effects")
	master_r.xp = 280
	check(Progression.promote(master_r, master.state.roster, master) and int(master_r.rank) == 5, "rank 4 promotes to Master")
	master.state.pending_mission = {}
	var rank5 = deploy(master)
	var rank5_u: Dictionary = unit(rank5, "u1")
	check(aura_bonus(rank5, nearby_ally(rank5, rank5_u)) == 5 and rank5_u.get("kit", []).has("masterAction"), "rank 5 grants ally aura and third action")
	var ap_before := int(rank5_u.ap)
	check(rank5.use_ability(int(rank5_u.id), "masterAction") and int(rank5_u.ap) == ap_before + 1 and not rank5.use_ability(int(rank5_u.id), "masterAction"), "Master third action works once per mission")
	var council = Campaign.new("normal")
	var council_r: Dictionary = council.soldier("u1")
	council_r.rank = 6
	var rank6 = deploy(council)
	var rank6_u: Dictionary = unit(rank6, "u1")
	check(aura_bonus(rank6, nearby_ally(rank6, rank6_u)) == 5, "rank 6 retains Master aura for allies")
	council_r.xp = 700
	check(Progression.promote(council_r, council.state.roster, council) and int(council_r.rank) == 7, "rank 6 promotes to Council Master")
	council.state.pending_mission = {}
	var rank7 = deploy(council)
	var rank7_u: Dictionary = unit(rank7, "u1")
	check(aura_bonus(rank7, nearby_ally(rank7, rank7_u)) == 10, "Council aura doubles for allies in live battle")
	check(unit(rank7, "u1").get("kit", []).has("masterAction"), "Council keeps third action")
	var grand = Campaign.new("normal")
	var first: Dictionary = grand.soldier("u1")
	var second: Dictionary = grand.soldier("u2")
	first.rank = 7; first.xp = 1000
	second.rank = 7; second.xp = 1000
	check(Progression.promote(first, grand.state.roster, grand) and int(first.rank) == 8, "first Grand Master promoted")
	check(not Progression.promote(second, grand.state.roster, grand) and int(second.rank) == 7, "second active Grand Master refused")
	var rank8 = deploy(grand)
	var rank8_u: Dictionary = unit(rank8, "u1")
	check(aura_bonus(rank8, nearby_ally(rank8, rank8_u)) == 10 and rank8_u.get("kit", []).has("masterAction"), "Grand Master retains Council aura and Master action")
	print("JEDI28 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
