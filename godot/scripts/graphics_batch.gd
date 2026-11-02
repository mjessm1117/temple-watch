extends "res://scripts/meshy_theme_batch.gd"
## Tag pairs before the deferred quality pass; duplicate sibling names are unstable.
func flush(parent: Node3D) -> void:
	var first := parent.get_child_count()
	super.flush(parent)
	for index in range(first,parent.get_child_count()):
		var holder := parent.get_child(index)
		if holder is GeometryInstance3D: continue
		for instance in holder.get_children():
			if instance is MultiMeshInstance3D:
				instance.set_meta("graphics_lod",1 if instance.visibility_range_begin > 0 else 0)
