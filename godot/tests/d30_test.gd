extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Classes = preload("res://scripts/class_registry.gd")
const Signature = preload("res://scripts/w27d_ability_signature.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("D30 " + label)

func near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) <= 0.05 and absf(a.g - b.g) <= 0.05 and absf(a.b - b.b) <= 0.05

func run() -> void:
	var definitions := [
		["guardian_deflect", Classes.class_data("guardian").abilities.guardian_deflect],
		["trooper_thermal_detonator", Classes.class_data("trooper").abilities.trooper_thermal_detonator],
		["medic_bacta_spray", Classes.class_data("medic").abilities.medic_bacta_spray],
	]
	var colors: Array[Color] = []
	for row in definitions:
		var profile: Dictionary = Signature.profile(row[0], row[1])
		check(profile.has("color"), row[0] + " has a class tell")
		colors.append(profile.get("color", Color.BLACK))
	check(colors[0] != colors[1] and colors[1] != colors[2] and colors[0] != colors[2], "Jedi, soldier, and medic colors differ")
	var melee: Dictionary = Signature.profile("duelist_kill_chain", Classes.class_data("duelist").abilities.duelist_kill_chain)
	var sniper_id: String = str(Classes.class_data("sniper").signature)
	var ranged: Dictionary = Signature.profile(sniper_id, Classes.class_data("sniper").abilities[sniper_id])
	var class_colors := [colors[0], colors[1], colors[2], melee.get("color", Color.BLACK), ranged.get("color", Color.BLACK)]
	var unique_colors := {}
	for color in class_colors: unique_colors[color] = true
	check(unique_colors.size() == 5, "five class families have distinct colors")
	check(melee.get("pulse", 0.0) == 0.3, "melee tell pulses in 0.3 seconds")
	check(ranged.get("shape", "") == "narrow_arc" and absf(float(ranged.get("radius", 0.0)) - 0.8) <= 0.01 and absf(float(ranged.get("color", Color.BLACK).a) - 0.7) <= 0.01, "ranged tell is a narrow white arc")
	var chain_def: Dictionary = Classes.class_data("guardian").abilities.guardian_challenging_glare
	var yellow: Dictionary = Signature.profile("guardian_challenging_glare", chain_def, {"combo_tags":{"MARKED":1}})
	check(near(yellow.get("color", Color.BLACK), Color("f0e020")), "ready chain overrides class with yellow")
	check(Signature.profile("guardian_challenging_glare", chain_def).get("color") == Color("e8a030"), "unready chain keeps class color")
	Phone.test_touch = 1; Phone.test_mobile = 1; Phone.test_scale = 1
	for size in [Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = size; root.content_scale_size = size
		DisplayServer.window_set_size(size)
		var flow: Node = root.get_node("CampaignFlow")
		flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
		flow.campaign.state.flow_stage = "battle"
		var squad: Array = flow.campaign.state.roster.slice(0, 5).map(func(member): return member.id)
		flow.campaign.state.pending_mission = {"mission_id":"relay", "squad":squad, "fewer":0}
		var game: Node = load("res://scenes/rescue.tscn").instantiate()
		root.add_child(game)
		for i in 12: await process_frame
		var hud = game.hud_controls.phone
		check(hud != null, "%s phone HUD loads" % size)
		if hud != null:
			var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
			var enemy: Dictionary = game.mission.living("enemy")[0]
			for id in ["guardian_challenging_glare", "guardian_deflect", "trooper_thermal_detonator", "medic_bacta_spray", "medpac", "revive"]:
				if not actor.kit.has(id): actor.kit.append(id)
			enemy.combo_tags = {"MARKED":int(actor.id)}
			game.target_id = int(enemy.id)
			game._refresh()
			hud.open_card = "more"
			hud.refresh()
			var ids: Array[String] = []
			for child in hud.popup_body.get_children():
				if child is Button and child.has_meta("ability_id"):
					ids.append(str(child.get_meta("ability_id")))
					check(child.custom_minimum_size.y >= 44.0, "%s MORE %s tap height" % [size, child.get_meta("ability_id")])
			check(ids.has("guardian_challenging_glare"), "%s chain ability in MORE" % size)
			check(ids.has("medpac") or ids.has("revive"), "%s utility in MORE" % size)
			if ids.has("guardian_challenging_glare") and (ids.has("medpac") or ids.has("revive")):
				var utility_at: int = ids.find("medpac") if ids.has("medpac") else ids.find("revive")
				check(ids.find("guardian_challenging_glare") < utility_at, "%s chain before utility" % size)
		game.queue_free()
		await process_frame
	Phone.test_touch = -1; Phone.test_mobile = -1; Phone.test_scale = 0
	print("D30 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
