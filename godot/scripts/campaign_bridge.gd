extends Node
## Owns the campaign session and all scene boundaries; battle rules stay in Mission.
const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Settings = preload("res://scripts/settings.gd")
const Villain11Battle = preload("res://scripts/villain11_battle.gd")
const SaveSlots = preload("res://scripts/campaign/save_slots.gd")
const Beats22 = preload("res://scripts/story/story14_beats.gd")
var campaign: RefCounted
var story: RefCounted
var active := false
var screen: Dictionary = {}
var screen_return := "temple"
var battle_game: Node
var transitioning := false
var save_path := Campaign.SAVE_PATH
var intelligence: Control
var launch_origin := "galaxy"
var settings_panel: Control
var fade_duration := 0.24
var last_bark_at := -4000
var actor_bark_turn: Dictionary = {}
var turn_prompt: PanelContainer
var queued_radio: Dictionary = {}

func session() -> RefCounted:
	if campaign == null:
		campaign = Campaign.new()
		campaign.load_save(save_path)
		story = Story.new(campaign.state)
	return campaign

func save() -> bool:
	return campaign.save(save_path)

func save_slot(slot: int) -> bool:
	return SaveSlots.write(session(), slot)

func load_slot(slot: int) -> bool:
	var next := Campaign.new()
	if not SaveSlots.read(next, slot): return false
	campaign = next
	story = Story.new(campaign.state)
	active = true
	_resume_loaded()
	return true

func open_settings() -> void:
	var scene := get_tree().current_scene
	if scene == null: return
	if is_instance_valid(settings_panel):
		settings_panel.queue_free()
		settings_panel = null
		return
	var panel := PanelContainer.new()
	panel.name = "SharedSettings"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(280, 160)
	panel.add_theme_stylebox_override("panel", preload("res://scripts/campaign/ui.gd").style())
	var content := VBoxContainer.new()
	panel.add_child(content)
	content.add_child(preload("res://scripts/graphics_options.gd").build_settings_panel())
	content.add_child(preload("res://scripts/campaign/ui.gd").button("BACK", open_settings))
	scene.add_child(panel)
	settings_panel = panel

func open_saves(origin: String = "menu") -> void:
	launch_origin = origin
	go("save_load")

func new_campaign(difficulty: String) -> void:
	campaign = Campaign.new(difficulty)
	story = Story.new(campaign.state)
	active = true
	campaign.state.flow_stage = "opening"
	save()
	go("opening")

func opening_finished() -> void:
	if not active or campaign == null or campaign.state.get("flow_stage", "") != "opening": return
	for i in campaign.state.options.size():
		if campaign.state.options[i].get("story", false) and str(campaign.state.options[i].get("mission", "")) == "relay":
			prepare_briefing(i)
			return

func continue_campaign() -> void:
	campaign = Campaign.new()
	if not campaign.load_save(save_path): return
	story = Story.new(campaign.state)
	active = true
	_resume_loaded()

func _resume_loaded() -> void:
	var stage: String = campaign.state.get("flow_stage", "temple")
	if stage == "opening": go("opening")
	elif stage in ["briefing", "debrief", "interlude", "arc_transition"]:
		screen = campaign.state.get("pending", {})
		screen_return = "squad" if stage == "briefing" else "result" if stage == "debrief" else "era_transition" if stage == "arc_transition" else "temple"
		go("briefing" if stage == "briefing" else "dialogue")
	elif stage in ["squad", "battle"]: go("squad")
	else: go("temple")

func direct_rescue(difficulty: String) -> void:
	active = false
	Settings.difficulty = difficulty
	go("rescue")

func go(scene: String) -> void:
	var tree := get_tree()
	var layer := CanvasLayer.new()
	layer.name = "CampaignFadeLayer"
	layer.layer = 100
	tree.root.add_child(layer)
	var veil := ColorRect.new()
	veil.name = "CampaignFade"
	veil.color = Color.BLACK
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.modulate.a = 1.0
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(veil)
	tree.change_scene_to_file("res://scenes/%s.tscn" % scene)
	var back := tree.create_tween()
	back.tween_property(veil, "modulate:a", 0.0, fade_duration)
	await back.finished
	layer.queue_free()

func prepare_briefing(index: int) -> void:
	launch_origin = get_tree().current_scene.name.to_snake_case() if get_tree().current_scene != null else "galaxy"
	if launch_origin not in ["galaxy", "temple"]: launch_origin = "galaxy"
	var option: Dictionary = campaign.state.options[index]
	campaign.state.launch_index = index
	campaign.state.launch_option = option.duplicate(true)
	campaign.state.flow_stage = "briefing"
	screen = story.start_briefing(str(option.mission))
	# Every offered mission has story data, but old saves can include custom missions.
	if screen.is_empty():
		screen = {"kind":"briefing", "title":str(option.mission).capitalize(), "text":"Complete the operation and reach evacuation.", "choices":[]}
		campaign.state.pending = screen
	if not campaign.state.launch_option.has("n"): campaign.state.launch_option.n = str(screen.get("title", option.mission))
	var maps = preload("res://scripts/map_catalog.gd")
	var map := maps.load_map(maps.select_layout(preload("res://scripts/campaign/battle_sith.gd").map_id(option),7,int(option.get("map_variant",0 if option.has("sith_offer_id") else -1))))
	var mission_goal := str(story.mission(str(option.mission)).get("goal", ""))
	screen.goal = mission_goal if option.get("story", false) and not mission_goal.is_empty() else "%s · %s. Complete the objective, then reach evacuation." % [map.get("name",option.mission),str(map.get("family","rescue")).replace("_"," ")]
	if option.has("sith_offer_id"): screen.goal = str(option.n) + " · " + str(option.get("risk",screen.goal))
	screen_return = "squad"
	save()
	go("briefing")

func back_from_briefing() -> void:
	campaign.state.flow_stage = "temple"
	campaign.state.erase("pending")
	screen = {}
	save()
	go(launch_origin)

func back_from_squad() -> void:
	campaign.state.flow_stage = "briefing"
	save()
	go("briefing")

func open_codex() -> void:
	screen = {}; screen_return = "temple"
	go("codex")

func temple_story() -> void:
	if not active: return
	var s: Dictionary = campaign.state
	screen = s.get("pending", {})
	if screen.get("kind", "") not in ["talk", "event", "vote", "villain11", "scene11", "grief"]: screen = preload("res://scripts/story/rank19_beats.gd").next(s)
	if screen.is_empty(): screen = story.next_villain_beat(s)
	if screen.is_empty() and show_sith_events(): return
	if screen.is_empty(): screen = story.next_story_event(s)
	if screen.is_empty() and int(s.get("vote_month", 0)) < int(s.month):
		screen = story.next_council_vote(s)
		if not screen.is_empty(): s.vote_month = int(s.month)
	if screen.is_empty(): screen = story.next_temple_talk(s)
	if screen.is_empty(): return
	screen_return = "temple"
	save()
	go("dialogue")

func story_finished() -> void:
	campaign._migrate()
	save()
	match screen_return:
		"squad":
			campaign.state.flow_stage = "squad"; save(); go("squad")
		"result": finish_result()
		"era_transition": advance_era()
		"battle":
			Battle.effects(battle_game.mission, campaign, campaign.state.get("battle_choice", {}))
			campaign.state.erase("battle_choice")
			battle_game.set_process_unhandled_input(true)
			battle_game._refresh()
		_:
			campaign.state.flow_stage = "temple"
			campaign.state.erase("pending")
			save(); go("temple")

func launch_squad(ids: Array) -> bool:
	if campaign.sith.project_status().defeated: return false
	var option: Dictionary = campaign.state.pending_mission
	if option.is_empty(): option = campaign.state.options[int(campaign.state.launch_index)]
	if not preload("res://scripts/campaign/strat_deployment.gd").validate(campaign, ids, option): return false
	if campaign.state.pending_mission.is_empty():
		if campaign.select_mission(int(campaign.state.launch_index), ids).is_empty(): return false
		campaign.state.battle_buffs = preload("res://scripts/campaign/modules.gd").take_next_battle_buffs(campaign)
	else: campaign.state.pending_mission.squad = ids.duplicate()
	preload("res://scripts/story/villain11_arc.gd").attach_battle(campaign.state,campaign.state.pending_mission)
	campaign.state.flow_stage = "battle"
	save()
	go("rescue")
	return true

func create_battle(seed_value: int) -> RefCounted:
	if not active or campaign == null or campaign.state.get("flow_stage", "") != "battle":
		return preload("res://scripts/mission.gd").new(seed_value)
	var battle: RefCounted = Battle.create(campaign, seed_value)
	if battle != null: Villain11Battle.setup(battle, campaign.state.pending_mission)
	return battle

func battle_refresh(game: Node) -> void:
	if not active or campaign == null or campaign.state.get("flow_stage", "") != "battle" or transitioning: return
	if battle_game != game:
		actor_bark_turn.clear()
		last_bark_at = -4000
		queued_radio.clear()
	battle_game = game
	if game.has_signal("battle_event") and not game.battle_event.is_connected(_battle_event):
		game.battle_event.connect(_battle_event)
		if game.has_meta("story_comms"):
			var comms = game.get_meta("story_comms")
			if comms != null: comms.event_mode = true
	for u in game.mission.units:
		if u.side == "enemy" and u.spotted: story.unlock_codex(campaign.state, "enemy", str(u.kind))
	for ability in game.mission.ability_uses: story.unlock_codex(campaign.state, "ability", str(ability))
	if game.mission.result != "" and not game.playing_enemy_events and not game.player_attack_pending:
		transitioning = true
		debrief.call_deferred(game.mission)

func battle_beat(game: Node) -> void:
	if not active or transitioning or game.mission.result != "": return
	if is_instance_valid(turn_prompt): return
	battle_game = game
	var names: Array = game.mission.living("player").map(func(u): return u.name)
	screen = story.next_squad_beat(campaign.state, str(campaign.state.pending_mission.mission_id), game.mission.turn, names)
	if screen.is_empty(): return
	var speaker := str(screen.get("name", "Field Comms"))
	var genuine_choice := false
	for choice in screen.get("choices", []):
		if not choice.get("battle", {}).is_empty(): genuine_choice = true
	if not genuine_choice:
		_show_radio(speaker,speaker,str(screen.get("text","")),1,game.mission.turn)
		campaign.state.beat_mission = str(campaign.state.pending_mission.mission_id)
		campaign.state.erase("pending")
		save()
		return
	if is_instance_valid(turn_prompt): turn_prompt.queue_free()
	turn_prompt = preload("res://scripts/storydelivery22_prompt.gd").new()
	turn_prompt.present(game,screen,_choose_battle_beat)
	_record_story(speaker,game.mission.turn,str(screen.get("text","")))
	save()

func _choose_battle_beat(id: String) -> void:
	var choice: Dictionary = story.apply_choice(campaign.state,id)
	if not choice.get("ok",false): return
	Battle.effects(battle_game.mission,campaign,campaign.state.get("battle_choice",{}))
	campaign.state.erase("battle_choice")
	if is_instance_valid(turn_prompt): turn_prompt.close()
	turn_prompt = null
	if not queued_radio.is_empty() and battle_game.has_meta("story_comms"):
		var comms = battle_game.get_meta("story_comms")
		if comms != null and comms.has_method("show_radio"):
			comms.show_radio(str(queued_radio.speaker),str(queued_radio.portrait_key),str(queued_radio.text),int(queued_radio.priority))
	queued_radio.clear()
	battle_game._refresh()
	save()

func _battle_event(kind: String, actor_id: String, target_id: String, context: Dictionary) -> void:
	if battle_game == null or campaign == null or transitioning: return
	var turn := int(context.get("turn",battle_game.mission.turn))
	var comms = battle_game.get_meta("story_comms") if battle_game.has_meta("story_comms") else null
	if kind == "villain_reveal":
		var name := str(context.get("name", ""))
		for unit in battle_game.mission.units:
			if str(unit.get("id","")) == actor_id or str(unit.get("rid","")) == actor_id: name = str(unit.get("name",name)); break
		if name.is_empty(): name = "Unknown Sith"
		_show_radio(name,name,str(context.get("line","The Sith steps into view.")),3,turn)
		if battle_game.get("sound") != null and battle_game.sound.has_method("cue"): battle_game.sound.cue("villain")
		if battle_game.has_method("cue_story"): battle_game.cue_story("villain",context.get("world_pos",Vector3.ZERO))
		return
	var now := Time.get_ticks_msec()
	if now - last_bark_at < 4000 or actor_bark_turn.get(actor_id,-1) == turn: return
	var bark: Dictionary = {}
	var beats = Beats22.new()
	if beats.has_method("pick_bark"): bark = beats.call("pick_bark",kind,actor_id,target_id,context)
	if bark.is_empty() and comms != null: bark = comms.fallback(kind,actor_id,target_id)
	if bark.is_empty(): return
	_show_radio(str(bark.get("speaker","Field Comms")),str(bark.get("portrait_key",bark.get("speaker",""))),str(bark.get("text","")),int(bark.get("priority",1)),turn)
	last_bark_at = now
	actor_bark_turn[actor_id] = turn
	if comms != null: comms.bark_number += 1

func _show_radio(speaker: String, portrait_key: String, line: String, priority: int, turn: int) -> void:
	if battle_game == null or not battle_game.has_meta("story_comms"): return
	var comms = battle_game.get_meta("story_comms")
	if comms == null or not comms.has_method("show_radio"): return
	if is_instance_valid(turn_prompt) and preload("res://scripts/phone_layout.gd").window_size().x < 700:
		queued_radio = {"speaker":speaker,"portrait_key":portrait_key,"text":line,"priority":priority}
		_record_story(speaker,turn,line)
		return
	comms.show_radio(speaker,portrait_key,line,priority)
	_record_story(speaker,turn,line)

func _record_story(speaker: String, turn: int, line: String) -> void:
	if campaign == null or line.strip_edges().is_empty(): return
	var transcript: Array = campaign.state.get("story_transcript",[])
	transcript.append({"speaker":speaker,"turn":turn,"text":line.strip_edges()})
	while transcript.size() > 40: transcript.pop_front()
	campaign.state.story_transcript = transcript
	save()

func debrief(mission: RefCounted) -> void:
	transitioning = false
	if campaign.state.get("flow_stage", "") != "battle": return
	Villain11Battle.finish(mission)
	var result: Dictionary = Battle.result(campaign, mission)
	result.villain_outcome = mission.objective_state.get("villain_outcome", "absent")
	campaign.state.battle_result = result
	if is_instance_valid(battle_game) and battle_game.get("sound") != null and battle_game.sound.has_method("cue"):
		battle_game.sound.cue("victory" if bool(result.win) else "defeat")
	screen = story.start_debrief(debrief_input(result,mission))
	if campaign.state.pending_mission.get("villain_present",false):
		screen.text += "\n\n" + Villain11Battle.outcome_text(str(mission.objective_state.villain_name), str(mission.objective_state.villain_outcome))
		var encounters: Array = campaign.state.get("villain11_encounters", [])
		encounters.append({"mission_id":result.mission_id, "name":mission.objective_state.villain_name, "outcome":mission.objective_state.villain_outcome})
		campaign.state.villain11_encounters = encounters
	screen.text = str(screen.get("text", "")) + "\n\n" + Battle.casualties(campaign, result)
	var front := str(campaign.state.get("twin",{}).get("stage",""))
	if front == "a": screen.text += "\n\nFRONT B awaits: a fresh squad of two to four, at most two Jedi. The date stays fixed until both fronts are settled."
	elif front == "b2": screen.text += "\n\nFRONT B complete. Both fronts now settle together."
	campaign.state.pending = screen
	campaign.state.flow_stage = "debrief"
	screen_return = "result"
	save()
	go("dialogue")

static func debrief_input(result: Dictionary, mission: RefCounted) -> Dictionary:
	return {"mission_id":result.mission_id,"won":result.win,"units":result.units,"mission_result":result,
		"squad":result.units.filter(func(u): return u.status != "dead").map(func(u): return u.id),
		"saved_by":mission.saved_by,"clues":mission.clues}

func finish_result() -> void:
	if campaign.state.get("flow_stage", "") != "debrief": return
	var result: Dictionary = campaign.state.battle_result
	campaign.state.last_debrief = campaign.apply_mission_result(result)
	campaign.state.erase("battle_result")
	campaign.state.erase("pending")
	campaign.state.flow_stage = "temple"
	save()
	go("temple")

func advance_era() -> void:
	var prior_era := int(campaign.state.era)
	if prior_era == 1 and (campaign.state.flags.get("boss_or_won", false) or campaign.state.flags.get("temple_scarred", false)):
		screen = story.next_era_resolution(campaign.state)
		if not screen.is_empty():
			screen_return = "era_transition"
			campaign.state.flow_stage = "arc_transition"
			save(); go("dialogue")
			return
	if story.advance_era(campaign.state):
		campaign.state.teams = []; campaign.state.staff = {}; campaign.state.team_assignments = {}
		campaign.state.field = {"list":[], "log":[]}
		campaign.state.day = 1; campaign.state.elapsed_days = 0
		campaign.state.erase("sith") # Each era starts a new, date-aligned strategic campaign.
		campaign._migrate()
		campaign.state.vote_month = 0
		screen = story.era_interlude(campaign.state,prior_era)
		screen_return = "temple"
		campaign.state.flow_stage = "interlude"
		save(); go("dialogue")

func open_intelligence(page: String = "operations") -> void:
	if int(campaign.state.era) == 1 and int(campaign.state.story.get("done", 0)) == 0: return
	if is_instance_valid(intelligence): intelligence.queue_free()
	intelligence = load("res://scenes/sith_report.tscn").instantiate()
	intelligence.bind_state(campaign.state)
	intelligence.page = page
	intelligence.state_changed.connect(func(): campaign.refresh_options(); save())
	intelligence.close_requested.connect(func():
		intelligence.queue_free(); campaign.refresh_options(); save()
		if campaign.sith.project_status().defeated: active = false; go("menu")
		else: go("galaxy" if get_tree().current_scene.scene_file_path.ends_with("galaxy.tscn") else "temple"))
	intelligence.mission_requested.connect(func(offer: Dictionary):
		campaign.refresh_options()
		for i in campaign.state.options.size():
			if campaign.state.options[i].get("sith_offer_id", "") == offer.id:
				intelligence.queue_free(); prepare_briefing(i); return)
	get_tree().current_scene.add_child(intelligence)

func show_sith_events() -> bool:
	if get_tree().current_scene == null: return false
	if int(campaign.state.era) == 1 and int(campaign.state.story.get("done", 0)) == 0: return false
	var events: Array = campaign.sith.pending_events()
	var report := events.any(func(event): return event.kind == "council_report")
	if events.is_empty() and not campaign.sith.project_status().defeated: return false
	open_intelligence("report" if report or campaign.sith.project_status().defeated else "operations")
	var notices := PackedStringArray()
	for event in events:
		var text := str(event.get("n",event.kind))
		campaign.state.news.append(text); notices.append(text)
		campaign.sith.acknowledge(str(event.id))
	intelligence.status_line.text = " · ".join(notices)
	save()
	return true
