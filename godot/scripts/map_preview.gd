extends SceneTree
## Real battle/HUD inspection: -s scripts/map_preview.gd -- sabotage --capture --fps
## --all captures all biomes plus a real action-camera frame. No save is loaded/written.
const Mission = preload("res://scripts/mission.gd")
const Combat = preload("res://scripts/combat_mission.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Shot = preload("res://scripts/shot.gd")
const Settings = preload("res://scripts/settings.gd")
var game
var failures := 0

func _initialize() -> void: run.call_deferred()

func run() -> void:
	Settings.difficulty = "normal"
	root.borderless = true; root.unresizable = true
	root.size = Vector2i(1920,1080); root.position = Vector2i(0,50)
	root.content_scale_size = Vector2i(1920,1080)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var args := OS.get_cmdline_user_args()
	var ids: Array = ["sabotage","envoy","h_grove","ilum","fixture","archive","relay","h_husks"] if "--all" in args else [args[0] if not args.is_empty() else "sabotage"]
	for id in ids:
		await show_battle(str(id))
		await create_timer(2.0).timeout
		if "--fps" in args: await fps_sample(str(id))
		if "--capture" in args or "--all" in args:
			await capture(str(game.mission.spec.get("theme","temple")))
		if "--action" in args and id == "fixture": await action_shot()
		if ("--all" in args and id == "relay") or "--highground" in args: await highground_shot()
		if ids.size() > 1:
			game.queue_free(); await process_frame
	if "--capture" in args or "--all" in args or "--benchmark" in args:
		quit(1 if failures else 0)

func show_battle(id: String) -> void:
	var source = Mission.new(17) if id == "fixture" else Mission.new(17,"res://data/maps/%s.json" % id if id.begins_with("web_") else Maps.resolve(id))
	if "--authored" in OS.get_cmdline_user_args() and source.spec.has("elevation"):
		preload("res://scripts/map_art_elevation.gd").apply(source.board,source.spec.elevation)
	game = load("res://scenes/rescue.tscn").instantiate(); root.add_child(game)
	game.mission = Combat.adopt(source)
	for view in game.figures.get_children():
		if view.name != "Prisoner": game.figures.remove_child(view); view.queue_free()
	game.views.clear(); game.selected_id = int(game.mission.living("player")[0].id)
	game.hud.queue_free(); game.portrait_viewport.queue_free(); game.portrait_kind = ""; game.action_buttons.clear(); game._build_ui()
	game._build_terrain(); game.terrain_seen_board = game.mission.board.duplicate(); game.terrain_seen_revision = game.mission.terrain_revision
	if game.mission.modern:
		game.pivot = Vector3(float(game.mission.spec.width)*0.5,0,float(game.mission.spec.height)*0.5)
		game.zoom = maxf(float(game.mission.spec.width),float(game.mission.spec.height))*1.3
	else:
		game.pivot = Vector3(9,0,17); game.zoom = 23.0
	game.pitch = 0.8; game.yaw = 0.3; game.action_camera = true
	game._update_camera(); game._refresh(); game.scene_view.arrange_labels()
	Input.warp_mouse(Vector2(960,60))
	await process_frame
	print("ART WINDOW: ",DisplayServer.window_get_size()," viewport ",root.get_visible_rect().size)

func capture(theme: String) -> void:
	game.scene_view.arrange_labels()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../docs/godot/shots/wave9-%s.png" % theme)
	var picture := root.get_texture().get_image()
	if picture.get_size() != Vector2i(1920,1080): failures += 1; push_error("Capture must be 1920x1080")
	var error := picture.save_png(path)
	if error != OK: failures += 1
	print("ART CAPTURE: %s (%s)" % [path,error_string(error)])

func action_shot() -> void:
	# The real camera owner frames two existing units, at their unchanged rule positions.
	var actor: Dictionary = game.mission.living("player")[2]
	var target: Dictionary = game.mission.living("enemy")[0]
	var from := Vector3(actor.x,Shot.elevation(game.mission,Shot.pos(actor))*0.7,actor.y)
	var to := Vector3(target.x,Shot.elevation(game.mission,Shot.pos(target))*0.7,target.y)
	await game.cam.frame(from,to,"shoot")
	await create_timer(0.5).timeout
	await capture("action-cam")
	game.cam.finish()

func fps_sample(id: String) -> void:
	# Allow imported character pipelines and shadow caches to finish warming.
	await create_timer(8.0).timeout
	var times: Array[float] = []; var previous := Time.get_ticks_usec()
	var cpu_start := cpu_ticks(); var cpu_prev := cpu_start; var cpu_peak := 0.0
	for i in 1200:
		await process_frame
		var now := Time.get_ticks_usec(); times.append(float(now-previous)/1000.0); previous = now
		if i%60 == 59:
			var cpu_now := cpu_ticks(); cpu_peak = maxf(cpu_peak,cpu_busy(cpu_prev,cpu_now)); cpu_prev = cpu_now
	var sum := 0.0
	for ms in times: sum += ms
	times.sort()
	var mean := 1000.0/(sum/times.size()); var p95 := times[int(times.size()*0.95)]; var p99 := times[int(times.size()*0.99)]
	print("BATTLE FPS: %s (%dx%d), %s, 1920x1080 Forward+, 1200 frames: mean %.1f, p95 %.2f ms, p99 %.2f ms; draw calls %d" % [id,game.mission.spec.width,game.mission.spec.height,RenderingServer.get_video_adapter_name(),mean,p95,p99,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	print("BATTLE LOAD: mean CPU %.1f%%, peak interval %.1f%%; loadavg %s; affinity %s" % [cpu_busy(cpu_start,cpu_ticks()),cpu_peak,proc_line("/proc/loadavg"),affinity()])
	if mean < 60 or p95 > 16.667: failures += 1; push_error("Battle did not sustain 60 fps")

func highground_shot() -> void:
	# Find a legal one-action move and downhill shot; no actor teleport, AP grant or forced hit.
	var m = game.mission
	for actor in m.living("player"):
		if str(actor.class_name) != "Soldier": continue
		var reach: Dictionary = m.paths(actor,int(actor.mob))
		for tile: Vector2i in reach.costs:
			if Shot.elevation(m,tile) <= 0 or m.occupied(tile,int(actor.id)): continue
			for target in m.living("enemy"):
				if Shot.elevation(m,Shot.pos(target)) >= Shot.elevation(m,tile): continue
				var probe: Dictionary = actor.duplicate(); probe.x = tile.x; probe.y = tile.y
				var info: Dictionary = Shot.calculate(m,probe,target)
				if not info.los or not info.range_ok: continue
				if not m.move(int(actor.id),tile): continue
				game.selected_id = int(actor.id); game._refresh()
				var view = game.views[int(actor.id)]
				while view.motion != null and view.motion.is_running(): await process_frame
				m.action_events.clear()
				m.defer_resolution = false
				if not m.shot(int(actor.id),int(target.id)): continue
				game.target_id = int(target.id); game._refresh()
				var event: Dictionary = {}
				for candidate in m.action_events:
					if candidate.kind == "attack" and int(candidate.actor) == int(actor.id): event = candidate
				if event.is_empty(): continue
				var from := Vector3(tile.x,Shot.elevation(m,tile)*0.7,tile.y)
				var to := Vector3(target.x,Shot.elevation(m,Shot.pos(target))*0.7,target.y)
				await game.cam.frame(from,to,"shoot")
				var direction := (to-from).normalized(); var side := Vector3(-direction.z,0,direction.x)
				game.camera.position = from-direction*4.0+side*5.0+Vector3.UP*4.2
				game.camera.look_at(from.lerp(to,0.4)+Vector3.UP*0.65)
				preload("res://scripts/enemy_presentation.gd").impact(game,event)
				await create_timer(0.08).timeout
				await capture("highground")
				print("HIGHGROUND: legal move to %s; shot %s -> %s; tiers %d -> %d; hit modifier %s" % [tile,actor.name,target.name,Shot.elevation(m,tile),Shot.elevation(m,Shot.pos(target)),info.get("lines",[])])
				await create_timer(0.6).timeout
				game.cam.finish(); return
	failures += 1; push_error("No legal high-ground soldier shot found")

func proc_line(path: String) -> String:
	var f := FileAccess.open(path,FileAccess.READ)
	return f.get_line() if f else "unavailable"

func cpu_ticks() -> Array[int]:
	var fields := proc_line("/proc/stat").split(" ",false)
	if fields.size()<9: return [0,0]
	var total := 0
	for i in range(1,9): total += int(fields[i])
	return [total,int(fields[4])+int(fields[5])]

func cpu_busy(before: Array[int], after: Array[int]) -> float:
	return 100.0*(1.0-(after[1]-before[1])/maxf(1,after[0]-before[0]))

func affinity() -> String:
	var f := FileAccess.open("/proc/self/status",FileAccess.READ)
	if not f: return "unavailable"
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("Cpus_allowed_list:"): return line.get_slice(":",1).strip_edges()
	return "unavailable"
