extends RefCounted
## Named squad Jedi occupy completed Temple rooms without runtime lights or animation.
const Jedi = preload("res://scripts/characters/jedi_models.gd")
const ROOM_ORDER := ["barracks", "medical", "war", "council", "hangar", "works", "under", "training", "gardens", "archives", "comms", "armory", "forge"]

static func populate(cells: Dictionary, rooms: Dictionary, state: Dictionary, low: bool) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var heroes: Array = []
	for soldier in state.get("roster", []):
		if str(soldier.get("status", "")) != "active": continue
		var id := Jedi.id_for({"name": soldier.get("n", soldier.get("name", ""))})
		if id != "": heroes.append(id)
	for room_id in ROOM_ORDER:
		if heroes.is_empty(): break
		if not rooms.has(room_id) or not rooms[room_id].built: continue
		if not cells.has(room_id): continue
		var id: String = heroes.pop_front()
		var scene := Jedi.scene_for_id(id, null)
		if low:
			var lod_path := Jedi.ROOT + id + "/" + id + "_lod.glb"
			if ResourceLoader.exists(lod_path): scene = load(lod_path) as PackedScene
		if scene == null: continue
		var actor := scene.instantiate() as Node3D
		actor.name = "Jedi_" + id
		actor.set_meta("show16_jedi", id)
		actor.position = Vector3(-0.9 if room_id != "council" else 0.82, 0.12, 1.45)
		actor.rotation.y = -0.24 if room_id != "council" else 0.20
		actor.scale = Vector3.ONE * 1.5
		cells[room_id].add_child(actor)
		var animator: AnimationPlayer = null
		for candidate in actor.find_children("*", "AnimationPlayer", true, false):
			animator = candidate as AnimationPlayer
			break
		if animator != null and animator.has_animation("idle"):
			animator.play("idle")
			animator.seek(float(result.size()) * 0.31, true)
			animator.stop(true)
		elif low: _pose_lod(actor, id, float(result.size()) * 0.31)
		result.append(actor)
	return result

static func _pose_lod(actor: Node3D, id: String, offset: float) -> void:
	var full_scene := Jedi.scene_for_id(id, null)
	if full_scene == null: return
	var source := full_scene.instantiate() as Node3D
	actor.get_parent().add_child(source)
	source.hide()
	var player: AnimationPlayer = null
	for candidate in source.find_children("*", "AnimationPlayer", true, false):
		player = candidate as AnimationPlayer
		break
	var source_rig: Skeleton3D = null
	var target_rig: Skeleton3D = null
	for candidate in source.find_children("*", "Skeleton3D", true, false):
		source_rig = candidate as Skeleton3D
		break
	for candidate in actor.find_children("*", "Skeleton3D", true, false):
		target_rig = candidate as Skeleton3D
		break
	if player != null and player.has_animation("idle") and source_rig != null and target_rig != null:
		player.play("idle")
		player.seek(offset, true)
		for bone in target_rig.get_bone_count():
			var source_bone := source_rig.find_bone(target_rig.get_bone_name(bone))
			if source_bone < 0: continue
			target_rig.set_bone_pose_position(bone, source_rig.get_bone_pose_position(source_bone))
			target_rig.set_bone_pose_rotation(bone, source_rig.get_bone_pose_rotation(source_bone))
			target_rig.set_bone_pose_scale(bone, source_rig.get_bone_pose_scale(source_bone))
	source.queue_free()
