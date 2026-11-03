extends SceneTree
## Disposable story fixtures for Wave 11 screenshot review.

const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var kind := "villain"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--case="): kind = arg.trim_prefix("--case=")
	var flow = root.get_node("CampaignFlow")
	var campaign = Campaign.new()
	flow.campaign = campaign
	flow.story = Story.new(campaign.state)
	flow.active = true
	match kind:
		"before":
			campaign.state.story.done = 1
			flow.screen = preload("res://scripts/story/arc_night1.gd").next_talk(campaign.state,[flow.story.table("N1_ARCS")[0]])
		"villain":
			campaign.state.story.done = 1
			flow.screen = flow.story.next_villain_beat(campaign.state)
		"squad":
			campaign.state.story.done = 1
			flow.screen = preload("res://scripts/story/scenes11_squad.gd").next(campaign.state,[flow.story.table("W11_SCENES")[1]])
		"journal":
			campaign.state.story.done = 2
			flow.story.next_villain_beat(campaign.state)
			flow.story.apply_choice(campaign.state,"villain:light")
			preload("res://scripts/story/scenes11_squad.gd").next(campaign.state,[flow.story.table("W11_SCENES")[0]])
			flow.story.apply_choice(campaign.state,"scene11:0")
		_: quit(1); return
	var scene = load("res://scenes/codex.tscn" if kind == "journal" else "res://scenes/dialogue.tscn").instantiate()
	if kind == "journal": scene.codex_category = "journal"
	root.add_child(scene)
	if kind != "journal": scene._reveal()
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave11-story-%s.png" % kind)
	var picture: Image = scene.get_viewport().get_texture().get_image()
	if picture.get_width() != 1920 or picture.get_height() != 1080: picture.resize(1920,1080,Image.INTERPOLATE_NEAREST)
	print("STORY11 SHOT %s %s" % [kind,picture.save_png(path)])
	quit(0)
