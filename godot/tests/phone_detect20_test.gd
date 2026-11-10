extends SceneTree
const Phone = preload("res://scripts/phone_layout.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PHONE_DETECT20: " + label)

func hint_text(node: Node) -> Array[String]:
	var found: Array[String] = []
	if node is Control and node.is_visible_in_tree():
		var value := ""
		if node is Label: value = node.text
		elif node is Button: value = node.text
		if value.contains("Tab") or value.contains("Esc") or value.contains("Enter"):
			found.append(value)
	for child in node.get_children(): found.append_array(hint_text(child))
	return found

func run() -> void:
	Phone.test_touch = 0; Phone.test_mobile = 0
	for entry in [[Vector2i(2868,1320),3.0], [Vector2i(2556,1179),3.0], [Vector2i(844,390),1.0], [Vector2i(1792,828),2.0]]:
		Phone.test_scale = entry[1]
		check(Phone.narrow(entry[0]), "%s @ %s uses phone layout" % entry)
	for entry in [Vector2i(1366,768), Vector2i(1920,1080)]:
		Phone.test_scale = 1.0
		check(not Phone.narrow(entry), "%s desktop without touch" % entry)
	Phone.test_scale = 1.0; Phone.test_touch = 1; Phone.test_mobile = 0
	check(Phone.narrow(Vector2i(1366,768)), "touchscreen with logical short side under 900")
	Phone.test_touch = 0; Phone.test_mobile = 1
	check(Phone.narrow(Vector2i(1366,768)), "mobile feature with logical short side under 900")
	Phone.test_touch = 1; Phone.test_mobile = 0
	DisplayServer.window_set_size(Vector2i(844,390))
	root.size = Vector2i(844,390); root.content_scale_size = Vector2i(844,390)
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://phone-detect20-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	for entry in [["Temple", "res://scenes/temple.tscn"], ["loadout", "res://scenes/squad.tscn"], ["battle", "res://scenes/rescue.tscn"]]:
		var scene: Node = load(entry[1]).instantiate()
		root.add_child(scene)
		for i in 8: await process_frame
		check(hint_text(scene).is_empty(), "%s has no visible Tab/Esc/Enter hints: %s" % [entry[0], hint_text(scene)])
		scene.queue_free()
		await process_frame
	Phone.test_scale = 0.0; Phone.test_touch = -1; Phone.test_mobile = -1
	print("PHONE_DETECT20: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
