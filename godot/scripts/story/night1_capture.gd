extends SceneTree
## Disposable fixture captures from the real story and codex scenes.

const Campaign = preload("res://scripts/campaign/state.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Arcs = preload("res://scripts/story/arc_night1.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var kind := "callback-briefing"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--case="): kind = arg.trim_prefix("--case=")
	var flow = root.get_node("CampaignFlow")
	var campaign = Campaign.new()
	flow.campaign = campaign
	flow.story = Story.new(campaign.state)
	flow.active = true
	var scene: Node
	match kind:
		"callback-briefing":
			campaign.state.flags.e1_strike_known = true
			flow.screen = flow.story.start_briefing("dock")
			scene = load("res://scenes/briefing.tscn").instantiate()
		"arc-talk":
			campaign.state.story.done = 1
			flow.screen = Arcs.next_talk(campaign.state,[flow.story.table("N1_ARCS")[0]])
			scene = load("res://scenes/dialogue.tscn").instantiate()
		"arc-resolution":
			campaign.state.story.done = 2
			campaign.state.personal_arcs.arc_0 = 2
			flow.screen = Arcs.next_talk(campaign.state,[flow.story.table("N1_ARCS")[0]])
			scene = load("res://scenes/dialogue.tscn").instantiate()
		"journal":
			campaign.state.flags.archive_backup = true
			campaign.state.personal_arcs.arc_0 = 1
			Arcs.person(campaign.state,"Tor Saalen").status = "dead"
			scene = load("res://scenes/codex.tscn").instantiate()
			scene.codex_category = "journal"
		"interlude":
			campaign.state.flags.e1_strike_known = true
			campaign.state.flags.archive_backup = true
			campaign.state.era = 2
			flow.screen = flow.story.era_interlude(campaign.state,1)
			scene = load("res://scenes/dialogue.tscn").instantiate()
		_: quit(1); return
	root.add_child(scene)
	if kind != "journal": scene._reveal()
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/night1-story-%s.png" % kind)
	var image: Image = scene.get_viewport().get_texture().get_image()
	if image.get_width() != 1920 or image.get_height() != 1080: image.resize(1920,1080,Image.INTERPOLATE_NEAREST)
	print("NIGHT1 SHOT %s %dx%d %s" % [kind,image.get_width(),image.get_height(),image.save_png(path)])
	quit(0)
