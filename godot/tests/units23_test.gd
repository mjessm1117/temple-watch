extends SceneTree
## Unit readability, far LOD and Low saber visibility contract.

const UnitView = preload("res://scripts/unit_view.gd")
const ROOT := "res://assets/units/w17/"
const KINDS := ["sniper", "heavy", "tech", "droid", "officer"]
var checks := 0
var failures := 0

class CueCounter extends Node:
	var calls := 0
	var muted := false
	var volume := 1.0
	func cue(_kind: String) -> void: calls += 1

class GameStub extends Node3D:
	var sound: Node
	var fx: Node3D
	var figures: Node3D
	var mission: RefCounted

func _initialize() -> void: run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func triangles(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D and node.mesh != null:
		for i in node.mesh.get_surface_count():
			if node.mesh.surface_get_primitive_type(i) == Mesh.PRIMITIVE_TRIANGLES:
				var arrays: Array = node.mesh.surface_get_arrays(i)
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				count += int((indices.size() if not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()) / 3)
	for child in node.get_children(): count += triangles(child)
	return count

func has_range(node: Node, begin: float, end: float) -> bool:
	if node is GeometryInstance3D and is_equal_approx(node.visibility_range_begin, begin) and is_equal_approx(node.visibility_range_end, end): return true
	for child in node.get_children():
		if has_range(child, begin, end): return true
	return false

func run() -> void:
	var game := GameStub.new()
	game.sound = CueCounter.new()
	game.figures = Node3D.new()
	root.add_child(game)
	game.add_child(game.sound)
	game.add_child(game.figures)
	for kind in KINDS:
		var near := (load(ROOT + kind + ".glb") as PackedScene).instantiate()
		var mid := (load(ROOT + kind + "_lod1.glb") as PackedScene).instantiate()
		var near_tris := triangles(near)
		var mid_tris := triangles(mid)
		near.free(); mid.free()
		var far_path: String = ROOT + kind + "_lod2.glb"
		var far_scene := load(far_path) as PackedScene
		check(far_scene != null, kind + " LOD2 loads")
		if far_scene == null: continue
		var far := far_scene.instantiate()
		var tri_count := triangles(far)
		check(tri_count > 0 and tri_count <= 800, kind + " LOD2 at most 800 triangles")
		var player := far.find_child("AnimationPlayer", true, false) as AnimationPlayer
		check(player != null and player.has_animation("run") and player.has_animation("shoot"), kind + " LOD2 has motion clips")
		print("UNITS23_TRIS ", kind, " lod0=", near_tris, " lod1=", mid_tris, " lod2=", tri_count)
		far.free()
		var view := UnitView.new()
		game.figures.add_child(view)
		view.setup({"id": 10, "side": "enemy", "class_name": kind, "model": kind}, load(ROOT + kind + ".glb"), Vector3.ZERO)
		check(view.lod2_animation != null, kind + " far animation wired")
		check(view.lod_animation != null, kind + " mid animation wired")
		check(view.lod2_animation.speed_scale == view.animation.speed_scale, kind + " LOD motion speed matches")
		check(has_range(view.model, 26.0, 42.0), kind + " mid range blends at 26 and 42 m")
		check(has_range(view.model, 42.0, 0.0), kind + " far range starts at 42 m")
		view.free()
	var jedi := UnitView.new()
	game.figures.add_child(jedi)
	jedi.setup({"id": 1, "side": "player", "class_name": "Guardian", "model": "jedi"}, load("res://assets/models/units/jedi.glb"), Vector3.ZERO)
	await process_frame
	check(jedi.saber_blade.global_position.distance_to(jedi.global_position) < 3.0, "saber stays attached at actor scale")
	check(jedi.saber_halo == jedi.saber_blade and jedi.saber_blade.visible, "saber core and Low halo share one draw")
	print("UNITS23_HALO faces=", jedi.saber_halo.mesh.get_faces().size())
	check(jedi.saber_halo.mesh.get_faces().size() <= 1200, "saber core and halo stay low poly")
	jedi.set_saber_halo(false)
	check(is_zero_approx((jedi.saber_blade.material_override as ShaderMaterial).get_shader_parameter("halo_alpha")) and jedi.saber_blade.visible, "tier toggle hides halo but retains core")
	jedi.set_saber_halo(true)
	check((jedi.saber_blade.material_override as ShaderMaterial).get_shader_parameter("halo_alpha") > 0.0, "halo can be restored")
	jedi.fall()
	check(not jedi.saber_blade.visible and not jedi.saber_active, "death hides blade and halo")
	check(game.sound.calls == 0, "fall does not replay kill cue")
	print("units23: %d checks, %d failures; draw_calls=%d tris_frame=%d" % [checks, failures, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	quit(1 if failures else 0)
