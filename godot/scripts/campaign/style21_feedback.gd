extends Node
## Brief tint feedback that keeps Control geometry and scroll drags stable.
var button: BaseButton
var restore: Tween

func _ready() -> void:
	button = get_parent() as BaseButton
	button.button_down.connect(_down)
	button.button_up.connect(_up)

func _down() -> void:
	if button.disabled: return
	if restore != null and restore.is_running(): restore.kill()
	button.self_modulate = Color("b8e5eb")

func _up() -> void:
	if restore != null and restore.is_running(): restore.kill()
	restore = button.create_tween()
	restore.tween_property(button, "self_modulate", Color.WHITE, 0.1)
