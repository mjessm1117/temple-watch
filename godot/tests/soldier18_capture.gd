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
	r.n = "Rex Vale"
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
	enemy.x = int(actor.x) + 2
	enemy.y = int(actor.y)
	enemy.awake = true
	enemy.spotted = true
	battle._select(int(actor.id))
	battle.action = "sniper_squadsight"
	battle._refresh_highlights(true)
	print("SOLDIER18 SHOT reason ", battle.mission.ability_reason(int(actor.id), "sniper_squadsight"), " phase ", battle.mission.phase)
	battle._use_ability(int(enemy.id))
	await create_timer(1.6).timeout
	print("SOLDIER18 SHOT uses ", battle.mission.ability_uses.get("sniper_squadsight", 0), " enemy hp ", enemy.hp)
	battle.pivot = Vector3((float(actor.x) + float(enemy.x)) * 0.5, 0, (float(actor.y) + float(enemy.y)) * 0.5)
	battle.zoom = 15.0
	battle._update_camera()
	battle._refresh()
	if int(battle.mission.ability_uses.get("sniper_squadsight", 0)) > 0:
		var from := Vector3(float(actor.x), 1.4, float(actor.y))
		var to := Vector3(float(enemy.x), 1.4, float(enemy.y))
		battle.fx.bolt(from, to, false, false)
		battle.fx.float_text(to - Vector3.UP * 0.6, "SQUADSIGHT", Color("f0cf86"), true)
	await _shot("battle-sniper-squadsight-844x390", 0.05)
	battle.queue_free()
	quit()
