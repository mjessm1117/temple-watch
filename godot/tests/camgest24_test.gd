extends SceneTree
const Touch = preload("res://scripts/touch_input.gd")
const CameraRules = preload("res://scripts/battle11_camera.gd")
const Mission = preload("res://scripts/mission.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const Batch = preload("res://scripts/map_art_batch.gd")
var checks := 0
var failures := 0
const PROOF := "/home/jess/projects/tw-logs/w24/camgest/captures/"

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMGEST24 " + label)

func touch(t, index: int, point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index; event.position = point; event.pressed = down
	t.handle(event)

func drag(t, index: int, point: Vector2, previous: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index; event.position = point; event.relative = point - previous
	t.handle(event)

func find_control(node: Node, wanted: String) -> Control:
	if node is Control and node.name == wanted: return node
	for child in node.get_children():
		var result := find_control(child, wanted)
		if result != null: return result
	return null

func capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await process_frame
	check(root.get_texture().get_image().save_png(PROOF + name + ".png") == OK, name + " screenshot saved")

func run() -> void:
	# All shipped biome families: the eye must sit behind the squad and look at
	# the first objective/enemy approach, including the gate hold mission.
	for entry in [["relay","temple"],["shrine","plains"],["rescue","dock"],["ilum","snow"],["h_grove","jungle"],["h_valo","city"],["archive","ruins"],["h_husks","caves"]]:
		var m = Mission.new(17, "res://data/maps/%s.json" % entry[0])
		check(str(m.spec.theme) == entry[1], "%s family" % entry[0])
		var squad := Vector2.ZERO
		for u in m.living("player"): squad += Vector2(float(u.x), float(u.y))
		squad /= maxf(1.0, float(m.living("player").size()))
		var target := Vector2.ZERO
		var count := 0
		for p in m.spec.objective.get("points", []): target += Vector2(float(p[0]), float(p[1])); count += 1
		if count == 0 and bool(m.prisoner.get("active", false)):
			target += Vector2(float(m.prisoner.x), float(m.prisoner.y)); count += 1
		for enemy in m.living("enemy"): target += Vector2(float(enemy.x), float(enemy.y)); count += 1
		if count > 0:
			target /= float(count)
			var heading: float = CameraRules.battle_heading(m)
			var forward := -Vector2(sin(heading), cos(heading))
			check(forward.dot((target - squad).normalized()) > 0.7, "%s heading faces approach" % entry[0])
	check(Touch.rotate_delta24(0.0, 0.4) <= 0.25, "twist event bounded; no quarter turn")
	check(CameraRules.clamp_zoom(2.0) == 9.0 and CameraRules.clamp_zoom(90.0) == 65.0, "pinch range 9 to 65")
	var batch := Batch.new()
	var shared := StandardMaterial3D.new()
	batch.put("box",shared,Vector3.ZERO,Vector3.ONE)
	batch.put("cylinder",shared,Vector3(2,0,0),Vector3.ONE)
	var static_root := Node3D.new(); root.add_child(static_root)
	batch.flush(static_root)
	check(static_root.get_child_count() == 1 and static_root.get_child(0) is MeshInstance3D, "B5 shared material static shapes flush as one draw surface")
	static_root.queue_free()
	var shell := FileAccess.get_file_as_string("res://web/shell.html")
	check(shell.contains("touch-action: none") and shell.contains("overscroll-behavior: none") and shell.contains("touchmove") and shell.contains("preventDefault"), "web shell blocks page rubber band paths")
	root.size = Vector2i(390,844); root.content_scale_size = root.size
	preload("res://scripts/phone_layout.gd").test_touch = 1
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://camgest24-%d.json" % OS.get_process_id()
	flow.campaign = Campaign.new("normal"); flow.campaign.select_mission(0)
	flow.campaign.state.flow_stage = "battle"; flow.story = flow.campaign.story; flow.active = true
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 10: await process_frame
	game.demo_mode = true
	var t = game.cam.touch
	var cfg := ConfigFile.new()
	cfg.set_value("controls","cam_sensitivity",1.5)
	cfg.set_value("controls","invert_rotate",true)
	check(cfg.save("user://controls24.cfg") == OK, "controls config saved")
	t._settings()
	check(is_equal_approx(t.cam_sensitivity,1.5) and t.invert_rotate, "sensitivity and invert rotation loaded")
	var unit: Dictionary = game.mission.living("player")[0]
	game._select(int(unit.id))
	await create_timer(0.5).timeout
	game.pivot = Vector3(float(unit.x),0,float(unit.y))
	game._update_camera()
	var unit_at: Vector2 = game.camera.unproject_position(Vector3(float(unit.x), 0.8, float(unit.y)))
	check(Rect2(Vector2.ZERO,Vector2(root.size)).has_point(unit_at), "unit drag begins on visible unit")
	var tile_at := Vector2.ZERO
	for y in range(230,630,40):
		for x in range(60,350,40):
			var candidate := Vector2(x,y)
			if t._control_at(game.overlay,candidate) == null and game._screen_tile(candidate).x >= 0:
				tile_at = candidate
				break
		if tile_at != Vector2.ZERO: break
	check(tile_at != Vector2.ZERO, "visible board tile found")
	for entry in [["tile",tile_at],["unit",unit_at]]:
		var point: Vector2 = entry[1]
		if entry[0] == "unit": point = game.camera.unproject_position(Vector3(float(unit.x), 0.8, float(unit.y)))
		var before: Vector3 = game.pivot
		touch(t,0,point,true)
		var drag_start := Time.get_ticks_msec()
		drag(t,0,point + Vector2(36,0),point)
		var latency_ms := Time.get_ticks_msec() - drag_start
		check(latency_ms <= 100, "%s drag updates pivot within 100 ms (%d ms)" % [entry[0], latency_ms])
		print("CAMGEST24 LATENCY ", entry[0], "=", latency_ms, "ms")
		if entry[0] == "unit": await capture("drag-frame1")
		touch(t,0,point + Vector2(36,0),false)
		check(game.pivot.distance_to(before) > 0.05, "%s finger drag pans board" % entry[0])
		var released: Vector3 = game.pivot
		for i in 20: await process_frame
		var drift: float = game.pivot.distance_to(released)
		print("CAMGEST24 DRIFT ", entry[0], "=", drift)
		check(drift < 0.05, "%s release pivot drift under 0.05" % entry[0])
		if entry[0] == "unit": await capture("drag-after")
	for name in ["PhoneEndTurn","AbilityTray","UnitCard"]:
		var control := find_control(game.overlay,name)
		check(control != null and control.is_visible_in_tree(), name + " exists")
		if control == null: continue
		var point := control.get_global_rect().get_center()
		var before: Vector3 = game.pivot
		touch(t,0,point,true)
		drag(t,0,point + Vector2(40,0),point)
		touch(t,0,point + Vector2(40,0),false)
		check(game.pivot.distance_to(before) < 0.001, name + " start blocks pan through release")
	# A fresh select glide must yield to the manual drag at 18 logical pixels.
	game._glide_to(game.pivot + Vector3(3,0,0), 0.6)
	var start: Vector2 = game.camera.unproject_position(Vector3(float(unit.x), 0.8, float(unit.y)))
	touch(t,0,start,true)
	drag(t,0,start + Vector2(36,0),start)
	touch(t,0,start + Vector2(36,0),false)
	var released: Vector3 = game.pivot
	for i in 20: await process_frame
	var glide_drift: float = game.pivot.distance_to(released)
	print("CAMGEST24 DRIFT glide=", glide_drift)
	check(glide_drift < 0.05, "manual pivot survives select glide")
	# Two fingers rotate continuously after the first 0.1 radians, and keep
	# their chosen mode even when the fingers later spread.
	var a := Vector2(130,300); var b := Vector2(230,300)
	touch(t,0,a,true); touch(t,1,b,true)
	var yaw_before: float = game.yaw
	drag(t,1,b + Vector2(0,20),b)
	check(t.gesture == "rotate", "first 0.1 radians locks rotate")
	check(game.yaw < yaw_before - 0.01 and game.yaw > yaw_before - 0.26, "inverted rotation continuous and bounded")
	drag(t,1,b + Vector2(20,20),b + Vector2(0,20))
	check(t.gesture == "rotate", "rotate remains locked on later spread")
	await capture("rotate-after")
	touch(t,1,b + Vector2(20,20),false); touch(t,0,a,false)
	touch(t,0,a,true); touch(t,1,b,true)
	drag(t,1,b + Vector2(25,0),b)
	check(t.gesture == "pinch", "first 12 pixels locks pinch")
	await create_timer(0.2).timeout
	check(game.zoom < 65.0 and game.zoom >= 9.0, "pinch stays inside zoom range")
	touch(t,1,b + Vector2(25,0),false); touch(t,0,a,false)
	touch(t,0,a,true); touch(t,1,b,true)
	drag(t,0,a + Vector2(10,0),a)
	drag(t,1,b + Vector2(10,0),b)
	drag(t,0,a + Vector2(20,0),a + Vector2(10,0))
	check(t.gesture == "pan", "first 12 pixel centroid motion locks pan")
	touch(t,1,b + Vector2(10,0),false); touch(t,0,a + Vector2(20,0),false)
	game.queue_free(); await process_frame
	print("CAMGEST24: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
