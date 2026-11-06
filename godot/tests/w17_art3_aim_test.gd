extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for kind in ["sniper", "heavy", "tech", "droid", "officer"]:
		for suffix in ["", "_lod1"]:
			var name: String = kind + suffix
			var model: Node3D = load("res://assets/units/w17/" + name + ".glb").instantiate()
			root.add_child(model)
			var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
			assert(player != null, "missing AnimationPlayer: " + name)
			for clip in ["idle", "run", "shoot"]:
				player.play(clip)
				player.advance(0.35)
				await process_frame
				var receiver: Node3D
				var muzzle: Node3D
				for node in model.find_children("*", "Node3D", true, false):
					if not node.name.ends_with("__hand_r"):
						continue
					if "receiver" in node.name or "repeater body" in node.name:
						receiver = node
					if "muzzle" in node.name or "carbine barrel" in node.name or "pistol barrel" in node.name or "long scoped barrel" in node.name or "droid blaster barrel" in node.name:
						muzzle = node
				assert(receiver != null and muzzle != null, "missing weapon nodes: " + name)
				assert(receiver.get_parent() is BoneAttachment3D, "weapon detached: " + name)
				var d: Vector3 = (muzzle.global_position - receiver.global_position).normalized()
				if clip == "shoot":
					var elevation: float = rad_to_deg(asin(d.y))
					assert(absf(elevation) <= 15.0 and d.z > 0.0, "barrel aim outside 15 degrees: " + name)
					print("W17_ART3_AIM ", name, " ", snappedf(elevation, 0.01), " degrees")
			model.queue_free()
	quit()
