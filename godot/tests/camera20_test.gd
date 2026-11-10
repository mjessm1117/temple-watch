extends SceneTree
const CameraRules = preload("res://scripts/battle11_camera.gd")
const Mission = preload("res://scripts/mission.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMERA20: " + why)

func _buttons(node: Node, found: Array[BaseButton]) -> void:
	if node is BaseButton and node.is_visible_in_tree() and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		found.append(node)
	for child in node.get_children(): _buttons(child, found)

func _visible_rect(button: Control) -> Rect2:
	var rect := button.get_global_rect().intersection(Rect2(Vector2.ZERO, root.size))
	var parent := button.get_parent()
	while parent is Control:
		if parent.clip_contents or parent is ScrollContainer: rect = rect.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return rect

func run() -> void:
	for id in ["relay", "rescue", "ilum"]:
		var path: String = preload("res://scripts/map_catalog.gd").resolve(id)
		var mission = Mission.new(17, path)
		var yaw: float = CameraRules.battle_heading(mission)
		var squad := Vector2.ZERO
		for u in mission.living("player"): squad += Vector2(u.x, u.y)
		squad /= float(mission.living("player").size())
		var target := Vector2.ZERO
		var n := 0
		for p in mission.spec.objective.get("points", []): target += Vector2(p[0], p[1]); n += 1
		if n == 0 and bool(mission.prisoner.get("active", false)):
			target += Vector2(mission.prisoner.x, mission.prisoner.y); n += 1
		for u in mission.living("enemy"): target += Vector2(u.x, u.y); n += 1
		target /= float(n)
		var camera := Camera3D.new(); root.add_child(camera)
		camera.position = Vector3(sin(yaw) * 10.0, 13.0, cos(yaw) * 10.0)
		camera.look_at(Vector3.ZERO)
		var forward := Vector2(-camera.global_basis.z.x, -camera.global_basis.z.z)
		var angle := rad_to_deg(forward.angle_to(target - squad))
		camera.queue_free()
		print("CAMERA20 %s yaw %.1f angle %.1f" % [id, rad_to_deg(yaw), absf(angle)])
		check(absf(angle) < 50.0, id + " faces action")
		check(absf(yaw / (PI / 4.0) - roundf(yaw / (PI / 4.0))) < 0.001, id + " snapped heading")
	check(preload("res://scripts/touch_input.gd").should_click(Vector2.ZERO, Vector2(6, 0), false, false), "6 logical pixel jitter remains a tap")
	for entry in [[Vector2i(844,390),1.0], [Vector2i(2868,1320),3.0]]:
		var physical: Vector2i = entry[0]
		var size := Vector2i(Vector2(physical) / float(entry[1]))
		Phone.test_touch = 1; Phone.test_scale = float(entry[1])
		DisplayServer.window_set_size(physical); root.size = physical; root.content_scale_size = size
		await process_frame
		var flow = root.get_node("CampaignFlow")
		flow.save_path = "user://camera20-%d.json" % OS.get_process_id()
		flow.campaign = Campaign.new(); flow.story = flow.campaign.story; flow.active = true
		var game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
		for i in 8: await process_frame
		game.demo_mode = true
		var phone = game.hud_controls.phone
		check(phone != null, "%s phone HUD" % size)
		if phone != null:
			var background: Control = phone.overlay.find_child("PhoneTopBackground", false, false)
			var header_px: float = background.get_global_rect().size.y * float(size.y) / game.camera.get_viewport().get_visible_rect().size.y
			check(absf(header_px - 44.0) < 0.2, "%s header is 44 logical px" % size)
			var buttons: Array[BaseButton] = []
			_buttons(phone.overlay, buttons)
			var measured := 0
			var smallest := Vector2(INF, INF)
			for button in buttons:
				var rect := _visible_rect(button)
				if not rect.has_area(): continue
				measured += 1
				smallest.x = minf(smallest.x, rect.size.x)
				smallest.y = minf(smallest.y, rect.size.y)
				check(rect.size.x >= 43.9 and rect.size.y >= 43.9, "%s %s visible hit area %s" % [size, button.name, rect])
				check(Rect2(Vector2.ZERO, size).encloses(button.get_global_rect()), "%s %s inside viewport" % [size, button.name])
			print("CAMERA20 HUD %s@%sx: %d controls, minimum visible %.1fx%.1f logical px" % [size, entry[1], measured, smallest.x, smallest.y])
			var original_y: Array[int] = []
			var squad: Array = game.mission.living("player")
			var objective_y := 0
			for enemy in game.mission.living("enemy"): objective_y += int(enemy.y)
			objective_y = roundi(float(objective_y) / float(game.mission.living("enemy").size()))
			for member in squad:
				original_y.append(int(member.y))
				member.y = 2 * objective_y - int(member.y)
			var old_heading: float = game.yaw
			game._face_battle_front()
			check(absf(wrapf(game.yaw - old_heading, -PI, PI)) >= PI / 2.0, "%s turn start follows squad around objective" % size)
			for i in squad.size(): squad[i].y = original_y[i]
			game._face_battle_front()
			var yaw_before: float = game.yaw
			(phone.overlay.find_child("CameraRotateRight", true, false) as Button).pressed.emit()
			await create_timer(0.35).timeout
			check(absf(wrapf(game.yaw-yaw_before, -PI, PI)-PI/2.0) < 0.02, "%s rotate button advances one step" % size)
			var actor: Dictionary = game.mission.unit_by_id(game.selected_id)
			var route: Dictionary = game.mission.reach_tiles(actor, 1)
			var destination := Vector2i(-1, -1)
			var screen := Vector2.ZERO
			for tile in route.costs:
				if int(route.costs[tile]) != 1: continue
				var at: Vector2 = game.camera.unproject_position(Vector3(tile.x, 0.5, tile.y))
				if at.x > 70 and at.x < size.x - 70 and at.y > 65 and at.y < size.y - 105:
					destination = tile; screen = at; break
			check(destination.x >= 0, "%s visible one-step destination" % size)
			if destination.x >= 0:
				for tap_index in 2:
					var down := InputEventScreenTouch.new(); down.index = 0; down.position = screen; down.pressed = true
					game.cam.touch.handle(down)
					var drag := InputEventScreenDrag.new(); drag.index = 0; drag.position = screen + Vector2(6, 0); drag.relative = Vector2(6, 0)
					game.cam.touch.handle(drag)
					var up := InputEventScreenTouch.new(); up.index = 0; up.position = drag.position; up.pressed = false
					game.cam.touch.handle(up)
					await process_frame
					check(game.preview_tile == destination or game.player_attack_pending or Vector2i(actor.x, actor.y) == destination, "%s jitter tap %d reaches movement" % [size, tap_index])
			await create_timer(0.55).timeout
			var zoom_before: float = game.zoom
			var finger_a := InputEventScreenTouch.new(); finger_a.index = 0; finger_a.position = Vector2(220, 120); finger_a.pressed = true
			var finger_b := InputEventScreenTouch.new(); finger_b.index = 1; finger_b.position = Vector2(320, 120); finger_b.pressed = true
			game.cam.touch.handle(finger_a); game.cam.touch.handle(finger_b)
			var spread := InputEventScreenDrag.new(); spread.index = 1; spread.position = Vector2(340, 120); spread.relative = Vector2(20, 0)
			game.cam.touch.handle(spread)
			check(absf(game.zoom - zoom_before) < 0.01, "%s pinch begins eased zoom" % size)
			await create_timer(0.16).timeout
			check(game.zoom < zoom_before - 0.1, "%s pinch zooms in" % size)
			finger_a.pressed = false; finger_b.pressed = false
			game.cam.touch.handle(finger_b); game.cam.touch.handle(finger_a)
		game.queue_free(); await process_frame
	Phone.test_touch = -1; Phone.test_scale = 0.0
	print("CAMERA20: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
