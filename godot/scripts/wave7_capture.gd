extends SceneTree
## Native-window captures of the integrated campaign, with an isolated review save.
const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
var flow

func _initialize() -> void: run.call_deferred()
func settle() -> void:
	await create_timer(0.7).timeout
	for i in 4: await process_frame
func shot(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave7-final-%s.png" % name)
	print("CAPTURE ",name," ",root.get_texture().get_image().save_png(path))

func run() -> void:
	root.size = Vector2i(1366,768)
	flow = root.get_node("CampaignFlow")
	flow.save_path = "user://wave7-capture.json"
	flow.campaign = Campaign.new("normal"); flow.story = Story.new(flow.campaign.state); flow.active = true
	var c = flow.campaign
	c.advance_days(30)
	# Use real progression data for the developed review fixture.
	c.state.strategy.squad_upgrades = 1
	c.state.res.credits = 850; c.state.res.intel = 7
	c.refresh_options()
	flow.go("galaxy"); await settle()
	current_scene._tab("Sith ops")
	await shot("galaxy")
	flow.open_intelligence("report")
	await shot("council")
	flow.intelligence.queue_free(); await process_frame
	for event in c.sith.pending_events(): c.sith.acknowledge(str(event.id))
	var previous := current_scene
	var temple = load("res://scenes/temple.tscn").instantiate()
	root.add_child(temple) # Bind the real screen before making it current; no story popup in this capture.
	current_scene = temple; previous.queue_free(); await settle()
	current_scene._change_page("Build")
	await shot("temple-build")
	flow.active = true
	var index := 0
	for i in c.state.options.size():
		if c.state.options[i].get("kind","") == "project": index = i; break
	flow.prepare_briefing(index); await settle()
	flow.story_finished(); await settle()
	await shot("loadout-five")
	flow.launch_squad(current_scene.selected); await settle()
	var game = current_scene
	game.set_process(false)
	# Frame the squad and its actual non-rescue map in the live scene.
	game.pivot = Vector3(float(game.mission.spec.width)*0.5,0,float(game.mission.spec.height)*0.58)
	game.zoom = 38; game._update_camera(); game._refresh(); game.scene_view.arrange_labels()
	await settle()
	game.scene_view.arrange_labels()
	await shot("battle-sabotage")
	flow.active = false
	current_scene.queue_free(); current_scene = null; await process_frame
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	quit()
