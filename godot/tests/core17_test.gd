extends SceneTree
const Classes = preload("res://scripts/class_registry.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Roster = preload("res://scripts/campaign/strat_roster.gd")
const Mentor = preload("res://scripts/campaign/mentor17.gd")
const Chains = preload("res://scripts/ability_chains.gd")
const Mission = preload("res://scripts/mission.gd")
const Shot = preload("res://scripts/shot.gd")
const Promotion = preload("res://scripts/campaign/promotion_screen.gd")
const BattleBridge = preload("res://scripts/campaign/battle_bridge.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CORE17: " + label)

func run() -> void:
	check(Classes.validate().is_empty(), "15 class schemas: " + str(Classes.validate()))
	check(Classes.classes().size() == 15, "all classes loaded")
	var old_abilities: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/abilities.json"))
	var merged: Dictionary = Classes.ability_catalog()
	for id in old_abilities:
		check(merged.has(id) and merged[id] == old_abilities[id], "legacy ability numbers unchanged: " + str(id))
	var units: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/units.json"))
	for row in Classes.classes().values():
		var kind := str(row.get("unit_kind", ""))
		if kind != "" and units.has(kind) and str(units[kind].get("side", "")) == "player":
			check(row.kit == units[kind].kit, "legacy kit unchanged: " + kind)
	check(Classes.power("jedi", 1) < Classes.power("soldier", 1), "Padawan below fresh soldier")
	check(Classes.power("jedi", 3) < Classes.power("soldier", 1), "under-trained Knight below soldier")
	check(Classes.power("jedi", 5) > Classes.power("soldier", 7), "Master above Commander")
	check(Classes.power("jedi", 8) == 420 and Classes.power("soldier", 7) == 220, "endpoints match design")
	var padawan := {"cls":"Guardian", "rank":1, "classes":["guardian"]}
	check(not Classes.cross_train(padawan, "Scout"), "mixed-side blend rejected")
	check(not Classes.cross_train(padawan, "Consular"), "second path waits for Knight")
	padawan.rank = 3
	check(Classes.cross_train(padawan, "Consular"), "Knight adds second Jedi path")
	check(not Classes.cross_train(padawan, "Scout"), "mixed-side third path rejected")
	padawan.rank = 5
	check(Classes.cross_train(padawan, "Sentinel") and not Classes.cross_train(padawan, "Wayseeker"), "Master caps at three paths")
	var trooper := {"cls":"Soldier", "rank":4, "classes":["trooper"]}
	check(Classes.cross_train(trooper, "Scout") and not Classes.cross_train(trooper, "Guardian"), "Sergeant soldier blends same-side")
	var m = Mission.new(17)
	var actor: Dictionary = m.living("player")[0]
	var enemy: Dictionary = m.living("enemy")[0]
	Chains.apply_tag(enemy, "MARKED", int(actor.id))
	var chain_def := {"chain":{"consume":[{"tag":"MARKED"}], "apply":[{"tag":"EXPOSED"}]}}
	Chains.resolve(m, actor, enemy, Vector2i.ZERO, chain_def)
	check(not Chains.has_tag(enemy, "MARKED") and Chains.has_tag(enemy, "EXPOSED") and m.chain_momentum == 1, "tag consume and apply")
	Chains.resolve(m, actor, enemy, Vector2i.ZERO, {"chain":{"apply":[{"tag":"MARKED"}], "consume":[{"tag":"MARKED"}]}})
	check(Chains.has_tag(enemy, "MARKED") and m.chain_momentum == 1, "same ability cannot consume newly applied tag")
	Chains.apply_tag(enemy, "PINNED"); Chains.consume(m, enemy, "PINNED")
	Chains.apply_tag(enemy, "LIFTED"); Chains.consume(m, enemy, "LIFTED")
	check(m.chain_momentum == 3 and Chains.claim_momentum_strike(m, actor) and m.chain_momentum == 0, "three tags grant free action")
	check(not Chains.claim_momentum_strike(m, actor), "one Momentum strike per turn")
	enemy.combo_tags.erase("MARKED")
	var unmarked := Shot.calculate(m, actor, enemy)
	Chains.apply_tag(enemy, "MARKED")
	var marked := Shot.calculate(m, actor, enemy)
	check(int(marked.crit) == int(unmarked.crit) + 10 and marked.lines.any(func(line): return line[0] == "Marked" and line[1] == 20), "MARKED grants aim and crit")
	Chains.apply_tag(actor, "INSPIRED")
	check(Shot.calculate(m, actor, enemy).lines.any(func(line): return line[0] == "Inspired" and line[1] == 15), "INSPIRED grants aim")
	enemy.droid = true
	Chains.apply_tag(enemy, "IONIZED")
	enemy.shield = 4
	Chains.apply_tag(enemy, "IONIZED")
	check(int(enemy.shield) == 0 and bool(enemy.get("stunned", false)), "IONIZED drops shields and stuns droids")
	Chains.apply_tag(actor, "SHIELDED", -1, 4)
	check(int(actor.shield) == 4, "SHIELDED absorbs four")
	var far_range := preload("res://scripts/abilities_engine.gd").range_of(m.abilities.push, actor)
	Chains.apply_tag(actor, "ATTUNED")
	check(preload("res://scripts/abilities_engine.gd").range_of(m.abilities.push, actor) == far_range + 1.0, "ATTUNED extends Force range")
	Chains.apply_tag(actor, "PINNED")
	check(not m.move(int(actor.id), Vector2i(int(actor.x) + 1, int(actor.y))), "PINNED blocks movement")
	var tagged: Dictionary = enemy.duplicate(true)
	tagged.hp = 20; tagged.max_hp = 20; tagged.shield = 0; tagged.combo_tags = {}
	actor.active_ability = "grenade"
	Chains.apply_tag(tagged, "IONIZED")
	check(m.apply_damage(tagged, 3, actor) == 6, "IONIZED doubles explosive damage")
	actor.erase("active_ability")
	tagged.hp = 20; tagged.combo_tags = {}
	Chains.apply_tag(tagged, "LIFTED")
	check(m.apply_damage(tagged, 4, actor) == 6, "LIFTED increases incoming damage")
	check(Chains.consume(m, tagged, "LIFTED") and tagged.hp == 12, "LIFTED deals fall damage when dropped")
	actor.kit.append("masterAction")
	check(m.use_ability(int(actor.id), "masterAction") and actor.ap == 4 and not m.use_ability(int(actor.id), "masterAction"), "Master third action once per mission")
	var game = Campaign.new()
	game.state.cands = [{"id":"new-jedi","n":"New Padawan","cls":"Guardian","jedi":true}]
	check(Roster.hire(game, "new-jedi"), "barracks hires Jedi")
	var hired: Dictionary = game.state.roster.back()
	check(hired.title == "Padawan" and hired.rank == 1 and hired.classes == ["guardian"], "Jedi joins as Padawan")
	var pending: Dictionary = game.select_mission(0)
	var battle: RefCounted = BattleBridge.create(game, 7) if not pending.is_empty() else null
	var recruit_battle: Dictionary = {}
	if battle != null:
		for member in battle.living("player"):
			if str(member.get("rid", "")) == str(hired.id): recruit_battle = member
	var class_kit: Array = recruit_battle.get("kit", []).filter(func(id): return id not in ["interact", "rewardSafe", "rewardRisky"])
	check(class_kit == ["strike", "guard"] and int(recruit_battle.get("focus", 0)) <= 2, "new Padawan deploys with small starting kit")
	hired.xp = 80
	check(Progression.promote(hired, game.state.roster) and hired.title == "Knight" and hired.rank == 3, "Padawan promotes to Knight")
	check(Classes.cross_train(hired, "Consular"), "promoted Knight cross-trains")
	var path := "user://core17-save.json"
	check(game.save(path), "new save writes")
	var restored = Campaign.new()
	check(restored.load_save(path) and restored.soldier(str(hired.id)).classes == ["guardian", "consular"], "hire and promotion round-trip")
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	old.v = 1
	for unit in old.C.roster:
		for key in ["classes", "cross_picks", "trained_padawans", "legacies", "tier"]: unit.erase(key)
	old.C.erase("mentor_memorials")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(old)); file.close()
	check(restored.load_save(path) and restored.soldier(str(hired.id)).classes == ["guardian"], "old save migrates")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var master: Dictionary = game.soldier("u1")
	master.rank = 5
	var pupil: Dictionary = game.soldier(str(hired.id))
	pupil.rank = 1
	pupil.erase("mentor_id")
	check(Mentor.assign(game, "u1", str(hired.id), "guard"), "Master teaches Padawan")
	check(Mentor.xp_multiplier(game, pupil) == 1.5, "mentored Padawan gains 50 percent XP")
	Mentor.on_death(game, master, "Test mission")
	check(pupil.legacies.size() == 1 and pupil.legacies[0].power == 0.5 and game.state.mentor_memorials.size() == 1, "death leaves reduced legacy and memorial")
	var grand := game.soldier("u1")
	grand.rank = 7; grand.xp = 1000
	check(Progression.promote(grand, game.state.roster) and grand.rank == 8, "Grand Master promotion")
	var rival := game.soldier("u2")
	rival.rank = 7; rival.xp = 1000
	check(not Progression.promote(rival, game.state.roster) and rival.rank == 7, "only one living Grand Master")
	var dark_before := int(game.state.orderDark)
	grand.trained_padawans = []
	Mentor.on_death(game, grand, "Test mission")
	check(int(game.state.orderDark) == dark_before + 2, "unmentored Grand Master death raises Darkness")
	for size in [Vector2i(844, 390), Vector2i(667, 375)]:
		root.size = size
		root.content_scale_size = size
		var screen := Promotion.new()
		root.add_child(screen)
		screen.setup(game, "u1")
		await process_frame
		var buttons: Array[Button] = []
		_find_buttons(screen, buttons)
		check(not buttons.is_empty() and buttons.all(func(b): return b.size.x >= 44 and b.size.y >= 44), "promotion taps at least 44 px at %s" % size)
		var train_button: Button = buttons.filter(func(b): return b.text.begins_with("Train "))[0]
		check(train_button.mouse_filter == Control.MOUSE_FILTER_PASS, "button passes touch drag to scroll at %s" % size)
		var start := train_button.get_global_rect().get_center()
		var press := InputEventScreenTouch.new()
		press.pressed = true; press.position = start
		screen.scroll._gui_input(press)
		var drag := InputEventScreenDrag.new()
		drag.position = start - Vector2(0, 90)
		screen.scroll._gui_input(drag)
		check(screen.scroll.scroll_vertical > 0, "promotion drag scrolls at %s" % size)
		screen.queue_free()
		await process_frame
	print("CORE17: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _find_buttons(node: Node, out: Array[Button]) -> void:
	if node is Button: out.append(node)
	for child in node.get_children(): _find_buttons(child, out)
