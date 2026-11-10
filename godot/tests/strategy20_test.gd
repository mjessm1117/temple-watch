extends SceneTree
const Phone = preload("res://scripts/phone_layout.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0
var bounds := Vector2.ZERO

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("STRATEGY20: " + label)

func frames(count: int = 8) -> void:
	for i in count: await process_frame

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "/home/jess/projects/tw-logs/w20/strategy/" + name + ".png"
	check(root.get_texture().get_image().save_png(path) == OK, "capture " + name)

func _building_fraction(view: Control) -> float:
	var camera: Camera3D = view.temple_view.camera
	var vp: SubViewport = view.temple_view.viewport
	var points: Array[Vector2] = []
	for x in [-16.2, 16.2]:
		for y in [-3.5, 17.5]:
			for z in [-4.2, 2.6]:
				points.append(camera.unproject_position(Vector3(x, y, z)) * view.temple_view.size / Vector2(vp.size))
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points: bounds = bounds.expand(point)
	var visible := bounds.intersection(Rect2(Vector2.ZERO, view.size))
	return visible.get_area() / (view.size.x * view.size.y)

func _control(button: Button, label: String) -> void:
	check(button.size.x >= 44 and button.size.y >= 44, label + " >=44")
	var rect := button.get_global_rect()
	check(rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= bounds.x + 1 and rect.end.y <= bounds.y + 1, label + " inside viewport")

func run() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://strategy20-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
	for entry in [[Vector2i(844,390),1.0], [Vector2i(956,440),3.0], [Vector2i(1366,768),1.0]]:
		var logical: Vector2i = entry[0]
		if "--only844" in OS.get_cmdline_user_args() and logical.x != 844: continue
		Phone.test_scale = entry[1]
		Phone.test_touch = 1 if logical.x < 1000 else 0
		Phone.test_mobile = 0
		var physical: Vector2i = logical * int(entry[1])
		DisplayServer.window_set_size(physical)
		root.size = physical; root.content_scale_size = physical
		await frames(4)
		var temple: Control = load("res://scenes/temple.tscn").instantiate()
		root.add_child(temple); await frames(20)
		bounds = temple.size
		var fraction := _building_fraction(temple)
		print("STRATEGY20 %s Temple %.3f view=%s root=%s factor=%s window=%s" % [logical, fraction, temple.temple_view.size, root.size, root.content_scale_factor, DisplayServer.window_get_size()])
		if logical.x < 1000: check(fraction >= 0.65, "Temple building >=65% " + str(logical))
		for name in ["Galaxy", "Arsenal", "Research", "Build", "Command"]:
			_control(temple.nav_buttons[name], "Temple " + name + " " + str(logical))
		if logical.x < 1000:
			_control(temple.find_child("MoreCommands", true, false), "Temple More " + str(logical))
			_control(temple.find_child("RoomsDrawer", true, false), "Temple Rooms " + str(logical))
			_control(temple.find_child("OpenGalaxy", true, false), "Home galaxy card " + str(logical))
			for id in temple.temple_view.buttons:
				var button: Button = temple.temple_view.buttons[id]
				check(button.mouse_filter == Control.MOUSE_FILTER_STOP, "room tappable " + str(id))
				check(button.size.x >= 43.9 and button.size.y >= 43.9, "room target >=44 " + str(id) + " " + str(button.size))
				var room_rect := button.get_global_rect()
				check(room_rect.position.x >= -1 and room_rect.position.y >= -1 and room_rect.end.x <= bounds.x + 1 and room_rect.end.y <= bounds.y + 1, "room inside viewport " + str(id))
		if logical.x == 844 and "--capture" in OS.get_cmdline_user_args(): await _capture("temple-after")
		temple.queue_free(); await process_frame
		var galaxy: Control = load("res://scenes/galaxy.tscn").instantiate()
		root.add_child(galaxy); await frames(20)
		bounds = galaxy.size
		var map_fraction: float = galaxy.map_view.size.x * galaxy.map_view.size.y / (galaxy.size.x * galaxy.size.y)
		print("STRATEGY20 %s Galaxy %.3f map=%s root=%s factor=%s window=%s" % [logical, map_fraction, galaxy.map_view.size, root.size, root.content_scale_factor, DisplayServer.window_get_size()])
		if logical.x < 1000:
			check(map_fraction >= 0.70, "Galaxy map >=70% " + str(logical))
			check(not galaxy.detail_panel.visible, "details hidden until site selected " + str(logical))
			_control(galaxy.find_child("Intelligence", true, false), "Galaxy intelligence " + str(logical))
			_control(galaxy.find_child("TempleReturn", true, false), "Galaxy Temple " + str(logical))
		if logical.x == 844 and "--capture" in OS.get_cmdline_user_args(): await _capture("galaxy-after")
		galaxy._select(0); await frames(20); await create_timer(0.4).timeout
		check(galaxy.detail_panel.visible, "site opens details " + str(logical))
		if logical.x < 1000:
			_control(galaxy.find_child("CloseSite", true, false), "Galaxy close " + str(logical))
			_control(galaxy.back_button, "Galaxy overview " + str(logical))
			for tab in galaxy.tabs.get_children(): check(tab.size.y >= 44, "Galaxy tab >=44 " + str(tab.text))
		if logical.x == 844 and "--capture" in OS.get_cmdline_user_args(): await _capture("galaxy-selected")
		galaxy._overview(); await frames()
		if logical.x < 1000: check(not galaxy.detail_panel.visible, "close restores map " + str(logical))
		galaxy.queue_free(); await process_frame

	Phone.test_scale = 0; Phone.test_touch = -1; Phone.test_mobile = -1
	print("STRATEGY20: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
