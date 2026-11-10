extends SceneTree
const Art = preload("res://scripts/map_presentation.gd")
const Mission = preload("res://scripts/mission.gd")
const Maps = preload("res://scripts/map_catalog.gd")
const Grid = preload("res://scripts/map_art_grid.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(label)

func count_meshes(node: Node) -> int:
	var total := 1 if node is MultiMeshInstance3D else 0
	for child in node.get_children(): total += count_meshes(child)
	return total

func run() -> void:
	for name in ["w23_albedo", "w23_roughness"]:
		var texture: Texture2D = load("res://assets/maps/w23_terrain/%s.webp" % name)
		check(texture != null and texture.get_size() == Vector2(512,512),name+": 512 atlas")
	var art = Art.new(); root.add_child(art)
	for entry in [{"name":"shrine","path":Maps.resolve("shrine")}, {"name":"grove","path":Maps.resolve("h_grove")}, {"name":"gate","path":"res://data/rescue.json"}]:
		var m = Mission.new(7,entry.path)
		art.build(m)
		var floors := 0; var imported := 0; var rounded := 0
		for tile in art.floor_bounds:
			var bounds: AABB = art.floor_bounds[tile]
			if absf(bounds.size.y) < 0.0001: floors += 1
		for record in art.batch.records:
			if record.role != "cover": continue
			if record.has("meshy_path"): imported += 1
			else: rounded += 1
		check(floors > 0,entry.name+": seamless plane tops")
		check(imported > 0 and rounded > 0,entry.name+": imported and rounded cover families")
		check(art.palette.floor.get_shader_parameter("atlas_albedo") != null,entry.name+": atlas bound")
		check(art.find_children("*","CollisionObject3D",true,false).is_empty(),entry.name+": no collision added")
		var instances := count_meshes(art)
		check(instances < 150,entry.name+": static art batched below 150 mesh instances")
		print("TERRAIN23 %s: floor planes=%d imported cover=%d procedural cover=%d batched instances=%d" % [entry.name,floors,imported,rounded,instances])
		await process_frame
	var source := Node3D.new(); root.add_child(source)
	var fixture = preload("res://scripts/w23_terrain_grid_fixture.gd").new(); root.add_child(fixture)
	fixture.mission = Mission.new(7,"res://data/rescue.json")
	fixture.selected_id = int(fixture.mission.living("player")[0].id)
	var grid := Grid.new(); root.add_child(grid); grid.bind(source,fixture)
	var border := art.box(Vector3(1,0.12,1),Vector3(0.08,0.05,0.86),art.material(Color("399ef2")),source)
	await process_frame; await process_frame
	check(not grid.visible,"idle overview has no grid")
	fixture.hovered = Vector2i(1,1); grid._process(0)
	check(grid.visible and grid.view.multimesh.visible_instance_count == 1,"Move squares remain lit")
	fixture.action = "free"; grid._process(0)
	check(not grid.visible,"inactive grid hidden")
	fixture.action = "shoot"; grid._process(0)
	check(grid.visible,"Aim grid visible")
	fixture.cinematic = true; grid._process(0)
	check(not grid.visible,"cinematic grid hidden")
	border.queue_free(); grid.queue_free(); fixture.queue_free(); source.queue_free(); art.queue_free()
	await process_frame
	print("TERRAIN23 TEST RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
