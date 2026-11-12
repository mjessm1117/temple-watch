extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Classes = preload("res://scripts/class_registry.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Bridge = preload("res://scripts/campaign/battle_bridge.gd")
const SkillTree = preload("res://scripts/campaign/loadout_skill_tree.gd")
const OUT = "/home/jess/projects/tw-logs/w20/loadout/"
var checks := 0
var failures := 0
var capture := false

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	run.call_deferred()

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("LOADOUT20: " + reason)

func resize_to(value: Vector2i) -> void:
	DisplayServer.window_set_size(value)
	root.size = value
	root.content_scale_size = value
	for i in 3: await process_frame

func shot(label: String) -> void:
	if not capture: return
	for i in 6: await process_frame
	await create_timer(0.4).timeout
	check(root.get_texture().get_image().save_png(OUT + label + ".png") == OK, "capture " + label)

func pair_type(ability: Dictionary) -> String:
	var effect := str(ability.get("effect", ""))
	if effect == "attack" and int(ability.get("shots", 1)) > 1: return "burst attack"
	if effect == "attack" and bool(ability.get("ignore_cover", false)): return "cover-piercing attack"
	return effect

func main_number(ability: Dictionary) -> float:
	if ability.get("damage", null) is Array:
		return (float(ability.damage[0]) + float(ability.damage[1])) * 0.5
	for key in ["heal", "defense", "shots", "damage_mod", "aim", "chance", "distance", "amount", "range"]:
		if ability.has(key) and (ability[key] is int or ability[key] is float): return float(ability[key])
	return 1.0

func inspect_tree(screen: Control, value: Vector2i) -> void:
	await resize_to(value)
	screen.inspect(0)
	screen._tab_armory_skills()
	for i in 3: await process_frame
	var tree: Control = screen.arsenal.picker.get_node_or_null("SkillTree")
	check(tree != null, "%s skill tree exists" % value)
	if value.x == 1366: check(screen.header.visible, "desktop header remains visible")
	if tree == null: return
	check(screen.deploy.visible and screen.deploy.get_global_rect().end.x <= value.x and screen.deploy.get_global_rect().end.y <= value.y, "%s DEPLOY visible inside screen" % value)
	check(screen.stage.actors[0].visible and screen.stage_container.get_global_rect().end.x <= screen.drawer.get_global_rect().position.x, "%s Kira visible beside inspector" % value)
	var scroll: ScrollContainer = screen.arsenal.get_parent()
	if value.x == 956:
		for rank in range(1, 4):
			for key in Progression.tree_options(screen.flow.session().soldier("u1"), rank):
				var card: Control = tree.cards[str(key)]
				check(card.custom_minimum_size.x >= 44 and card.custom_minimum_size.y >= 44, "956 R%d %s touch target" % [rank, key])
				check(card.find_child("Chain", true, false) != null, "956 R%d %s chain shown" % [rank, key])
	for card in tree.cards.values():
		check(card.custom_minimum_size.x >= 44 and card.custom_minimum_size.y >= 44, "%s tree touch target" % value)
	if value.x in [844, 1366]: await shot("layout-%d" % value.x)

func run() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://loadout20-test.json"
	flow.campaign = Campaign.new("normal"); flow.story = flow.campaign.story; flow.active = true
	var c = flow.campaign
	check(c.state.roster.size() >= 6, "fresh campaign has full roster")
	for r in c.state.roster:
		check(Progression.skill_rank(r) >= 3 and Progression.pending_rank(r) in [1, 3], "%s may choose ranks 1-3 before first mission" % r.n)
	var catalog: Dictionary = Classes.ability_catalog()
	for cls in Classes.classes().values():
		var fixture := {"cls":cls.name, "rank":3, "picks":[], "spec":""}
		for rank in range(1, 4):
			var options: Array = Progression.tree_options(fixture, rank)
			check(options.size() == 2, "%s R%d has two choices" % [cls.name, rank])
			if options.size() != 2: continue
			var first: Dictionary = catalog.get(str(options[0]), {})
			var second: Dictionary = catalog.get(str(options[1]), {})
			var a := main_number(first); var b := main_number(second)
			var apart := absf(a - b) / maxf(0.001, maxf(absf(a), absf(b)))
			check(pair_type(first) != pair_type(second) or apart >= 0.2, "%s R%d distinct pair: %s vs %s" % [cls.name, rank, options[0], options[1]])
			for ability in [first, second]:
				var icon_id := SkillTree._icon(ability)
				check(ResourceLoader.exists("res://assets/loadout/icons/%s.svg" % icon_id), "real skill icon %s" % icon_id)
	var ids := ["u1", "u2", "u3", "u4", "u5"]
	await resize_to(Vector2i(956, 440))
	var screen = load("res://scenes/squad.tscn").instantiate(); root.add_child(screen)
	for i in 3: await process_frame
	await shot("01-lineup")
	screen.inspect(0)
	for i in 3: await process_frame
	var weapon: Button = screen.arsenal.slot_row.get_node("Slot_weapon")
	check(not str(weapon.get_node("ItemName").text).to_lower().contains("blaster"), "Jedi weapon card says saber")
	check(weapon.get_node("GearArt").texture != null, "Jedi weapon has item art")
	for key in ["form", "evolution"]:
		check(screen.arsenal.slot_row.get_node("Slot_" + key).get_node("GearArt").texture != null, "%s has real icon" % key)
	await shot("02-gear")
	await inspect_tree(screen, Vector2i(956, 440))
	await inspect_tree(screen, Vector2i(844, 390))
	await inspect_tree(screen, Vector2i(1366, 768))
	await inspect_tree(screen, Vector2i(956, 440))
	var tree: Control = screen.arsenal.picker.get_node("SkillTree")
	tree._preview(1, "guardian_deflect")
	await shot("03-tree-selection")
	tree._confirm()
	for r in c.state.roster:
		for rank in range(1, 4):
			var options: Array = Progression.tree_options(r, rank)
			check(Progression.set_choice(r, rank, str(options[0]), true), "%s chooses R%d" % [r.n, rank])
		check(r.picks.size() == 3 and Progression.pending_rank(r) == 0, "%s has three battle skills" % r.n)
	screen._refresh(); screen._tab_armory_skills()
	tree = screen.arsenal.picker.get_node("SkillTree")
	tree._preview(3, str(Progression.tree_options(c.soldier("u1"), 3)[1]))
	await shot("04-comparison")
	check(not c.select_mission(0, ids).is_empty(), "first mission accepts selected squad")
	var before := Gear.battle_stats(c, "u1")
	var battle_before = Bridge.create(c, 8)
	var old_hp := 0
	if battle_before != null: old_hp = int(battle_before.living("player").filter(func(u): return u.rid == "u1")[0].max_hp)
	check(Gear.buy_armor(c, "u1", "none"), "Jedi can swap armor")
	var after := Gear.battle_stats(c, "u1")
	check(int(after.hp) < int(before.hp), "gear swap changes HP stat")
	var battle = Bridge.create(c, 8)
	check(battle != null, "battle bridge creates mission")
	if battle != null:
		for unit in battle.living("player"):
			var r: Dictionary = c.soldier(str(unit.rid))
			check(unit.selected_skills == r.picks, "%s picks reach battle state" % r.n)
			for pick in r.picks:
				check(pick in unit.kit, "%s skill %s reaches tactical kit" % [r.n, pick])
		var kira: Dictionary = battle.living("player").filter(func(u): return u.rid == "u1")[0]
		check(int(kira.max_hp) == old_hp + int(after.hp) - int(before.hp), "armor HP reaches battle bridge")
	check(bool(c.state.skill_picks_locked), "skill picks lock at first battle")
	check(not Progression.set_choice(c.soldier("u1"), 1, "saberThrow", true), "locked pick cannot change")
	screen.queue_free(); await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("LOADOUT20 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
