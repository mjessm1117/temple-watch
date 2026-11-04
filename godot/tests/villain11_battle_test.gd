extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Bridge = preload("res://scripts/campaign_bridge.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Villain = preload("res://scripts/villain11_battle.gd")
const Settings = preload("res://scripts/settings.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func battle(id: String, flagged: bool) -> Dictionary:
	var campaign = Campaign.new("normal")
	campaign.state.options = [{"mission":id,"map_variant":0,"adv":false}]
	campaign.select_mission(0)
	if flagged:
		var story = Story.new(campaign.state)
		var briefing: Dictionary = story.start_briefing(id)
		preload("res://scripts/story/villain11_arc.gd").attach_battle(campaign.state,campaign.state.pending_mission)
		check(briefing.get("villain_present",false), "briefing flags " + id)
	campaign.state.flow_stage = "battle"
	var bridge = Bridge.new()
	bridge.active = true
	bridge.campaign = campaign
	var m: RefCounted = bridge.create_battle(17)
	bridge.free()
	return {"mission":m,"campaign":campaign}

func run() -> void:
	Settings.difficulty = "normal"
	var session := battle("r_caves",true)
	var m: RefCounted = session.mission
	check(m != null, "flagged campaign battle created")
	if m == null: quit(1); return
	var villains: Array = m.units.filter(func(u): return bool(u.get("villain11",false)))
	check(villains.size() == 1, "exactly one story villain spawns")
	if villains.is_empty(): quit(1); return
	var villain: Dictionary = villains[0]
	check(villain.name == session.campaign.state.pending_mission.villain_name and villain.side == "enemy", "villain uses briefing name and enemy side")
	var nearest_squad := 999
	for player in m.living("player"):
		nearest_squad = mini(nearest_squad, abs(int(villain.x)-int(player.x))+abs(int(villain.y)-int(player.y)))
	check(nearest_squad >= 12 and m.passable(Vector2i(int(villain.x),int(villain.y))), "villain starts on a distant open enemy tile")
	check(villain.spotted and villain.awake and m.log_lines.back() == session.campaign.state.pending_mission.villain_start_bark, "visible villain speaks on turn one")
	check(m.turn == 1 and m.objective_state.villain_outcome == "present", "encounter starts on turn one")
	var threshold := floori(float(villain.max_hp) * 0.3)
	m.apply_damage(villain,int(villain.hp)-threshold,m.living("player")[0])
	check(m.objective_state.villain_outcome == "retreated" and not m.units.has(villain), "low health removes villain as retreat")
	check(m.log_lines.has(session.campaign.state.pending_mission.villain_end_bark), "retreat speaks end bark")
	check(Villain.outcome_text(m.objective_state.villain_name,m.objective_state.villain_outcome).contains("retreated"), "outcome yields debrief text")
	var burst: RefCounted = battle("r_caves",true).mission
	var burst_villain: Dictionary = burst.units.filter(func(u): return bool(u.get("villain11",false)))[0]
	burst.apply_damage(burst_villain,99,burst.living("player")[0])
	check(burst.objective_state.villain_outcome == "retreated" and not burst.units.has(burst_villain), "lethal burst cannot bypass retreat")
	var absent: RefCounted = battle("r_caves",false).mission
	check(absent.objective_state.get("villain_outcome", "absent") == "absent" and absent.units.filter(func(u): return bool(u.get("villain11",false))).is_empty(), "unflagged battle has no villain")
	var duel: RefCounted = battle("r_seventh",true).mission
	var duel_villains: Array = duel.units.filter(func(u): return bool(u.get("villain11",false)))
	check(duel_villains.size() == 1 and int(duel_villains[0].id) == int(duel.objective_state.boss_id), "duel names existing boss without a duplicate")
	var boss: Dictionary = duel_villains[0]
	duel.apply_damage(boss,int(boss.hp)-floori(float(boss.max_hp)*0.3),duel.living("player")[0])
	check(duel.objective_state.villain_outcome == "present" and duel.units.has(boss), "duel boss fights below retreat threshold")
	duel.apply_damage(boss,99,duel.living("player")[0])
	check(duel.objective_state.villain_outcome == "defeated" and duel.result == "win", "duel defeat recorded and completes objective")
	check(duel.log_lines.has(duel.objective_state.villain_end_bark), "defeat speaks end bark")
	var extracted := battle("r_bomb",true)
	Villain.finish(extracted.mission)
	check(extracted.mission.objective_state.villain_outcome == "retreated", "living villain withdraws at extraction")
	var history: Array = extracted.campaign.state.get("villain11_encounters", [])
	history.append({"mission_id":"r_bomb","name":extracted.mission.objective_state.villain_name,"outcome":extracted.mission.objective_state.villain_outcome})
	extracted.campaign.state.villain11_encounters = history
	check(Story.new(extracted.campaign.state).journal(extracted.campaign.state).villain.has(Villain.outcome_text(extracted.mission.objective_state.villain_name,"retreated")), "journal records battle outcome")
	if "--capture" in OS.get_cmdline_user_args(): await capture(session)
	print("VILLAIN11 BATTLE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func capture(_session: Dictionary) -> void:
	var session := battle("r_caves",true)
	var m: RefCounted = session.mission
	root.borderless = true
	root.unresizable = true
	root.size = Vector2i(1920,1080)
	root.content_scale_size = Vector2i(1920,1080)
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.demo_mode = true
	game.set_process(false)
	game.mission = m
	for view in game.figures.get_children():
		if view.name != "Prisoner": game.figures.remove_child(view); view.queue_free()
	game.views.clear()
	game.selected_id = int(m.living("player")[0].id)
	game.hud.queue_free(); game.portrait_viewport.queue_free(); game.portrait_kind = ""; game.action_buttons.clear(); game._build_ui()
	game._build_terrain()
	game.terrain_seen_board = m.board.duplicate()
	game.terrain_seen_revision = m.terrain_revision
	var villain: Dictionary = m.units.filter(func(u): return bool(u.get("villain11",false)))[0]
	game.pivot = Vector3(float(villain.x),0,float(villain.y))
	game.zoom = 15.0
	game.pitch = 0.78
	game.yaw = 0.3
	game.action_camera = true
	game._update_camera(); game._refresh(); game.scene_view.arrange_labels()
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://../docs/godot/shots/wave11-villain-battle.png")
	var error := root.get_texture().get_image().save_png(output)
	check(error == OK, "battle screenshot saved")
	game.queue_free()
	await process_frame
