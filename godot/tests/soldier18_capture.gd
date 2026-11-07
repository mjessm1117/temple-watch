extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Promotion = preload("res://scripts/campaign/promotion_screen.gd")
const OUT = "res://../docs/godot/w18/soldier/"

func _initialize() -> void:
	call_deferred("capture")

func _size() -> void:
	var value := Vector2i(844, 390)
	root.size = value
	root.content_scale_size = value
	DisplayServer.window_set_size(value)

func _shot(name: String, delay: float = 0.4) -> void:
	await create_timer(delay).timeout
	await process_frame
	var path := ProjectSettings.globalize_path(OUT + name + ".png")
	print("SOLDIER18 SHOT ", name, " ", root.get_texture().get_image().save_png(path))

func capture() -> void:
	_size()
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://soldier18-capture.json"
	flow.campaign = Campaign.new()
	flow.active = true
	var r: Dictionary = flow.campaign.soldier("u1")
	for class_id in ["Sniper", "Droid"]:
		r.cls = class_id
		r.classes = [class_id.to_lower()]
		r.rank = 1 if class_id == "Sniper" else 4
		r.picks = []
		r.pick = 1
		r.spec = ""
		var screen := Promotion.new()
		root.add_child(screen)
		screen.setup(flow.campaign, "u1")
		await process_frame
		await _shot("promotion-" + class_id.to_lower() + "-844x390")
		screen.queue_free()
		await process_frame
	var battle = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(battle)
	await create_timer(1.0).timeout
	var actor: Dictionary = battle.mission.living("player")[2]
	var enemy: Dictionary = battle.mission.living("enemy")[0]
	actor.class_name = "Sniper"
	actor.name = "Republic Sniper"
	actor.kit.append("sniper_squadsight")
	actor.range = 16
	enemy.x = int(actor.x) + 3
	enemy.y = int(actor.y)
	enemy.awake = true
	enemy.spotted = true
	battle._select(int(actor.id))
	battle.action = "sniper_squadsight"
	battle._refresh()
	battle._use_ability(int(enemy.id))
	await create_timer(0.6).timeout
	await _shot("battle-sniper-squadsight-844x390", 0.05)
	battle.queue_free()
	quit()
