extends RefCounted
const Shot = preload("res://scripts/shot.gd")

static func unit_id(event: Dictionary, key: String) -> String:
	return str(event.get(key, "")) if event.has(key) else ""

static func objective_hp(game: Node3D, kind: String) -> int:
	if kind == "vip_attack": return int(game.mission.prisoner.get("hp", 0))
	var state: Dictionary = game.mission.objective_state
	return int(state.get("relay_hp", state.get("hp", 0)))

static func emit(game: Node3D, kind: String, event: Dictionary, position: Vector3, extra: Dictionary = {}) -> void:
	var context := {"world_pos":position, "turn":int(game.mission.turn)}
	if event.has("damage"): context.damage = int(event.damage)
	if event.has("group"): context.group = int(event.group)
	if kind == "objective_hit": context.objective_hp = objective_hp(game, str(event.get("kind", "")))
	context.merge(extra, true)
	var target_id := "gate" if kind == "objective_hit" and str(event.get("kind", "")) == "objective_attack" else "vip" if kind == "objective_hit" else unit_id(event, "target")
	game.battle_event.emit(kind, unit_id(event, "actor"), target_id, context)

static func cue(game: Node3D, kind: String) -> void:
	if game.sound != null and game.sound.has_method("cue"): game.sound.cue(kind)

static func music(game: Node3D, state: String) -> void:
	if game.sound != null and game.sound.has_method("set_music_state"): game.sound.set_music_state(state)
