extends Node
var action := "move"
var cinematic := false
var mission: RefCounted
var selected_id := -1
var hovered := Vector2i(-1,-1)
var preview_tile := Vector2i(-1,-1)
var hover_highlights := Node3D.new()

func _init() -> void:
	add_child(hover_highlights)
