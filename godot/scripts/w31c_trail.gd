extends RefCounted
## Short lived silhouettes mark the route without adding particles.

static func spawn_trail_ghost(scene_tree: SceneTree, unit_pos: Vector3, unit_sprite: Node3D) -> Node3D:
	if scene_tree == null or unit_sprite == null or not is_instance_valid(unit_sprite): return null
	var parent: Node = scene_tree.current_scene if scene_tree.current_scene != null else scene_tree.root
	var ghost := Node3D.new()
	ghost.name = "W31CTrailGhost"
	ghost.add_to_group("w31c_trail_ghosts")
	parent.add_child(ghost)
	ghost.global_position = unit_pos
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.55, 0.82, 0.95, 0.20)
	material.no_depth_test = true
	for source in unit_sprite.find_children("*", "MeshInstance3D", true, false):
		if not source is MeshInstance3D or source.mesh == null: continue
		var copy := MeshInstance3D.new()
		copy.mesh = source.mesh
		copy.material_override = material
		ghost.add_child(copy)
		copy.global_transform = source.global_transform
	if ghost.get_child_count() == 0:
		var shape := MeshInstance3D.new()
		shape.mesh = CapsuleMesh.new()
		shape.material_override = material
		ghost.add_child(shape)
		shape.position.y = 0.9
	var fade := ghost.create_tween()
	fade.tween_property(material, "albedo_color:a", 0.0, 0.4)
	fade.tween_callback(ghost.queue_free)
	return ghost

static func clear_trail_ghosts(scene_tree: SceneTree) -> void:
	if scene_tree == null: return
	for ghost in scene_tree.get_nodes_in_group("w31c_trail_ghosts"):
		if is_instance_valid(ghost): ghost.queue_free()
