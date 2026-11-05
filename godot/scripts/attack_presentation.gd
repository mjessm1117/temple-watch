extends RefCounted
## Player and enemy shots share the same impact/outcome sequence.
const ShotBeat = preload("res://scripts/cine15_shot.gd")

static func play(game: Node3D, event: Dictionary) -> void:
	await ShotBeat.play(game, event)
