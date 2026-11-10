extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Gear = preload("res://scripts/campaign/gear.gd")
const Modules = preload("res://scripts/campaign/modules.gd")
const Legacy = preload("res://scripts/campaign/legacy.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var game = Campaign.new()
	check(game.state.roster.size() == 6 and game.state.res.credits == 500, "web starting roster and credits")
	game.state.roster[0].kills = 4
	check(game.save("user://campaign-test-save.json"), "save writes")
	var restored = Campaign.new("hard")
	check(restored.load_save("user://campaign-test-save.json"), "save loads")
	check(restored.state.diff == "normal" and restored.state.roster[0].kills == 4, "save round trip retains campaign")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://campaign-test-save.json"))

	game = Campaign.new()
	game.state.wings.archives = 1
	check(game.start_research("ataru"), "research starts with Archives")
	check(game.state.res.credits == 460, "research spends web cost")
	game.advance_days(14)
	check(not game.researched("ataru"), "research still running before day 15")
	game.advance_days(1)
	check(game.researched("ataru"), "research completes on day 15")

	game = Campaign.new()
	check(game.build_wing("training"), "Training Salle build starts")
	check(game.state.res.credits == 350, "wing spends 150 credits")
	game.advance_mission()
	check(game.state.wings.training == 1 and game.state.build == "", "wing completes after a mission")
	check(not game.build_wing("training"), "Training Salle level 2 requires curriculum")

	game = Campaign.new()
	var wounded: Dictionary = game.soldier("u1")
	wounded.wound = 21
	check(game.assign("u1", "rest"), "wounded soldier assigned to Medical Halls")
	game.advance_days(15)
	check(wounded.wound == 0 and wounded.assign == "", "wounded soldier recovers")

	game = Campaign.new()
	var unit: Dictionary = game.soldier("u3")
	var before: Dictionary = Progression.battle_stats(unit)
	unit.xp = 80
	check(Progression.promote(unit), "soldier promotes at 80 XP")
	var after: Dictionary = Progression.battle_stats(unit)
	check(unit.rank == 3 and after.hp == before.hp + 1 and after.aim == before.aim + 5 and after.will == before.will + 3, "RANK_GAIN reaches battle stats")
	check(Progression.choose(unit, str(Progression.tree_options(unit, 1)[0])), "rank 1 tree choice")

	game = Campaign.new()
	check(game.state.options.filter(func(o): return o.get("story",false)).size() == 1 and game.state.options[0].mission == "relay", "opening story mission offered")
	game.state.step = 1; game.refresh_options()
	check(game.state.options.size() >= 3 and game.state.options[0].mission == "rescue" and game.state.options[1].mission == "shrine", "crisis plan offers web missions")
	check(game.select_mission(0).mission_id == "rescue", "mission selection records chosen option")
	check(game.state.res.favor == 42, "ignored escort-less crisis applies web favor penalty")

	game = Campaign.new()
	var result: Dictionary = game.apply_mission_result({"mission_id": "relay", "win": true, "story": true, "units": [
		{"id": "u1", "status": "active", "hp": 2, "max_hp": 8, "downed": true, "kills": 2},
		{"id": "u3", "status": "dead", "kills": 1}]})
	check(game.soldier("u1").kills == 2 and game.soldier("u1").xp > 30, "result awards kills and XP")
	check(game.soldier("u1").wound > 0, "grave wound remains after 15-day advance")
	check(game.soldier("u3").status == "dead" and game.state.legends.size() == 1, "result records casualty")
	check(result.rows.size() == 2, "result debrief has roster rows")

	game = Campaign.new()
	check(Gear.slots(game.soldier("u3"), "w") == 4, "Military blaster has web Mk II slot count")
	check(Gear.fit_module(game, "u3", "w", "scope"), "arsenal installs a weapon module")
	check(game.state.res.credits == 475, "scope costs 25 credits")
	check(game.team_capacity() == 2, "two starting strike teams")
	check(game.field_odds("convoy", ["u1", "u3"]) > 0, "field op odds use roster")
	check(Modules.use(game, "medical"), "medical action available at starting wing")
	check(not Modules.ready(game, "medical"), "wing action starts cooldown")
	check(Legacy.bond_points(game, "u1", "u3", 8) == 1, "bond threshold matches web")
	check(Legacy.set_nickname(game, "u1", "Rook"), "identity nickname saved")
	check(game.soldier("u1").nick == "Rook", "identity nickname stored")
	game.state.step = 1; game.refresh_options()
	check(game.assign_team_to_crisis("shrine", "t2"), "second squad can take another crisis")
	check(game.state.team_assignments.shrine == "t2", "second squad assignment stored")
	var temple_scene: PackedScene = load("res://scenes/temple.tscn")
	var temple: Control = temple_scene.instantiate()
	root.add_child(temple)
	await process_frame
	for station in ["Command", "Roster", "Research", "Build", "Arsenal", "Teams", "Legacy"]:
		temple._change_page(station)
		await process_frame
		check((current_scene != null and current_scene.scene_file_path.ends_with("squad.tscn")) if station == "Arsenal" else temple.page == station, "Temple station %s renders" % station)
	temple.queue_free()
	await process_frame
	var galaxy_scene: PackedScene = load("res://scenes/galaxy.tscn")
	var galaxy: Control = galaxy_scene.instantiate()
	root.add_child(galaxy)
	await process_frame
	galaxy.campaign.state.step = 1
	galaxy.campaign.refresh_options()
	galaxy._show_details()
	check(galaxy.campaign.state.options.size() >= 3, "galaxy crisis briefing renders")
	galaxy.queue_free()
	await process_frame
	print("CAMPAIGN TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
