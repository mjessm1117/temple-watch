extends Node
## Owns the campaign session and all scene boundaries; battle rules stay in Mission.
const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Battle = preload("res://scripts/campaign/battle_bridge.gd")
const Settings = preload("res://scripts/settings.gd")
var campaign: RefCounted
var story: RefCounted
var active := false
var screen: Dictionary = {}
var screen_return := "temple"
var battle_game: Node
var transitioning := false
var save_path := Campaign.SAVE_PATH

func session() -> RefCounted:
	if campaign == null:
		campaign = Campaign.new()
		campaign.load_save(save_path)
		story = Story.new(campaign.state)
	return campaign

func save() -> bool:
	return campaign.save(save_path)

func new_campaign(difficulty: String) -> void:
	campaign = Campaign.new(difficulty)
	story = Story.new(campaign.state)
	active = true
	campaign.state.flow_stage = "temple"
	save()
	go("temple")

func continue_campaign() -> void:
	campaign = Campaign.new()
	if not campaign.load_save(save_path): return
	story = Story.new(campaign.state)
	active = true
	var stage: String = campaign.state.get("flow_stage", "temple")
	if stage in ["briefing", "debrief"]:
		screen = campaign.state.get("pending", {})
		screen_return = "squad" if stage == "briefing" else "result"
		go("briefing" if stage == "briefing" else "dialogue")
	elif stage in ["squad", "battle"]: go("squad")
	else: go("temple")

func direct_rescue(difficulty: String) -> void:
	active = false
	Settings.difficulty = difficulty
	go("rescue")

func go(scene: String) -> void:
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene)

func prepare_briefing(index: int) -> void:
	var option: Dictionary = campaign.state.options[index]
	campaign.state.launch_index = index
	campaign.state.launch_option = option.duplicate(true)
	campaign.state.flow_stage = "briefing"
	screen = story.start_briefing(str(option.mission))
	# Every offered mission has story data, but old saves can include custom missions.
	if screen.is_empty():
		screen = {"kind":"briefing", "title":str(option.mission).capitalize(), "text":"Deploy to recover the Republic aide and reach evacuation.", "choices":[]}
		campaign.state.pending = screen
	if Battle.map_path(str(option.mission)).ends_with("rescue.json") and str(option.mission) != "rescue":
		screen.goal = "Current deployment: free Aide Mira Tal and escort her to evacuation. This battle resolves the operation above."
	screen_return = "squad"
	save()
	go("briefing")

func open_codex() -> void:
	screen = {}; screen_return = "temple"
	go("codex")

func temple_story() -> void:
	if not active: return
	var s: Dictionary = campaign.state
	screen = s.get("pending", {})
	if screen.get("kind", "") not in ["talk", "event", "vote"]: screen = story.next_story_event(s)
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
		"battle":
			Battle.effects(battle_game.mission, campaign, campaign.state.get("battle_choice", {}))
			campaign.state.erase("battle_choice")
			battle_game.set_process_unhandled_input(true)
			battle_game._refresh()
		_: go("temple")

func launch_squad(ids: Array) -> bool:
	if ids.size() != 4: return false
	var seen := {}
	for id in ids:
		var r: Dictionary = campaign.soldier(str(id))
		if seen.has(id) or r.is_empty() or r.status != "active" or int(r.wound) > 0 or r.assign != "": return false
		seen[id] = true
	if campaign.state.pending_mission.is_empty():
		if campaign.select_mission(int(campaign.state.launch_index), ids).is_empty(): return false
		campaign.state.battle_buffs = preload("res://scripts/campaign/modules.gd").take_next_battle_buffs(campaign)
	else: campaign.state.pending_mission.squad = ids.duplicate()
	campaign.state.flow_stage = "battle"
	save()
	go("rescue")
	return true

func create_battle(seed_value: int) -> RefCounted:
	if not active or campaign == null or campaign.state.get("flow_stage", "") != "battle":
		return preload("res://scripts/mission.gd").new(seed_value)
	return Battle.create(campaign, seed_value)

func battle_refresh(game: Node) -> void:
	if not active or campaign == null or campaign.state.get("flow_stage", "") != "battle" or transitioning: return
	battle_game = game
	for u in game.mission.units:
		if u.side == "enemy" and u.spotted: story.unlock_codex(campaign.state, "enemy", str(u.kind))
	for ability in game.mission.ability_uses: story.unlock_codex(campaign.state, "ability", str(ability))
	if game.mission.result != "" and not game.playing_enemy_events and not game.player_attack_pending:
		transitioning = true
		debrief.call_deferred(game.mission)

func battle_beat(game: Node) -> void:
	if not active or transitioning or game.mission.result != "": return
	battle_game = game
	var names: Array = game.mission.living("player").map(func(u): return u.name)
	screen = story.next_squad_beat(campaign.state, str(campaign.state.pending_mission.mission_id), game.mission.turn, names)
	if screen.is_empty(): return
	screen_return = "battle"
	var panel = load("res://scenes/dialogue.tscn").instantiate()
	panel.set_campaign_state(campaign.state); panel.show_scene(screen)
	panel.completed.connect(func(): panel.queue_free(); story_finished())
	game.hud.add_child(panel)
	game.set_process_unhandled_input(false)
	save()

func debrief(mission: RefCounted) -> void:
	transitioning = false
	if campaign.state.get("flow_stage", "") != "battle": return
	var result: Dictionary = Battle.result(campaign, mission)
	campaign.state.battle_result = result
	screen = story.start_debrief({"mission_id":result.mission_id, "won":result.win,
		"squad":result.units.filter(func(u): return u.status != "dead").map(func(u): return u.id), "saved_by":mission.saved_by, "clues":mission.clues})
	screen.text = str(screen.get("text", "")) + "\n\n" + Battle.casualties(campaign, result)
	campaign.state.pending = screen
	campaign.state.flow_stage = "debrief"
	screen_return = "result"
	save()
	go("dialogue")

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
	if story.advance_era(campaign.state):
		campaign.state.teams = []; campaign.state.staff = {}; campaign.state.team_assignments = {}
		campaign.state.field = {"list":[], "log":[]}
		campaign.state.day = 1; campaign.state.elapsed_days = 0
		campaign._migrate()
		campaign.state.vote_month = 0
		save(); go("temple")
