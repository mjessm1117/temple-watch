extends SceneTree
## Isolated staged-art smoke test. Does not add units to game data.
func _initialize() -> void:
	for kind in ["sniper", "heavy", "tech", "droid", "officer", "sniper_lod1", "heavy_lod1", "tech_lod1", "droid_lod1", "officer_lod1"]:
		var path: String = "res://assets/units/w17/" + kind + ".glb"
		var packed: PackedScene = load(path)
		assert(packed != null, "cannot load " + path)
		var model := packed.instantiate()
		root.add_child(model)
		var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		assert(player != null, "no AnimationPlayer in " + kind)
		for clip in ["idle", "run", "shoot", "hit", "death"]:
			assert(player.has_animation(clip), "missing " + clip + " in " + kind)
			player.play(clip)
			player.advance(0.15)
			assert(player.current_animation == clip, "clip failed to play: " + kind + "/" + clip)
			var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
			assert(skeleton != null and skeleton.get_bone_count() > 20, "missing humanoid skeleton in " + kind)
			for bone in range(skeleton.get_bone_count()):
				assert(skeleton.get_bone_pose_position(bone).is_finite(), "invalid bone translation in " + kind + "/" + clip)
			print("W17_ART_ANIM ", kind, " ", clip, " ok")
		model.queue_free()
	quit()
