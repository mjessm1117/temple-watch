extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Promotion = preload("res://scripts/campaign/promotion_screen.gd")
const OUT = "/home/jess/projects/tw-logs/w28/soldier/"

func _initialize() -> void:
	call_deferred("capture")

func _shot(label: String) -> void:
	await create_timer(0.5).timeout
	await process_frame
	var args := OS.get_cmdline_user_args()
	var stage := "before" if "--before" in args else "after"
	var size: Vector2i = root.size
	var name := "%s-%s-%dx%d" % [stage, label, size.x, size.y]
	var code := root.get_texture().get_image().save_png(OUT + name + ".png")
	var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	print("W28B CAPTURE %s code=%d draws=%d" % [name, code, draws])

func capture() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://w28b-capture.json"
	flow.campaign = Campaign.new()
	flow.active = true
	var roster: Dictionary = flow.campaign.soldier("u1")
	roster.n = "Rex Vale"
	for class_id in ["trooper", "scout", "medic"]:
		roster.cls = class_id.capitalize()
		roster.classes = [class_id]
		roster.rank = 2
		roster.picks = []
		roster.pick = 1
		roster.spec = ""
		var screen := Promotion.new()
		root.add_child(screen)
		screen.setup(flow.campaign, "u1")
		await _shot("promotion-" + class_id)
		screen.queue_free()
		await process_frame
	await _battle("trooper", "suppress", "rapidFire")
	await _battle("scout", "mark", "deadeye")
	await _battle("medic", "medic_toxin_dart", "protocol", true)
	quit()

func _battle(class_id: String, setup_id: String, finish_id: String, droid: bool = false) -> void:
	var battle = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(battle)
	await create_timer(1.0).timeout
	var allies: Array[Dictionary] = battle.mission.living("player")
	var setter: Dictionary = allies[1]
	var finisher: Dictionary = allies[2]
	var enemy: Dictionary = battle.mission.living("enemy")[0]
	setter.kit.append(setup_id)
	finisher.kit.append(finish_id)
	setter.class_name = class_id.capitalize()
	finisher.class_name = class_id.capitalize()
	setter.x = int(finisher.x)
	setter.y = int(finisher.y)
	setter.range = 16
	finisher.range = 16
	enemy.x = int(finisher.x) + 2
	enemy.y = int(finisher.y)
	enemy.hp = 100
	enemy.max_hp = 100
	enemy.awake = true
	enemy.spotted = true
	if droid: enemy.droid = true
	battle.mission.abilities[setup_id].chance = 100
	battle.mission.abilities[finish_id].chance = 100
	print("W28B REASON ", class_id, " ", battle.mission.ability_reason(int(setter.id), setup_id))
	print("W28B SETUP ", class_id, " ", battle.mission.use_ability(int(setter.id), setup_id, int(enemy.id)))
	battle._select(int(finisher.id))
	battle._refresh()
	await _shot("battle-" + class_id + "-combo")
	print("W28B FINISH ", class_id, " ", battle.mission.use_ability(int(finisher.id), finish_id, int(enemy.id)))
	battle._refresh()
	await _shot("battle-" + class_id + "-finish")
	battle.queue_free()
	await process_frame
