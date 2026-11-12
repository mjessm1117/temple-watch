extends SceneTree
## Local Low renderer evidence for the first defense mission.
const Campaign = preload("res://scripts/campaign/state.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Cue = preload("res://scripts/w29a_move_cue.gd")
const OUTPUT := "/home/jess/projects/tw-logs/w29/phone29/"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1
	var flow: Node = root.get_node("CampaignFlow")
	for size in [Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = size; root.content_scale_size = size
		DisplayServer.window_set_size(size)
		flow.campaign = Campaign.new("story"); flow.story = flow.campaign.story; flow.active = true
		flow.campaign.state.flow_stage = "battle"
		flow.campaign.state.pending_mission = {"mission_id": "relay", "squad": flow.campaign.state.roster.slice(0, 5).map(func(member): return member.id), "fewer": 0}
		var game: Node = load("res://scenes/rescue.tscn").instantiate()
		root.add_child(game)
		for frame in 60: await process_frame
		var image: Image = root.get_texture().get_image()
		var label := "%dx%d" % [size.x, size.y]
		print("W29A CAPTURE ", label, " idle ", image.save_png(OUTPUT + "after-" + label + "-native.png"))
		var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
		var route: Dictionary = game.mission.reach_tiles(actor, 2)
		var rules: Script = load("res://scripts/shot.gd")
		var best := Vector2i(-1, -1)
		var rank := -1
		for tile in route.get("costs", {}):
			if tile == Vector2i(int(actor.x), int(actor.y)): continue
			var elevation: float = float(rules.call("elevation", game.mission, tile)) if rules != null and rules.has_method("elevation") else 0.0
			var point: Vector2 = game.camera.unproject_position(Vector3(tile.x, elevation * 0.7 + 0.2, tile.y))
			if not game.hud_controls.phone.hud_safe_rect28().grow(-24.0).has_point(point): continue
			var cue: Dictionary = Cue.at(game.mission, actor, tile)
			var score := 3 if bool(cue.flanked) else 2 if bool(cue.exposed) else 1 if int(cue.cover) > 0 else 0
			if score > rank: rank = score; best = tile
		if best.x >= 0:
			game.preview_tile = best
			game._refresh_highlights()
			game.hud_controls.phone._refresh_odds()
			for frame in 12: await process_frame
			image = root.get_texture().get_image()
			print("W29A CAPTURE ", label, " preview ", best, " cue ", game.hud_controls.phone.odds_badge.text, " ", image.save_png(OUTPUT + "after-" + label + "-preview-native.png"))
		game.queue_free()
		await process_frame
	quit(0)
