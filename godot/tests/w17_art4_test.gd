extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func _is_pack(node: Node) -> bool:
	while node != null:
		if node.name.begins_with("rocket backpack") or node.name.begins_with("rocket tube"):
			return true
		node = node.get_parent()
	return false

func _world_top(mesh: MeshInstance3D) -> float:
	var box := mesh.get_aabb()
	var top := -INF
	for x in [box.position.x, box.end.x]:
		for y in [box.position.y, box.end.y]:
			for z in [box.position.z, box.end.z]:
				top = maxf(top, (mesh.global_transform * Vector3(x, y, z)).y)
	return top

func run() -> void:
	for kind in ["sniper", "heavy", "tech", "droid", "officer"]:
		for suffix in ["", "_lod1"]:
			var name: String = kind + suffix
			var model: Node3D = load("res://assets/units/w17/" + name + ".glb").instantiate()
			root.add_child(model)
			var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
			assert(player != null, "missing AnimationPlayer: " + name)
			var has_accent := false
			for mesh in model.find_children("*", "MeshInstance3D", true, false):
				for surface in range(mesh.mesh.get_surface_count()):
					var material: Material = mesh.mesh.surface_get_material(surface)
					if material != null and "accent" in material.resource_name:
						has_accent = true
			assert(has_accent, "missing accent: " + name)
			player.play("shoot")
			player.advance(0.35)
			await process_frame
			var receiver: Node3D
			var muzzle: Node3D
			for node in model.find_children("*", "Node3D", true, false):
				if not node.name.ends_with("__hand_r"):
					continue
				if "receiver" in node.name or "repeater body" in node.name:
					receiver = node
				if "muzzle" in node.name or "carbine barrel" in node.name or "pistol barrel" in node.name or "droid blaster barrel" in node.name:
					muzzle = node
			assert(receiver != null and muzzle != null, "missing weapon: " + name)
			assert(receiver.get_parent() is BoneAttachment3D, "weapon detached: " + name)
			var direction: Vector3 = (muzzle.global_position - receiver.global_position).normalized()
			var elevation := rad_to_deg(asin(direction.y))
			assert(absf(elevation) <= 15.0 and direction.z > 0.0, "barrel aim outside 15 degrees: " + name)
			if kind == "heavy":
				var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
				assert(skeleton != null, "missing skeleton: " + name)
				var head_end := skeleton.find_bone("head_end")
				assert(head_end >= 0, "missing head_end: " + name)
				var head_top := skeleton.to_global(skeleton.get_bone_global_pose(head_end).origin).y
				var pack_top := -INF
				for mesh in model.find_children("*", "MeshInstance3D", true, false):
					if _is_pack(mesh):
						assert(mesh.get_parent() is BoneAttachment3D and (mesh.get_parent() as BoneAttachment3D).bone_name == "spine_03", "pack detached from spine: " + name)
						pack_top = maxf(pack_top, _world_top(mesh))
				print("W17_ART4_PACK ", name, " top=", pack_top, " head_end=", head_top)
				assert(pack_top > -INF and pack_top < head_top, "pack above helmet: " + name)
			print("W17_ART4 ", name, " accent and aim ", snappedf(elevation, .01))
			model.queue_free()
	quit()
