extends SceneTree
const Story = preload("res://scripts/story/story_engine.gd")
var checks := 0
var failures := 0
var completions := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.active = false
	for name in ["menu","briefing","dialogue","codex"]:
		var screen = load("res://scenes/%s.tscn" % name).instantiate()
		root.add_child(screen)
		await process_frame
		await process_frame
		check(screen.get_child_count() > 0,"builds " + name)
		if name == "menu":
			for id in ["story","normal","hard","legend"]:
				screen._pick(id)
				check(screen.picked == id and screen.buttons[id].button_pressed,"difficulty " + id)
		if name == "briefing":
			check(screen.portrait_count == 1,"briefing has unit portrait")
			check(screen.narrative.visible_characters >= 0,"transmission types in")
			screen._reveal()
			check(screen.narrative.visible_characters == -1,"transmission can be revealed")
		if name == "dialogue":
			check(screen.portrait_count == 2,"talk has facing portraits")
			check(screen.bond_meter != null,"talk has bond meter")
			screen.completed.connect(func(): completions += 1)
			screen.choice_buttons[0].pressed.emit()
			check(completions == 0,"talk waits for bond animation")
			await create_timer(0.6).timeout
			check(is_equal_approx(screen.bond_meter.value,1.0),"bond meter settles at changed trust")
			check(screen.campaign_state.flags.get("kira_told",false),"talk choice applies flag")
			check(screen.campaign_state.saga.t.kira == 1,"talk choice changes trust")
			check(completions == 1,"talk completes once")
			screen._choose("talk:0")
			check(completions == 1 and screen.campaign_state.saga.t.kira == 1,"double activation cannot apply twice")
		if name == "codex":
			for item in screen.engine.table("KINDS"):
				screen._category(item[0])
				await process_frame
				check(screen.codex_category == item[0],"codex category " + item[0])
			check(screen.engine.codex_entries(screen.campaign_state,"planet",false).size() > screen.engine.codex_entries(screen.campaign_state,"planet").size(),"archive has locked and unlocked records")
		screen.queue_free()
		await process_frame
	var story = Story.new()
	var briefing = load("res://scenes/briefing.tscn").instantiate()
	briefing.set_campaign_state(story.state)
	briefing.show_scene(story.start_briefing("relay"))
	root.add_child(briefing)
	await process_frame
	story.state.res.favor = 0
	briefing._choose("brief:2")
	check(not briefing.decision_recorded,"unaffordable approach is rejected")
	briefing._choose("brief:0")
	check(briefing.decision_recorded,"briefing choice applies")
	briefing.queue_free()
	await process_frame
	var debrief = load("res://scenes/dialogue.tscn").instantiate()
	debrief.set_campaign_state(story.state)
	debrief.show_scene(story.start_debrief({"mission_id":"relay","won":true}))
	root.add_child(debrief)
	await process_frame
	check(debrief.scene_data.kind == "debrief" and debrief.portrait_count == 1,"debrief loads with holo and speaker")
	if not debrief.scene_data.choices.is_empty():
		debrief._choose(debrief.scene_data.choices[0].id)
		check(debrief.decision_recorded,"debrief choice applies")
	debrief.queue_free()
	await process_frame
	flow.save_path = "user://screens-test-%d.json" % OS.get_process_id()
	flow.new_campaign("normal")
	await process_frame
	await process_frame
	for i in 10:
		if current_scene.scene_file_path.ends_with("temple.tscn"): break
		if current_scene.scene_data.choices.is_empty(): current_scene._finish()
		else: current_scene._choose(current_scene.scene_data.choices[0].id)
		for frame in 4: await process_frame
	flow.open_codex()
	await process_frame
	await process_frame
	check(current_scene.mode == "codex","campaign opens codex")
	for i in 2: await process_frame
	check(current_scene.body.get_children()[-1].get_global_rect().end.y <= current_scene.size.y,"campaign archive return stays in viewport")
	current_scene._finish()
	await process_frame
	await process_frame
	check(current_scene.scene_file_path.ends_with("temple.tscn"),"codex returns to Temple")
	DirAccess.remove_absolute(flow.save_path)
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	print("SCREENS TEST RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
