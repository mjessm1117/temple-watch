extends SceneTree
const Paging = preload("res://scripts/storydelivery22_paging.gd")
const Opening = preload("res://scripts/story/opening.gd")
const Comms = preload("res://scripts/story14_comms.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Prompt = preload("res://scripts/storydelivery22_prompt.gd")
const Portraits = preload("res://scripts/story14_portraits.gd")
const Phone = preload("res://scripts/phone_layout.gd")

class FakeMission extends RefCounted:
	var units: Array = [{"id":1,"name":"Kira Venn","side":"player","hp":4,"max_hp":5,"x":0,"y":0,"status":"active","aim":70,"mob":5,"crit":5,"damage":[2,4],"focus":0,"armor":0,"class_name":"guardian"}]
	var ability_uses: Array = []
	var result := ""
	var turn := 2
	var saved_by: Dictionary = {}
	var clues: Array = []
	var spec: Dictionary = {"story_locks":0}
	func living(side: String) -> Array:
		return units.filter(func(u): return u.side == side and int(u.hp) > 0)

class FakeSound extends Node:
	var villain_cues := 0
	func cue(kind: String) -> void:
		if kind == "villain": villain_cues += 1

class FakeGame extends Node3D:
	signal battle_event(kind: String, actor_id: String, target_id: String, context: Dictionary)
	var mission := FakeMission.new()
	var demo_mode := false
	var selected_id := 1
	var camera: Camera3D
	var sound: FakeSound
	var playing_enemy_events := false
	var player_attack_pending := false
	var story_cues := 0
	func cue_story(kind: String, pos: Vector3) -> void:
		if kind == "villain": story_cues += 1
	func _refresh() -> void: pass
	func _ready() -> void:
		camera = Camera3D.new(); add_child(camera)
		sound = FakeSound.new(); add_child(sound)

class InfoStory extends RefCounted:
	func next_squad_beat(_state: Dictionary, _mission_id: String, _turn: int, _names: Array) -> Dictionary:
		return {"kind":"beat","name":"Field Ops","text":"Supply line confirmed.","choices":[]}

var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func run() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/opening.json"))
	check(Portraits.texture("kira") != null and Portraits.texture("Kira Venn") != null,"portrait_key accepts ID and display name")
	var raw: Array = source.pages
	var total := 0
	var max_before := 0
	var max_after := 0
	var max_chars_before := 0
	var max_chars_after := 0
	for row in raw:
		max_before = maxi(max_before,Paging.word_count(str(row.text)))
		max_chars_before = maxi(max_chars_before,str(row.text).length())
		var pages := Paging.pages(str(row.text))
		check(pages.size() >= 2,"opening source splits")
		for page in pages:
			check(Paging.word_count(page) <= 60,"opening page <=60 words")
			max_after = maxi(max_after,Paging.word_count(page))
			max_chars_after = maxi(max_chars_after,page.length())
		total += pages.size()
	check(raw.size() == 8 and total > 8,"opening minimum taps before 8 after %d" % total)
	var count_engine := Story.new()
	var briefing_data: Dictionary = count_engine.start_briefing("relay")
	var debrief_data: Dictionary = count_engine.start_debrief({"mission_id":"relay","won":true})
	var briefing_before := str(briefing_data.text).split("\n",false).size()
	var debrief_before := str(debrief_data.text).split("\n",false).size()
	var briefing_after := 0
	var debrief_after := 0
	for source_line in str(briefing_data.text).split("\n",false): briefing_after += Paging.pages(source_line).size()
	for source_line in str(debrief_data.text).split("\n",false): debrief_after += Paging.pages(source_line).size()
	check(briefing_after >= briefing_before and debrief_after >= debrief_before,"brief and debrief tap counts measured")
	var long_text := "One sentence explains the situation. ".repeat(15)
	var chunks := Paging.pages(long_text)
	var chunks_fit := true
	for passage in chunks: chunks_fit = chunks_fit and Paging.word_count(passage) <= 60
	check(chunks.size() >= 2 and chunks_fit,"story pages <=60 words")
	for size in [Vector2i(844,390),Vector2i(390,844),Vector2i(1366,768)]:
		Phone.test_window_size = size
		DisplayServer.window_set_size(size)
		root.size = size; root.content_scale_size = size
		await process_frame; await process_frame
		var opening = preload("res://scenes/opening.tscn").instantiate()
		root.add_child(opening)
		await process_frame; await process_frame
		if size.x == 390:
			opening.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			opening.size = Vector2(size) / 1.2
			opening._layout()
			await process_frame; await process_frame
		check(opening.pages.size() == total and opening.counter.text.contains(str(total)),"opening page counter %s" % size)
		var logical_width := float(size.x) / 1.2 if size.x == 390 else float(size.x)
		check(opening.counter.get_global_rect().end.x <= logical_width-10,"opening counter clears edge %s" % size)
		check(opening.narrative.get_theme_font_size("normal_font_size") >= 14,"opening Noto 14 px %s" % size)
		check(opening.next_button.get_global_rect().end.x <= logical_width-10,"opening buttons clear edge %s" % size)
		opening._fast_forward()
		check(opening.page_index == 1 and opening.narrative.visible_characters == -1,"opening fast-forward %s" % size)
		opening.queue_free(); await process_frame
		var screen = preload("res://scenes/briefing.tscn").instantiate()
		root.add_child(screen)
		screen.show_scene({"kind":"briefing","title":"Long report","text":long_text,"choices":[]})
		await process_frame; await process_frame
		check(screen.dialogue_lines.size() == chunks.size() and screen.page_counter.text == "PAGE 1 / %d" % chunks.size(),"story page counter %s" % size)
		check(screen.narrative.get_theme_font_size("font_size") >= 14,"story Noto 14 px %s" % size)
		screen._fast_forward(); screen._fast_forward()
		check(screen.dialogue_index == 1 and screen.narrative.visible_characters == -1,"story fast-forward %s" % size)
		screen._skip_dialogue()
		check(screen.dialogue_index == chunks.size()-1 and screen.choices_box.visible,"story skip %s" % size)
		screen.queue_free(); await process_frame
	Phone.test_window_size = Vector2i.ZERO
	var flow = root.get_node("CampaignFlow")
	flow.campaign = Campaign.new("normal")
	flow.story = Story.new(flow.campaign.state)
	flow.active = true
	flow.transitioning = false
	flow.save_path = "user://storydelivery22.json"
	flow.campaign.state.flow_stage = "battle"
	flow.campaign.state.pending_mission = {"mission_id":"relay"}
	var game := FakeGame.new(); root.add_child(game); await process_frame
	var comms := Comms.new(game)
	flow.battle_refresh(game)
	check(game.battle_event.is_connected(flow._battle_event) and comms.event_mode,"battle_event wired, polling fallback off")
	game.battle_event.emit("kill","1","enemy",{"turn":2,"world_pos":Vector3.ZERO})
	check(flow.campaign.state.get("story_transcript",[]).size() == 1,"first actor bark recorded")
	check(comms.text_label.text == "Hold the line.","dormant hero kill bark follows Kira")
	game.battle_event.emit("kill","1","enemy",{"turn":2,"world_pos":Vector3.ZERO})
	check(flow.campaign.state.story_transcript.size() == 1,"one bark per actor per turn")
	flow.last_bark_at = Time.get_ticks_msec()
	game.battle_event.emit("hurt","2","1",{"turn":2})
	check(flow.campaign.state.story_transcript.size() == 1,"four second bark cooldown")
	flow.last_bark_at = -4000
	game.battle_event.emit("flank","2","1",{"turn":2})
	check(flow.campaign.state.story_transcript.size() == 2 and comms.who_label.text == "KIRA VENN","flank bark follows target actor")
	game.battle_event.emit("villain_reveal","boss","",{"name":"Darth Malgus","line":"The gate is mine.","turn":2,"world_pos":Vector3.ONE})
	check(comms.who_label.text == "DARTH MALGUS" and comms.face.texture != null,"villain portrait and name")
	check(game.sound.villain_cues == 1 and game.story_cues == 1,"guarded sound and camera cues")
	check(comms.card.position.y >= 12 and comms.card.custom_minimum_size.x <= 366 and comms.text_label.get_theme_font_size("font_size") >= 14,"radio fits phone")
	await create_timer(3.9).timeout
	check(not comms.card.visible,"radio auto-dismisses in 3.7 seconds")
	for i in 45: flow._record_story("Kira Venn",i,"Narrative line %d" % i)
	check(flow.campaign.state.story_transcript.size() == 40 and int(flow.campaign.state.story_transcript[0].turn) == 5,"transcript capped at 40")
	var reloaded := Campaign.new("normal")
	check(reloaded.load_save(flow.save_path) and reloaded.state.get("story_transcript",[]).size() == 40,"transcript survives campaign save")
	var journal: Dictionary = flow.story.journal(flow.campaign.state)
	check(journal.get("transcript",[]).size() == 40,"journal shows transcript")
	var journal_screen = preload("res://scripts/story/story_screen.gd").new()
	journal_screen.engine = flow.story
	journal_screen.campaign_state = flow.campaign.state
	var journal_list := VBoxContainer.new()
	journal_screen._build_journal(journal_list)
	check(journal_list.get_children().filter(func(node): return node is Label and node.text.begins_with("TURN ")).size() == 40,"journal renders 40 narrative lines")
	journal_list.free(); journal_screen.free()
	var mission_result := {"mission_id":"relay","win":true,"units":[{"id":"u1","status":"active","kills":2,"hurt":true}],"objectives_completed":1}
	var debrief_payload: Dictionary = flow.debrief_input(mission_result,game.mission)
	check(debrief_payload.units.size() == 1 and debrief_payload.units[0].kills == 2 and debrief_payload.mission_result.objectives_completed == 1,"real units and mission result reach debrief")
	var independent := Campaign.new("normal")
	var debrief_scene: Dictionary = Story.new(independent.state).start_debrief(debrief_payload)
	check(str(debrief_scene.get("text","")).contains(str(independent.state.roster[0].n)),"debrief names actual wounded participant")
	game.set_process_unhandled_input(true)
	flow.battle_beat(game)
	check(is_instance_valid(flow.turn_prompt) and flow.screen.get("choices",[]).size() == 2,"turn-two choice becomes compact prompt")
	check(game.is_processing_unhandled_input(),"turn prompt preserves battle input")
	Phone.test_window_size = Vector2i(390,844)
	flow._show_radio("Kira Venn","Kira Venn","Hold this position.",1,2)
	check(not flow.queued_radio.is_empty() and not comms.card.visible,"portrait radio waits until prompt closes")
	var chosen_id := str(flow.screen.choices[0].id)
	flow._choose_battle_beat(chosen_id)
	check(flow.campaign.state.beat_mission == "relay" and not flow.campaign.state.has("battle_choice"),"battle choice applied and recorded")
	check(int(game.mission.units[0].hp) == 5,"turn decision applies the mission heal")
	check(flow.queued_radio.is_empty() and comms.card.visible and comms.text_label.text == "Hold this position.","queued portrait radio resumes after choice")
	Phone.test_window_size = Vector2i.ZERO
	flow.story = InfoStory.new()
	flow.battle_beat(game)
	check(not is_instance_valid(flow.turn_prompt) and comms.text_label.text == "Supply line confirmed." and game.is_processing_unhandled_input(),"information beat uses nonblocking radio")
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT; tap.pressed = true
	comms.card.gui_input.emit(tap)
	check(not comms.card.visible,"tap dismisses radio card")
	var prompt := Prompt.new()
	game.set_process_unhandled_input(true)
	prompt.present(game,{"name":"Kira Venn","text":"Choose a position.","choices":[{"id":"a","label":"Hold the line"},{"id":"b","label":"Press forward"}]},func(_id): pass)
	await process_frame
	check(prompt.get_child(0).get_child_count() == 4 and prompt.get_global_rect().size.x <= 350,"compact two-choice turn prompt")
	check(game.is_processing_unhandled_input(),"prompt leaves battle input enabled")
	prompt.close(); game.queue_free()
	print("StoryDelivery22: %d checks, %d failures; opening taps 8 -> %d; briefing %d -> %d; debrief %d -> %d; max words %d -> %d; max chars %d -> %d" % [checks,failures,total,briefing_before,briefing_after,debrief_before,debrief_after,max_before,max_after,max_chars_before,max_chars_after])
	quit(1 if failures else 0)
