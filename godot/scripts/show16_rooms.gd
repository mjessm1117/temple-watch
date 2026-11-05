extends RefCounted
## Named squad Jedi occupy completed Temple rooms without runtime lights or animation.
const Jedi = preload("res://scripts/characters/jedi_models.gd")
const ROOM_ORDER := ["council", "war", "barracks", "medical", "hangar", "works", "under", "training", "gardens", "archives", "comms", "armory", "forge"]

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
		actor.position = Vector3(-0.9 if room_id != "council" else 0.82, 0.12, 0.95)
		actor.rotation.y = -0.24 if room_id != "council" else 0.20
		actor.scale = Vector3.ONE * 0.79
		cells[room_id].add_child(actor)
		var animator: AnimationPlayer = null
		for candidate in actor.find_children("*", "AnimationPlayer", true, false):
			animator = candidate as AnimationPlayer
			break
		if animator != null and animator.has_animation("idle"):
			animator.play("idle")
			animator.seek(float(result.size()) * 0.31, true)
			animator.stop(true)
		result.append(actor)
	return result
