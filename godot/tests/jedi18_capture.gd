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
	var battle = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	await create_timer(1.6).timeout
	battle.phase_banner.visible = false
	var actor: Dictionary = battle.mission.unit_by_id(battle.selected_id)
	actor.name = "Guardian"
	actor.class_name = "Guardian"
	actor.kit = ["guardian_deflect"]
	actor.focus = 4
	actor.focus_left = 4
	actor.ap = 2
	battle._refresh()
	battle.action = "guardian_deflect"
	battle._use_ability()
	battle.phase_banner.visible = false
	battle.highlights.visible = false
	await shot("battle-guardian-deflect", 0.08)
	print("JEDI18 CAPTURE ability uses ", battle.mission.ability_uses.get("guardian_deflect", 0))
	battle.queue_free()
	quit()
