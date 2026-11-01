extends RefCounted
## Player and enemy shots share the same impact/outcome sequence.
const Presentation = preload("res://scripts/enemy_presentation.gd")

static func play(game: Node3D, event: Dictionary) -> void:
	await Presentation.show_event(game, event)
