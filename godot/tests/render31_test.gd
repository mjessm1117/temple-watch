extends SceneTree
## Low portrait render budget. The full gate action peak is measured by the
## W31 metrics capture under a rendering display; headless counters can be 0.
const Campaign = preload("res://scripts/campaign/state.gd")
const Phone = preload("res://scripts/phone_layout.gd")
const Batch = preload("res://scripts/map_art_batch.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func check_batch() -> void:
	var batch := Batch.new()
	var material := StandardMaterial3D.new()
	for x in 10:
		for y in 10:
			batch.put("terrain", material, Vector3(x, 0, y), Vector3.ONE)
	var parent := Node3D.new()
	batch.flush(parent)
	check(parent.get_child_count() == 1, "100 floor tiles share one draw node")
	if parent.get_child_count() == 1:
		var instance := parent.get_child(0) as MultiMeshInstance3D
		check(instance != null and instance.multimesh.instance_count == 100, "floor batch contains all 100 tiles")
	parent.free()

func run() -> void:
	check_batch()
	var size := Vector2i(390, 844)
	root.size = size
	root.content_scale_size = size
	DisplayServer.window_set_size(size)
	Phone.test_touch = 1
	Phone.test_mobile = 1
	Phone.test_scale = 1
	var graphics: Node = root.get_node("Graphics")
	check("--graphics=low" in OS.get_cmdline_user_args() and graphics.requested == "low" and graphics.effective == "low", "Low tier active from command line")
	var flow: Node = root.get_node("CampaignFlow")
	flow.save_path = "user://render31-%d.json" % OS.get_process_id()
	var campaign = Campaign.new("normal")
	campaign.select_mission(0)
	campaign.state.flow_stage = "battle"
	flow.campaign = campaign
	flow.story = campaign.story
	flow.active = true
	var game: Node = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 20: await process_frame
	check(str(game.mission.spec.id) == "relay", "portrait fixture is the gate mission")
	var body_rims := 0
	var attachment_meshes := 0
	var attachment_rims := 0
	var side_badges := 0
	for unit in game.figures.get_children():
		if unit.get_script() == null or not str(unit.get_script().resource_path).ends_with("/unit_view.gd"): continue
		var badge := unit.get_node_or_null("SideBadge26") as Sprite3D
		if badge != null and badge.visible: side_badges += 1
		for mesh in unit.find_children("*", "MeshInstance3D", true, false):
			var parent: Node = mesh.get_parent()
			var attached := false
			while parent != null and parent != unit:
				if parent is BoneAttachment3D: attached = true
				parent = parent.get_parent()
			if attached:
				attachment_meshes += 1
				if mesh.material_overlay != null: attachment_rims += 1
			elif mesh.material_overlay != null: body_rims += 1
	check(body_rims > 0 and side_badges > 0, "unit body rims and side badges remain readable")
	check(attachment_meshes > 0 and attachment_rims == 0, "Low omits duplicate attachment overlay passes")
	for i in 2: await process_frame
	var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if draws > 0:
		check(draws <= 150, "gate portrait Low initial draw count <=150: %d" % draws)
		print("RENDER31 gate portrait Low initial draws=", draws)
	else:
		check(graphics.effective == "low" and attachment_rims == 0, "headless draw counter unavailable; Low batch structure verified")
		print("RENDER31 headless draw counter=0; structural budget assertion used")
	game.queue_free()
	await process_frame
	if FileAccess.file_exists(flow.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	Phone.test_touch = -1
	Phone.test_mobile = -1
	Phone.test_scale = 0
	print("RENDER31 RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
