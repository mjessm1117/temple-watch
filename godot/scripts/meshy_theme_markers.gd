extends Node3D
## Preserve rule-owned detection borders exactly, but draw their boxes in one batch.
var source: Node3D
var game: Node
var dirty := true
# CPU-side submission records also work with the headless dummy RenderingServer.
var submitted: Array[Dictionary] = []
var view := MultiMeshInstance3D.new()

func _ready() -> void:
	add_child(view); view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tree_exiting.connect(unbind)

func unbind() -> void:
	if not is_instance_valid(source): return
	source.visible = true
	source.child_entered_tree.disconnect(changed); source.child_exiting_tree.disconnect(changed)
	source = null

func bind(node: Node3D) -> void:
	if node == source: return
	unbind(); source = node; dirty = true
	source.visible = false
	source.child_entered_tree.connect(changed); source.child_exiting_tree.connect(changed)

func changed(_node: Node) -> void: dirty = true

func _process(_delta: float) -> void:
	if is_instance_valid(game) and game.hud_controls != null:
		var target: Node3D = game.hud_controls.targeting.detection_root
		if is_instance_valid(target): bind(target)
	if not is_instance_valid(source) or not dirty: return
	dirty = false; submitted.clear()
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true
	var cube := BoxMesh.new(); cube.size = Vector3.ONE; mm.mesh = cube
	mm.instance_count = source.get_child_count()
	var count := 0
	for child in source.get_children():
		if not child is MeshInstance3D or not child.mesh is BoxMesh: continue
		var mat: StandardMaterial3D = child.material_override
		if view.material_override == null:
			var shared: StandardMaterial3D = mat.duplicate()
			shared.albedo_color = Color.WHITE; shared.vertex_color_use_as_albedo = true
			view.material_override = shared
		var transform: Transform3D = global_transform.affine_inverse()*child.global_transform*Transform3D(Basis.from_scale(child.mesh.size),Vector3.ZERO)
		submitted.append({"transform":transform,"color":mat.albedo_color})
		mm.set_instance_transform(count,transform)
		mm.set_instance_color(count,mat.albedo_color); count += 1
	mm.visible_instance_count = count; view.multimesh = mm
