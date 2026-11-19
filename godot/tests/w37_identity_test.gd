extends SceneTree

const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Mission = preload("res://scripts/mission.gd")
const Frame = preload("res://scripts/w29a_phone_frame.gd")

var checks := 0
var failures := 0
var proof_dir := ""

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--proof="): proof_dir = arg.trim_prefix("--proof=")
	var story := Story.new()
	var briefing: Dictionary = story.start_briefing("rescue")
	var win: Dictionary = Story.new().start_debrief({"mission_id":"rescue","won":true,"units":[]})
	var loss: Dictionary = Story.new().start_debrief({"mission_id":"rescue","won":false,"units":[]})
	check(str(briefing.text).contains("Mira Tal") and str(briefing.goal).contains("Mira Tal"), "Mira Tal in briefing and goal")
	check(story.codex_entries(story.state, "character").any(func(entry): return entry.id == "mira" and entry.name == "Mira Tal"), "Mira Tal named in unlocked codex")
	check(str(win.text).contains("Mira Tal") and str(loss.text).contains("Mira Tal"), "Mira Tal in both debriefs")
	check(not str(briefing).contains("Republic evacuee") and not str(win).contains("Republic evacuee") and not str(loss).contains("Republic evacuee"), "no old captive name in story")
	for path in ["res://data/maps/rescue.json", "res://data/maps/web_detention_level_5.json", "res://data/maps/web_smuggler_grotto.json"]:
		var variant := Mission.new(1, path)
		check(str(variant.prisoner.name) == "Mira Tal" and not str(variant.log_lines).contains("Republic evacuee"), "runtime captive name in " + path.get_file())
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1
	Phone.test_window_size = root.size
	var flow: Node = root.get_node("CampaignFlow")
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	flow.campaign.state.flow_stage = "battle"
	flow.campaign.state.pending_mission = {"mission_id":"rescue","map_variant":0,"squad":flow.campaign.state.roster.slice(0, 5).map(func(member): return member.id),"fewer":0}
	var game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 12: await process_frame
	check(str(game.mission.prisoner.name) == "Mira Tal", "map target is Mira Tal")
	check(str(game.mission.objective_status().label).contains("Mira Tal") and str(game.hud_controls.phone.objective_summary.text).contains("MIRA TAL"), "objective and phone card name Mira Tal")
	var cue: Control = game.overlay.get_node_or_null("ObjectiveCue36")
	check(cue != null and str(cue.get("world_label").text) == "MIRA TAL", "world objective cue names Mira Tal")
	if cue != null:
		cue.set("cue", {"title":"MIRA","point":Vector2(250, 120),"direction":Vector2.UP,"distance":4})
		await process_frame
		check(str(cue.get("cue").title) == "MIRA TAL", "edge arrow names Mira Tal")
	if proof_dir != "":
		for i in 3: await process_frame
		var image: Image = root.get_texture().get_image()
		check(image != null and image.save_png(proof_dir.path_join("after-mira-rescue.png")) == OK, "844x390 after capture")
	var comms = game.get_meta("story_comms")
	check(comms != null, "battle comms attached")
	if comms != null:
		comms.cue_seen.clear(); comms.triggered_named = 0
		for enemy in game.mission.living("enemy"): enemy.awake = false; enemy.spotted = false
		var enemy: Dictionary = game.mission.living("enemy")[0]
		var start: int = Time.get_ticks_msec()
		game.battle_event.emit("reveal", str(enemy.id), "", {"turn":game.mission.turn})
		check(comms.triggered_named == 1 and comms.who_label.text == "ILSA MYR" and comms.text_label.text.split("\n").size() <= 2, "first contact emits one short named line")
		if proof_dir != "":
			for i in 2: await process_frame
			var radio_image: Image = root.get_texture().get_image()
			check(radio_image != null and radio_image.save_png(proof_dir.path_join("after-named-radio.png")) == OK, "844x390 radio capture")
			start = Time.get_ticks_msec()
		game.battle_event.emit("reveal", str(enemy.id), "", {"turn":game.mission.turn})
		check(comms.triggered_named == 1, "repeat contact silent")
		game.mission.prisoner.freed = true
		comms.last_sample = -1000; comms.sample()
		check(comms.triggered_named == 2 and comms.who_label.text == "TOR SAALEN" and comms.text_label.text.contains("Mira Tal"), "freeing Mira emits one named line")
		comms.last_sample = -1000; comms.sample()
		check(comms.triggered_named == 2, "repeat objective silent")
		var ally: Dictionary = game.mission.living("player")[0]
		ally.hp = 0; ally.status = "down"
		game.mission.phase = "enemy"
		game.battle_event.emit("ally_down", str(enemy.id), str(ally.id), {"turn":game.mission.turn})
		check(comms.triggered_named == 3 and comms.who_label.text == "DOC BREN", "first casualty emits one named line")
		game.battle_event.emit("ally_down", str(enemy.id), str(ally.id), {"turn":game.mission.turn})
		check(comms.triggered_named == 3, "repeat casualty silent")
		check(Time.get_ticks_msec() - start < 1000 and not paused and game.mission.phase == "enemy" and comms.card.mouse_filter == Control.MOUSE_FILTER_IGNORE, "radio adds no enemy-turn wait or input block")
	game.queue_free()
	await process_frame
	if DisplayServer.get_name() == "headless":
		print("W37 IDENTITY: %d checks, %d failures" % [checks, failures])
		quit(1 if failures else 0)
		return
	root.size = Vector2i(390, 844)
	root.content_scale_size = root.size
	Phone.test_window_size = root.size
	DisplayServer.window_set_size(root.size)
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	flow.campaign.state.flow_stage = "battle"
	flow.campaign.state.pending_mission = {"mission_id":"rescue","map_variant":0,"squad":flow.campaign.state.roster.slice(0, 5).map(func(member): return member.id),"fewer":0}
	var portrait_game: Node3D = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(portrait_game)
	for i in 12: await process_frame
	var alerts = portrait_game.hud_controls.phone.alerts
	check(alerts != null, "portrait radio layer available")
	if alerts != null:
		alerts.queue.clear(); alerts.remaining = 0.0
		var portrait_comms = portrait_game.get_meta("story_comms")
		portrait_comms.show_radio("Ilsa Myr", "Ilsa Myr", "Contact. I have them.", 2)
		for i in 2: await process_frame
		check(alerts.card.visible and alerts.heading.text == "RADIO · ILSA MYR" and alerts.message.text == "Contact. I have them.", "portrait named radio visible")
		check(alerts.card.mouse_filter == Control.MOUSE_FILTER_IGNORE and not alerts.card.get_global_rect().intersects(Frame.unit_bounds(portrait_game)), "portrait radio does not cover or block acting unit")
		if proof_dir != "":
			var portrait_image: Image = root.get_texture().get_image()
			check(portrait_image != null and portrait_image.save_png(proof_dir.path_join("after-named-radio-portrait.png")) == OK, "390x844 radio capture")
	portrait_game.queue_free()
	await process_frame
	print("W37 IDENTITY: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
