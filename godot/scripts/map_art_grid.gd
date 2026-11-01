extends Node3D
## Render the HUD's rule-owned range borders as one faint instanced grid.
## Source nodes remain intact for the HUD's existing refresh/clear contract.
var source: Node3D
var dirty := true
var game: Node
var view: MultiMeshInstance3D

func bind(original: Node3D, owner_game: Node = null) -> void:
	game = owner_game
	source = original; source.visible = false
	source.child_entered_tree.connect(changed); source.child_exiting_tree.connect(changed)
	view = MultiMeshInstance3D.new(); add_child(view)
	var mat := StandardMaterial3D.new(); mat.vertex_color_use_as_albedo = true; mat.albedo_color = Color(1,1,1,0.34)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	view.material_override = mat; view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func changed(_child: Node) -> void: dirty = true

func _process(_delta: float) -> void:
	if is_instance_valid(game): visible = not game.cinematic
	if not dirty or not is_instance_valid(source): return
	dirty = false
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true
	var mesh := BoxMesh.new(); mesh.size = Vector3.ONE; mm.mesh = mesh
	mm.instance_count = source.get_child_count()
	var index := 0
	for child in source.get_children():
		if not child is MeshInstance3D or not child.mesh is BoxMesh: continue
		var size: Vector3 = child.mesh.size
		if size.x < size.z: size.x *= 0.25
		else: size.z *= 0.25
		size.y = 0.012
		var transform: Transform3D = child.transform*Transform3D(Basis.from_scale(size),Vector3.ZERO)
		transform.origin.y -= 0.095
		mm.set_instance_transform(index,transform)
		var tint: Color = child.material_override.albedo_color
		tint.a = 1.0; mm.set_instance_color(index,tint); index += 1
	mm.visible_instance_count = index; view.multimesh = mm
