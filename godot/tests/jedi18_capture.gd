extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Promotion = preload("res://scripts/campaign/promotion_screen.gd")
const OUT = "res://../docs/godot/w18/jedi/"

func _initialize() -> void: capture.call_deferred()

func shot(name: String, delay: float = 0.35) -> void:
	await create_timer(delay).timeout
	await process_frame
	var path := ProjectSettings.globalize_path(OUT + name + ".png")
	var status := root.get_texture().get_image().save_png(path)
	print("JEDI18 SHOT ", name, " ", status)

func capture() -> void:
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://jedi18-capture.json"
	flow.campaign = Campaign.new()
	flow.active = true
	var r: Dictionary = flow.campaign.soldier("u1")
	for path in ["Sage", "Guardian"]:
		var row: Dictionary = preload("res://scripts/class_registry.gd").class_data(path)
		r.cls = path
		r.classes = [path.to_lower(), "knight", "duelist"]
		r.rank = 5
		r.title = "Master"
		r.spec = "a"
		r.picks = [row.signature, row.tree.trunk["2"][0], row.tree.specs.a.sig, row.tree.specs.a["4"][0]]
		r.pick = 5
		var screen := Promotion.new()
		root.add_child(screen)
		screen.setup(flow.campaign, "u1")
		await shot("promotion-" + path.to_lower() + "-844x390")
		screen.queue_free()
		await process_frame
	root.size = Vector2i(667, 375)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	var narrow := Promotion.new()
	root.add_child(narrow)
	narrow.setup(flow.campaign, "u1")
	await shot("promotion-guardian-667x375")
	narrow.queue_free()
	await process_frame
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	var battle = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	await create_timer(1.6).timeout
	battle.phase_banner.visible = false
	var actor: Dictionary = battle.mission.unit_by_id(battle.selected_id)
	actor.name = "Consular"
	actor.class_name = "Consular"
	actor.kit = ["consular_grand_living_force"]
	actor.hp = 2
	for ally in battle.mission.living("player"):
		if ally != actor: ally.hp = maxi(1, int(ally.max_hp) - 5)
	actor.focus = 4
	actor.focus_left = 4
	actor.ap = 2
	battle._refresh()
	await shot("battle-consular-grand-button", 0.08)
	battle.action = "consular_grand_living_force"
	battle._use_ability()
	battle.phase_banner.visible = false
	battle.highlights.visible = false
	await shot("battle-consular-living-force", 0.4)
	print("JEDI18 CAPTURE ability uses ", battle.mission.ability_uses.get("consular_grand_living_force", 0))
	battle.queue_free()
	quit()
