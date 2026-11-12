extends Node
## Keep the landscape confirm buttons off the selected soldier and map center.
var g: Node

static func place(game: Node) -> void:
	if game == null or not is_instance_valid(game) or game.hud_controls == null or game.hud_controls.phone == null: return
	var free: Rect2 = game.hud_controls.phone.hud_safe_rect28()
	if free.size.x <= free.size.y: return
	var controls: Control = game.overlay.get_node_or_null("MoveConfirm24")
	if controls == null or not controls.visible: return
	controls.position = Vector2(free.end.x - 196.0, free.position.y + 4.0)
	controls.size = Vector2(196.0, 44.0)

func _ready() -> void:
	process_priority = 1000

func _process(_delta: float) -> void:
	place(g)
