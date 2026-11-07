extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Promotion = preload("res://scripts/campaign/promotion_screen.gd")
const OUT = "res://../docs/godot/w17/core/"

func _initialize() -> void:
	call_deferred("capture")

func _size(value: Vector2i) -> void:
	root.size = value
	root.content_scale_size = value
	DisplayServer.window_set_size(value)

func _shot(name: String) -> void:
	await create_timer(0.5).timeout
	await process_frame
	var path := ProjectSettings.globalize_path(OUT + name + ".png")
	print("CORE17 SHOT ", name, " ", root.get_texture().get_image().save_png(path))

func capture() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://core17-capture.json"
	flow.campaign = Campaign.new()
	flow.active = true
	flow.campaign.soldier("u1").rank = 5
	flow.campaign.soldier("u1").title = "Master"
	for size in [Vector2i(844, 390), Vector2i(667, 375)]:
		_size(size)
		var screen := Promotion.new()
		root.add_child(screen)
		screen.setup(flow.campaign, "u1")
		await _shot("promotion-%dx%d" % [size.x, size.y])
		screen.queue_free()
		await process_frame
	_size(Vector2i(844, 390))
	var temple = load("res://scenes/temple.tscn").instantiate()
	root.add_child(temple)
	await process_frame
	temple._change_page("Roster")
	await _shot("barracks-padawan-hire")
	temple.queue_free()
	await process_frame
	var battle = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	battle.action = "guard"
	battle._use_ability()
	await create_timer(0.8).timeout
	await _shot("battle-guard-ability")
	battle.queue_free()
	quit()
