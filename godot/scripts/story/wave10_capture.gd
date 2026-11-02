extends SceneTree
## Deterministic screenshots of actual campaign screens for the Wave 10 report.

const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Legacy = preload("res://scripts/campaign/legacy.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var kind := "briefing"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--case="): kind = arg.trim_prefix("--case=")
	var flow = root.get_node("CampaignFlow")
	var campaign = Campaign.new()
	flow.campaign = campaign
	flow.story = Story.new(campaign.state)
	flow.active = true
	var jedi: Array = campaign.state.roster.filter(func(r): return str(r.cls) in ["Guardian","Consular","Sentinel"])
	if jedi.size() >= 2: Legacy.bond_points(campaign,str(jedi[0].id),str(jedi[1].id),30)
	var screen: Node
	match kind:
		"briefing":
			flow.screen = flow.story.start_briefing("relay")
			screen = load("res://scenes/briefing.tscn").instantiate()
		"mid":
			campaign.state.era = 2
			flow.screen = flow.story.next_squad_beat(campaign.state,"relay",2,[])
			screen = load("res://scenes/dialogue.tscn").instantiate()
		"debrief":
			flow.screen = flow.story.start_debrief({"mission_id":"relay","won":true})
			screen = load("res://scenes/dialogue.tscn").instantiate()
		"talk":
			flow.screen = flow.story.next_temple_talk(campaign.state)
			screen = load("res://scenes/dialogue.tscn").instantiate()
		"roster":
			screen = load("res://scenes/temple.tscn").instantiate()
		"battle":
			campaign.state.pending_mission = {"mission_id":"relay","squad":[jedi[0].id,jedi[1].id],"fewer":0}
			campaign.state.flow_stage = "battle"
			screen = load("res://scenes/rescue.tscn").instantiate()
		_: quit(1); return
	root.add_child(screen)
	if kind == "roster":
		screen._change_page("Roster")
		await process_frame
		var scroll: ScrollContainer = screen.page_content.get_parent()
		scroll.scroll_vertical = 390
	if kind == "battle":
		var u: Dictionary = screen.mission.living("player")[0]
		screen.pivot = Vector3(float(u.x),0,float(u.y))
		screen.zoom = 13.0
		screen._update_camera()
	if kind in ["briefing","mid","debrief","talk"]: screen._reveal()
	await create_timer(1.1 if kind != "battle" else 2.0).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave10-story-%s.png" % kind)
	var error := screen.get_viewport().get_texture().get_image().save_png(path)
	print("WAVE10 SHOT %s: %s" % [kind,"ok" if error == OK else str(error)])
	quit(0 if error == OK else 1)
