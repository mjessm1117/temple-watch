extends Button
## Two 96x44 touch targets rendered in one canvas item.
var game: Node

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	flat = true
	custom_minimum_size = Vector2(196, 44)

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for i in range(2):
		var left := 0.0 if i == 0 else 100.0
		draw_rect(Rect2(left, 0, 96, 44), Color("152637ee") if i == 0 else Color("355c49ee"), true)
		draw_rect(Rect2(left, 0, 96, 44), Color("c6d6dc") if i == 0 else Color("a8efbd"), false, 2.0)
		draw_string(font, Vector2(left + 11, 29), "CANCEL" if i == 0 else "CONFIRM", HORIZONTAL_ALIGNMENT_LEFT, 84, 15, Color("edf3f4"))

func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if not pressed or not is_instance_valid(game): return
	if event.position.x < 98.0: game._cancel_order()
	elif game.action == "move" and game.preview_tile.x >= 0: game._move_selected(game.preview_tile)
	accept_event()
