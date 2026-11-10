extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Bot = preload("res://tests/loop_bot.gd")
var checks := 0
var failures := 0
var flow: Node
var capture := false
var suffix := ""

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int = 4) -> void:
	for i in count: await process_frame

func shot(label: String) -> void:
	if not capture: return
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var path := "res://../docs/godot/shots/wave5-loop-%s%s.png" % [label, suffix]
	check(root.get_texture().get_image().save_png(path) == OK, "capture " + label)
	print("LOOP SCREENSHOT: " + path)

func button_named(node: Node, label: String) -> Button:
	if node is Button and node.text == label: return node
	for child in node.get_children():
		var found := button_named(child, label)
		if found != null: return found
	return null

func choose_first() -> void:
	var scene = current_scene
	if scene.scene_data.get("choices", []).is_empty(): scene.completed.emit()
	else: scene._choose(str(scene.scene_data.choices[0].id))
	await frames()

func reach_temple() -> void:
	await frames()
	for i in 30:
		if is_instance_valid(flow.intelligence):
			check(flow.intelligence.layer.state == flow.campaign.state, "hub intelligence uses live state")
			flow.intelligence.close_requested.emit(); await frames(); continue
		if current_scene.scene_file_path.ends_with("temple.tscn"): return
		check(current_scene.scene_file_path.ends_with("dialogue.tscn"), "hub interrupt is a story scene")
		if not current_scene.scene_file_path.ends_with("dialogue.tscn"): return
		await choose_first()
	check(false, "hub dialogue chain terminates")

func run() -> void:
	capture = "--capture-loop" in OS.get_cmdline_user_args()
	if "--large" in OS.get_cmdline_user_args(): root.size = Vector2i(1920, 1080); suffix = "-1920"
	else: root.size = Vector2i(1366, 768)
	flow = root.get_node("CampaignFlow")
	flow.save_path = "user://loop-test-%d.json" % OS.get_process_id()
	flow.go("menu")
	await frames()
	check(button_named(current_scene, "Continue Campaign").disabled, "Continue disabled without save")
	await shot("menu")
	current_scene._pick("story")
	button_named(current_scene, "New Campaign").pressed.emit()
	await frames()
	check(flow.campaign.state.flow_stage == "opening" and current_scene.scene_file_path.ends_with("opening.tscn"), "new campaign enters opening cinematic")
	current_scene._finish()
	await frames()
	check(flow.campaign.state.flow_stage == "briefing" and current_scene.scene_data.kind == "briefing", "opening leads to first mission briefing")
	await shot("briefing")
	current_scene._choose("brief:1")
	await frames()
	check(int(flow.campaign.state.approach.get("aim", 0)) == 5, "briefing choice persists Dig in")
	check(current_scene.scene_file_path.ends_with("squad.tscn"), "briefing opens squad selection")
	current_scene._toggle("u3"); current_scene._toggle("u6")
	check(current_scene.selected.size() == 5 and current_scene.selected.has("u5"), "Medic selectable among five")
	await shot("squad")
	current_scene._deploy()
	await frames()
	var game = current_scene
	var m = game.mission
	check(m.living("player").size() == 5, "campaign battle uses five roster soldiers")
	var medic: Dictionary = m.living("player").filter(func(u): return u.get("rid") == "u5")[0]
	check(medic.class_name == "Medic" and medic.kit.has("reviveStim"), "campaign Medic brings correct kit")
	var stats: Dictionary = preload("res://scripts/campaign/gear.gd").battle_stats(flow.campaign, "u5")
	check(int(medic.aim) == int(stats.aim) + int(m.difficulty.player_aim) + 5, "rank stats, difficulty and approach reach battle")
	game._select(int(medic.id)); game._refresh()
	check(not game.action_buttons.strike.visible and game.action_buttons.heal.visible, "ability bar hides other classes’ actions")
	check(game.action_buttons.scan.disabled and game.action_buttons.scan.tooltip_text != "", "unusable kit action gives reason")
	await shot("battle")
	# Controlled casualty fixture exercises the real down/revive/result path while the bot plays normally.
	var patient: Dictionary = m.living("player")[1]
	m.apply_damage(patient, 999)
	for i in 60:
		if m.result != "": break
		Bot._bot_turn(m)
	check(m.result != "", "bot finishes campaign battle")
	check(patient.wounded, "downed soldier remains Wounded after revive")
	var before_missions: int = flow.campaign.soldier(str(patient.rid)).missions
	game._refresh()
	await frames()
	check(current_scene.scene_data.kind == "debrief", "battle end opens story debrief")
	check(int(flow.campaign.state.story.done) == 1, "story result recorded exactly once")
	await shot("debrief")
	# Reload at debrief to exercise crash/quit recovery without applying results early.
	flow.continue_campaign()
	await frames()
	check(current_scene.scene_data.kind == "debrief", "Continue resumes pending debrief")
	await choose_first()
	await reach_temple()
	var c = flow.campaign
	check(int(c.soldier(str(patient.rid)).missions) == before_missions + 1, "debrief applies mission result")
	check(c.soldier(str(patient.rid)).status == "active" and int(c.soldier(str(patient.rid)).wound) > 0, "downed = Wounded, never implicit death or capture")
	check(c.state.pending_mission.is_empty() and c.state.flow_stage == "temple", "result clears deployment and returns Temple")
	check(c.state.saga.seen.size() > 0, "due Temple talk chosen and recorded after battle")
	check(not c.state.bonds.is_empty(), "battle updates bonds")
	await shot("temple")
	for station in ["Roster", "Research", "Build", "Arsenal", "Teams", "Legacy", "Command"]:
		current_scene._change_page(station)
		await frames(1)
		if station == "Arsenal":
			check(current_scene.scene_file_path.ends_with("squad.tscn"), "reachable station " + station)
			button_named(current_scene, "DONE").pressed.emit()
			await reach_temple()
		else:
			check(current_scene.page == station, "reachable station " + station)
	flow.open_codex()
	await frames()
	check(current_scene.mode == "codex", "Codex reached from campaign")
	check(button_named(current_scene, "← Return to Temple").get_global_rect().end.y <= current_scene.size.y, "Codex return button fits the viewport")
	await shot("codex")
	button_named(current_scene, "← Return to Temple").pressed.emit()
	await reach_temple()
	current_scene._open_galaxy()
	await frames()
	check(current_scene.scene_file_path.ends_with("galaxy.tscn"), "Temple opens Galaxy")
	await shot("galaxy")
	flow.go("temple")
	await frames()
	var snapshot := JSON.stringify(c.state)
	flow.finish_result()
	check(JSON.stringify(c.state) == snapshot, "duplicate result application is a no-op")
	flow.save()
	var loaded = Campaign.new()
	check(loaded.load_save(flow.save_path), "campaign save/load round trip")
	for key in ["story", "bonds", "roster"]:
		check(JSON.parse_string(JSON.stringify(loaded.state[key])) == JSON.parse_string(JSON.stringify(c.state[key])), key + " survives save/load")
	while int(c.soldier(str(patient.rid)).wound) > 0: current_scene._rest()
	check(int(c.soldier(str(patient.rid)).wound) == 0, "wounded soldier recovers through Temple rest days")
	check(c.default_squad().has(patient.rid), "recovered soldier can deploy again")
	_test_eras()
	_test_loss_and_modifiers()
	flow.save()
	flow.go("menu")
	await frames()
	check(not button_named(current_scene, "Continue Campaign").disabled, "Continue enabled with valid save")
	button_named(current_scene, "Continue Campaign").pressed.emit()
	await reach_temple()
	check(current_scene.scene_file_path.ends_with("temple.tscn"), "Continue reaches Temple")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("LOOP TEST RESULTS: %d checks, %d failures; campaign bot %s" % [checks, failures, m.result])
	quit(1 if failures else 0)

func _test_eras() -> void:
	var c = Campaign.new()
	c.state.step = 4; c.refresh_options()
	check(int(c.state.step) == 5 and not c.state.options.is_empty(), "year transitions cannot strand Galaxy")
	c.state.flags.boss_or_won = true
	check(c.story.advance_era(c.state), "era one result permits era two")
	c._migrate()
	check(c.state.options[0].mission == "r_muster" and c.soldier("e2_0").has("wound"), "era two roster and offers playable")
	c.state.flags.boss_ru_won = true
	check(c.story.advance_era(c.state), "era two result permits era three")
	c._migrate()
	check(c.state.options[0].mission == "h_hetzal", "era three offers available")
	check(Battle.map_path("h_hetzal") == "res://data/maps/h_hetzal.json", "missing mission map resolves to rescue")

func _test_loss_and_modifiers() -> void:
	var c = Campaign.new("normal")
	c.select_mission(0, ["u1", "u2", "u3", "u5"])
	preload("res://scripts/campaign/gear.gd").fit_module(c, "u3", "w", "scope")
	var m = Battle.create(c, 8)
	var actor: Dictionary = m.living("player")[0]
	var foe: Dictionary = m.living("enemy")[0]
	m.apply_damage(foe, 999, actor)
	check(int(actor.kills) == 1, "battle kill credits its roster soldier once")
	m.apply_damage(foe, 999, actor)
	check(int(actor.kills) == 1, "already down enemy cannot grant a duplicate kill")
	var troop: Dictionary = m.living("player")[2]
	check(int(troop.aim) == int(preload("res://scripts/campaign/gear.gd").battle_stats(c, "u3").aim) + int(m.difficulty.get("player_aim", 0)), "purchased arsenal modules reach deployed soldier")
	var before_damage := int(actor.damage[0])
	var before_armor := int(troop.armor)
	Battle.effects(m, c, {"jdmg":1, "tarmor":1, "kit":1, "crit":10, "foeStun":1})
	check(int(actor.damage[0]) == before_damage + 1 and int(troop.armor) == before_armor + 1 and int(troop.medpacs) == 3, "Temple wing buffs reach battle")
	check(m.living("enemy")[0].get("stunned", false), "story stun effect reaches enemy AI")
	for u in m.living("player"): m.apply_damage(u, 999)
	check(m.result == "loss", "full campaign squad down ends battle")
	var result := Battle.result(c, m)
	c.apply_mission_result(result)
	check(c.soldier("u1").kills == 1 and int(c.soldier("u1").xp) > 30, "loss still awards actual kills and survival XP")
	for id in ["u1", "u2", "u3", "u5"]:
		check(c.soldier(id).status == "active" and int(c.soldier(id).wound) > 0, "loss preserves downed soldier as Wounded: " + id)
	for era in [1, 2, 3]:
		c = Campaign.new()
		c.state.era = era
		for step in 14:
			c.state.step = step
			c.refresh_options()
			check(not c.state.options.is_empty(), "era %d step %d has a playable offer" % [era, step])
			for option in c.state.options:
				check(not c.story.mission(str(option.mission)).is_empty(), "offered mission has briefing: " + str(option.mission))
