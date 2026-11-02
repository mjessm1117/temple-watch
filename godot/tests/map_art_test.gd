extends SceneTree
const Mission = preload("res://scripts/mission.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Shot = preload("res://scripts/shot.gd")
const Art = preload("res://scripts/map_presentation.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1; push_error(message)

func state(m: RefCounted) -> PackedByteArray:
	return var_to_bytes([m.spec,m.board,m.cover_hp,m.terrain_revision,m.units,m.prisoner,m.objective_state,m.pressure_state,m.rng.state])

func rules(m: RefCounted) -> Array:
	var result: Array = []
	for y in int(m.spec.height):
		for x in int(m.spec.width):
			var p := Vector2i(x,y)
			result.append([m.passable(p),Shot.elevation(m,p)])
			for dir in Shot.DIRS:
				var target := p+dir*4
				if m.in_bounds(target): result.append([Shot.cover(m,p,target),Shot.los(m,p,target)])
	return result

func validate(art, m: RefCounted, id: String) -> void:
	check(art.floor_bounds.size() == int(m.spec.width)*int(m.spec.height),id+": every tile rendered")
	for tile in art.floor_bounds:
		var bounds: AABB = art.floor_bounds[tile]
		check(absf(bounds.end.y-Shot.elevation(m,tile)*0.7) < 0.0001,id+": exact raised floor %s" % tile)
	for record in art.batch.records:
		if record.role == "scenery":
			for bounds: AABB in record.parts:
				var outside := bounds.end.x <= -0.5 or bounds.position.x >= float(m.spec.width)-0.5 or bounds.end.z <= -0.5 or bounds.position.z >= float(m.spec.height)-0.5
				check(outside,id+": scenery outside board "+str(record.kind))
			continue
		var tile: Vector2i = record.tile; var a: AABB = record.bounds
		check(m.in_bounds(tile),id+": prop tile in bounds")
		check(a.position.x >= tile.x-0.5001 and a.end.x <= tile.x+0.5001 and a.position.z >= tile.y-0.5001 and a.end.z <= tile.y+0.5001,id+": prop fits tile %s %s" % [tile,record.kind])
		check(absf(a.position.y-float(record.floor)) < 0.001,id+": grounded prop %s %s y=%f" % [tile,record.kind,a.position.y])
		if record.role == "cover":
			if record.kind == "#": check(a.size.y >= 1.8,id+": full cover tall")
			if record.kind in ["c","h","k"]: check(a.size.y < 0.9 and a.size.y >= 0.7,id+": half cover low")
	check(art.find_children("*","OmniLight3D",true,false).size() <= 4,id+": at most four local lights")
	for tile in art.access_tiles:
		for lower: Vector2i in art.access_tiles[tile]:
			check(m.passable(lower) and Shot.elevation(m,lower)<Shot.elevation(m,tile),id+": valid rendered stair landing")
	check(art.find_children("*","CollisionObject3D",true,false).is_empty(),id+": art adds no collision")

func run() -> void:
	if "--fps" in OS.get_cmdline_user_args():
		var largest := ""; var area := 0
		for entry in Maps.manifest().missions.values():
			var data := Maps.read(entry.path)
			var size := int(data.plot.width)*int(data.plot.height)
			if size > area: largest = entry.path; area = size
		var renderer = Art.new(); root.add_child(renderer)
		await sample_fps(renderer,largest)
		renderer.queue_free(); await process_frame
		quit(1 if failures else 0); return
	var art = Art.new(); root.add_child(art)
	var paths: Array = []
	for entry in Maps.manifest().missions.values(): paths.append(entry.path)
	paths.append_array(Maps.manifest().web_variants)
	paths.append("res://data/rescue.json")
	var largest := ""; var largest_area := 0; var themes: Dictionary = {}
	for path in paths:
		var m = Mission.new(17,str(path)); var before := state(m); var geometry := rules(m)
		art.build(m); art.refresh_markers(m); art.refresh_damage()
		check(before == state(m),str(path)+": map/mission/RNG data identical after art")
		check(geometry == rules(m),str(path)+": walkable/cover/LOS identical after art")
		validate(art,m,str(path)); themes[art.theme] = true
		var area := int(m.spec.width)*int(m.spec.height)
		if area > largest_area: largest = str(path); largest_area = area
		await process_frame
	check(themes.size() == 8,"all eight themes exercised including temple rescue fixture")
	# An independently transformed, off-centre GLB must fit for every cardinal orientation.
	for kind in ["crate","wall_metal","pillar","relay","terminal","console","rubble","barrel"]:
		for angle in [0.0,PI/2,PI,PI*1.5,0.37]:
			var actual: AABB = art.batch.model("res://assets/maps/%s.glb" % kind,Vector3(2,1.4,3),0.85,0.8,angle)
			check(actual.size.x <= 0.851 and actual.size.z <= 0.851 and absf(actual.position.y-1.4) < 0.001,"imported bounds: %s @ %f" % [kind,angle])
	art.batch.buckets.clear()
	var source := Node3D.new(); root.add_child(source)
	var grid := preload("res://scripts/map_art_grid.gd").new(); root.add_child(grid); grid.bind(source)
	var border := art.box(Vector3(1,0.12,1),Vector3(0.08,0.05,0.86),art.material(Color("399ef2")),source)
	await process_frame; await process_frame
	check(source.get_child_count() == 1 and not source.visible,"range art preserves rule-owned HUD nodes")
	check(grid.view.multimesh.visible_instance_count == 1 and grid.view.material_override.albedo_color.a < 0.4,"range grid batched and faint")
	source.remove_child(border); border.queue_free(); await process_frame; await process_frame
	check(grid.view.multimesh.visible_instance_count == 0,"range art follows cleared HUD nodes")
	grid.queue_free(); source.queue_free(); await process_frame
	var damage = Mission.new(17,Maps.resolve("sabotage"))
	var tile := Vector2i(7,7)
	# Controlled fixture edits happen before the renderer, never inside it.
	damage.set_tile(tile,"#"); art.build(damage)
	damage.damage_cover(tile,1); art.refresh_damage()
	check(art.damage_root.get_child_count() > 0,"nonbreaking damage visible without terrain revision")
	damage.damage_cover(tile,3); art.build(damage)
	check(damage.tile(tile) == "c","full cover cracks to half in existing rules")
	validate(art,damage,"damaged")
	damage.damage_cover(tile,4); art.build(damage)
	check(damage.tile(tile) == "r","broken cover renders rubble")
	validate(art,damage,"broken")
	print("MAP ART: %d maps; largest %s (%d tiles)" % [paths.size(),largest,largest_area])
	if DisplayServer.get_name() == "headless":
		print("MAP ART FPS: skipped: headless has no GPU frames; run tests/map_art_test.gd -- --fps in a real window")
	else:
		await sample_fps(art,largest)
	art.queue_free(); await process_frame
	print("MAP ART TEST RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func sample_fps(art, path: String) -> void:
	root.borderless = true; root.unresizable = true; root.size = Vector2i(1920,1080); root.content_scale_size = Vector2i(1920,1080); DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var m = Mission.new(17,path); art.build(m)
	var world := WorldEnvironment.new(); root.add_child(world)
	var sun := DirectionalLight3D.new(); root.add_child(sun); art.apply_environment(world,sun,art.theme)
	var camera := Camera3D.new(); root.add_child(camera)
	var center := Vector3(float(m.spec.width)*0.5,0,float(m.spec.height)*0.5)
	camera.position = center+Vector3(7,28,30); camera.look_at(center); camera.current = true
	await create_timer(3.0).timeout
	var times: Array[float] = []; var previous := Time.get_ticks_usec()
	for i in 600:
		await process_frame
		var now := Time.get_ticks_usec(); times.append(float(now-previous)/1000.0); previous = now
	var sum := 0.0
	for ms in times: sum += ms
	times.sort(); var mean := 1000.0/(sum/times.size()); var p95 := times[int(times.size()*0.95)]
	print("MAP ART FPS: %s, 1920x1080, %s, 600 frames, mean %.1f fps, p95 %.2f ms, p99 %.2f ms" % [path,RenderingServer.get_video_adapter_name(),mean,p95,times[int(times.size()*0.99)]])
	check(mean >= 60 and p95 <= 16.667,"largest map sustained 60 fps (mean and p95)")
