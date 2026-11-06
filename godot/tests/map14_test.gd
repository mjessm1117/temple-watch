extends SceneTree
## Identical camera/map fixtures for Wave 14 before/after captures and Low counters.
const Mission = preload("res://scripts/mission.gd")
const Art = preload("res://scripts/map_presentation.gd")
const Shot = preload("res://scripts/shot.gd")
const PATHS := {
	"temple":"res://data/rescue.json", "dock":"res://data/maps/dock.json",
	"city":"res://data/maps/envoy.json", "ruins":"res://data/maps/cache.json",
	"snow":"res://data/maps/ilum.json", "jungle":"res://data/maps/h_grove.json",
	"plains":"res://data/maps/relay.json", "caves":"res://data/maps/w11_holocron.json"
}
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(why)

func run() -> void:
	if "--battle" in OS.get_cmdline_user_args():
		await battle_capture()
		return
	var before := "--before" in OS.get_cmdline_user_args()
	var capture := "--capture" in OS.get_cmdline_user_args()
	var phase := "before" if before else "after"
	var low := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--theme="): only = arg.trim_prefix("--theme=")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for theme in PATHS:
		if only != "" and theme != only: continue
		for size in [Vector2i(844,390),Vector2i(1366,768)]:
			var view := SubViewport.new(); view.size = size
			view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			view.own_world_3d = true; root.add_child(view)
			var m = Mission.new(17,PATHS[theme])
			var art = Art.new(); view.add_child(art); art.build(m)
			if theme == "plains" and not m.living("player").is_empty():
				var guard: Dictionary = m.living("player")[0]
				guard.overwatch = true; guard.range = 8.0
				check(art.overwatch_zones(m).size() == 1, "overwatch uses one arc per guard")
				art.refresh_markers(m)
				check(art.marker_root.get_children().any(func(node): return node is MeshInstance3D and node.mesh is ImmediateMesh and node.mesh.get_surface_count() == 2), "overwatch arc has fill and edge")
			var world := WorldEnvironment.new(); view.add_child(world)
			var sun := DirectionalLight3D.new(); view.add_child(sun)
			art.apply_environment(world,sun,theme)
			var camera := Camera3D.new(); view.add_child(camera)
			camera.fov = 45.0; camera.current = true
			var center := Vector3(float(m.spec.width-1)*0.5,0,float(m.spec.height-1)*0.5)
			camera.position = center+Vector3(7,19,22)
			camera.look_at(center)
			var graphics: Node = root.get_node("Graphics")
			graphics.apply_all()
			for i in 20: await process_frame
			var draws := 0; var tris := 0
			for i in 24:
				await process_frame
				draws = maxi(draws,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
				tris = maxi(tris,int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
			print("MAP14 PERF %s %s %s: draws=%d triangles=%d" % [phase,theme,size,draws,tris])
			if not before:
				check(view.size == size, "%s: viewport size %s expected %s" % [theme,view.size,size])
				check(art.theme == theme and art.floor_bounds.size() == int(m.spec.width)*int(m.spec.height), "%s: map complete" % theme)
				check(art.find_children("*","CollisionObject3D",true,false).is_empty(), "%s: no detail collision" % theme)
				check(world.environment.fog_enabled == not low and world.environment.glow_enabled == not low, "%s: Low effects" % theme)
				check(sun.shadow_enabled == not low, "%s: Low shadows" % theme)
				check(art.get_node_or_null("Map14SurfaceMarks") is MeshInstance3D, "%s: vertex marks" % theme)
				check(art.palette.floor.get_shader_parameter("map_seed") == float(posmod(hash(m.spec),10000)), "%s: per-map surface seed" % theme)
				check(art.batch.records.any(func(record): return record.kind == "map14 clutter"), "%s: clutter" % theme)
				for record in art.batch.records:
					if record.kind == "map14 clutter": check(preload("res://scripts/map14_detail.gd").safe(m,record.tile), "%s: clutter safe tile" % theme)
				for shape in ["box","rock","cone","boulder"]:
					var mesh: Mesh = art.batch.shapes[shape]
					var triangles := 0
					for surface in mesh.get_surface_count():
						var arrays: Array = mesh.surface_get_arrays(surface)
						var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
						var index_count := 0
						if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: index_count = arrays[Mesh.ARRAY_INDEX].size()
						triangles += (index_count if index_count > 0 else vertices.size())/3
					check(triangles > 0 and triangles <= 800,"%s: %s clutter <=800 triangles" % [theme,shape])
				check(art.get_node_or_null("Map14Accent") == null if low else art.get_node_or_null("Map14Accent") is OmniLight3D, "%s: tier light" % theme)
				check(art.get_node_or_null("Map14WearDecal") == null if low else art.get_node_or_null("Map14WearDecal") is Decal, "%s: tier decal" % theme)
				check(not camera.is_position_behind(center), "%s: map center in front" % theme)
				var projected := camera.unproject_position(center)
				check(projected.x >= 0 and projected.x < size.x and projected.y >= 0 and projected.y < size.y, "%s: map center in viewport" % theme)
			if capture and DisplayServer.get_name() != "headless":
				var image := view.get_texture().get_image()
				check(image.get_size() == size,"%s: image size %s expected %s" % [theme,image.get_size(),size])
				var path := "res://../docs/godot/shots/wave14-map-%s-%s-%s.png" % [phase,theme,"phone" if size.x == 844 else "desktop"]
				check(image.save_png(path) == OK,"%s: screenshot" % theme)
			view.queue_free()
			for i in 3: await process_frame
	if not before and only == "":
		for size in [Vector2i(844,390),Vector2i(1366,768)]:
			root.size = size; root.content_scale_size = size
			var source := Node3D.new(); root.add_child(source)
			var grid := preload("res://scripts/map_art_grid.gd").new(); root.add_child(grid); grid.bind(source)
			grid.focus = Vector2i(1,1)
			for x in [1,10]:
				var border := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = Vector3(0.1,0.05,0.8)
				border.mesh = mesh; border.position = Vector3(x,0.12,1)
				var mat := StandardMaterial3D.new(); mat.albedo_color = Color("71ed9a"); border.material_override = mat
				source.add_child(border)
			await process_frame; await process_frame
			check(root.size == size, "grid viewport %s" % size)
			check(grid.view.multimesh.visible_instance_count == 2,"grid source fits %s" % size)
			var near: float = grid.focus_alpha(Vector3(1,0,1),grid.focus)
			var far: float = grid.focus_alpha(Vector3(10,0,1),grid.focus)
			check(near > far and far >= 0.6,"grid keeps distant move tiles visible %s" % size)
			grid.queue_free(); source.queue_free(); await process_frame
	print("map14: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func battle_capture() -> void:
	var size := root.size
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	for i in 16: await process_frame
	root.get_node("Graphics").apply_all()
	await create_timer(1.2).timeout
	var selected: Dictionary = game.mission.unit_by_id(game.selected_id)
	game.pivot = Vector3(int(selected.x),0,int(selected.y))
	game.zoom = 25.0
	game._update_camera()
	for i in 12: await process_frame
	check(game.range_highlights.get_child_count() > 0,"battle range exists")
	var grid = game.highlights.get_child(1)
	check(grid.view.multimesh.visible_instance_count > 0,"battle range batched")
	check(grid.focus.x > -900,"battle grid tracks selected unit")
	for control in [game.title_label,game.selected_label,game.objective_label]:
		var rect: Rect2 = control.get_global_rect()
		check(rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= size.x+1 and rect.end.y <= size.y+1,"battle header fits %s" % size)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		var image := root.get_texture().get_image()
		check(image.get_size() == size,"battle image %s" % size)
		var path := "res://../docs/godot/shots/wave14-map-after-grid-%s.png" % ("phone" if size.x == 844 else "desktop")
		check(image.save_png(path) == OK,"battle grid shot")
	game.sound.player.stop(); game.sound.player.stream = null
	game.queue_free(); await process_frame
	print("map14 battle: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
