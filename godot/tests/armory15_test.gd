extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Actor = preload("res://scripts/campaign/loadout_actor.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1; push_error("ARMORY15: " + message)

func run() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://armory15-test.json"
	flow.campaign = Campaign.new(); flow.active = true
	flow.campaign.soldier("u1").gear.mk["armor:robes"] = 2
	var graphics = root.get_node("Graphics")
	var old_tier: String = graphics.effective
	graphics.effective = "low"
	root.size = Vector2i(844, 390); root.content_scale_size = root.size
	var screen = load("res://scenes/squad.tscn").instantiate()
	root.add_child(screen); await process_frame
	screen.inspect(0); await process_frame
	var room: Node3D = screen.stage.get_node_or_null("Armory15Hangar")
	check(room != null and room.get_child_count() >= 5, "instanced 3D hangar exists")
	check(room.get_node_or_null("LightPools") != null, "Low uses emissive pools")
	check(room.get_children().filter(func(n): return n is SpotLight3D).is_empty(), "Low adds no ceiling spotlights")
	var actor = screen.stage.actors[screen.focus_index]
	var original_model: Node3D = actor.model
	var plate: MeshInstance3D = actor.find_child("ArmorPlate", true, false)
	check(plate != null and plate.visible, "equipped armor has a visible plate")
	var original_material: Material = plate.material_override
	check(screen.change_gear("color", "", "#c58cff"), "crystal changes")
	actor = screen.stage.actors[screen.focus_index]
	check(actor.model != original_model and actor.tint == Color("c58cff"), "hero updates within the gear action frame")
	var new_plate: MeshInstance3D = actor.find_child("ArmorPlate", true, false)
	check(new_plate != null and new_plate.material_override != original_material, "hero equipment material is rebuilt")
	check(screen.change_gear("armor", "", "none"), "armor slot equips")
	actor = screen.stage.actors[screen.focus_index]
	check(not actor.find_child("ArmorPlate", true, false).visible, "armor equip changes visible plate")
	var art: TextureRect = screen.arsenal.preview_card.find_child("LargeGearArt", true, false)
	check(art != null and art.size.x >= 120 and art.size.y >= 120, "phone preview art is at least 120 pixels")
	for tile in screen.arsenal.slot_row.get_children():
		check(not tile.get_node("SlotLabel").get_global_rect().intersects(tile.get_node("GearArt").get_global_rect()), "%s label clears icon" % tile.name)
	var hero_bottom := -INF
	for x in [-0.55, 0.55]:
		for z in [-0.55, 0.55]:
			var point: Vector2 = screen.stage.camera.unproject_position(actor.global_position + Vector3(x, 0, z))
			hero_bottom = maxf(hero_bottom, screen.stage_container.global_position.y + point.y)
	check(hero_bottom <= screen.card_scroll.get_global_rect().position.y - 8.0, "phone hero clears roster")
	await create_timer(0.15).timeout
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	check(draws <= 130, "Low phone draw ceiling 130 (observed %d)" % draws)
	screen.queue_free(); await process_frame
	graphics.effective = "high"
	root.size = Vector2i(1366, 768); root.content_scale_size = root.size
	screen = load("res://scenes/squad.tscn").instantiate()
	root.add_child(screen); await process_frame
	screen.inspect(0); await process_frame
	room = screen.stage.get_node_or_null("Armory15Hangar")
	check(room != null and room.get_children().filter(func(n): return n is SpotLight3D).size() == 2, "High has two ceiling light pools")
	art = screen.arsenal.preview_card.find_child("LargeGearArt", true, false)
	check(art != null and art.size.x >= 200 and art.size.y >= 200, "desktop preview art is at least 200 pixels")
	var upgrade_button: Button = screen.arsenal.offers[0].button
	check(upgrade_button.get_global_rect().end.y <= screen.drawer.get_global_rect().end.y - 8, "desktop Upgrade clears drawer bottom")
	for id in ["u1", "u3"]:
		for armor in (["none", "robes", "armoredRobes", "masterRobes"] if id == "u1" else ["none", "light", "medium", "heavy", "beskar"]):
			for mark in [1, 2, 3]:
				var soldier: Dictionary = flow.campaign.soldier(id).duplicate(true)
				soldier.gear.armor = armor
				soldier.gear.mk["armor:" + armor] = mark
				var fitted := Actor.new(); fitted.setup(soldier, true)
				var fitted_plate: MeshInstance3D = fitted.find_child("ArmorPlate", true, false)
				var shoulder_plate: MeshInstance3D = fitted.find_child("ShoulderPlate", true, false)
				var has_armor: bool = armor in ["medium", "heavy", "armoredRobes", "beskar", "masterRobes"] or mark > 1
				check(fitted_plate != null and fitted_plate.visible == has_armor and fitted_plate.get_parent() is BoneAttachment3D and shoulder_plate.get_parent() is BoneAttachment3D, "%s %s Mk %d plates follow bones" % [id, armor, mark])
				fitted.free()
	screen.queue_free(); await process_frame
	graphics.effective = old_tier
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("ARMORY15 TEST RESULTS: %d checks, %d failures; Low draw monitor=%d" % [checks, failures, draws])
	quit(1 if failures else 0)
