extends PanelContainer
const UI = preload("res://scripts/campaign/ui.gd")
var layer: CanvasLayer

func present(game: Node, scene: Dictionary, chosen: Callable) -> void:
	layer = CanvasLayer.new()
	layer.layer = 16
	game.add_child(layer)
	layer.add_child(self)
	var size_x := float(game.get_viewport().get_visible_rect().size.x)
	custom_minimum_size.x = minf(350.0,size_x-24.0)
	position = Vector2(size_x-custom_minimum_size.x-12.0,12.0)
	add_theme_stylebox_override("panel",UI.style(Color(0.04,0.075,0.085,0.97),UI.GOLD))
	var stack := UI.column(5)
	add_child(stack)
	stack.add_child(UI.label("TURN DECISION  ·  " + str(scene.get("name","FIELD COMMS")).to_upper(),14,UI.GOLD))
	stack.add_child(UI.label(str(scene.get("text","")),14,UI.TEXT))
	for choice in scene.get("choices",[]):
		var button := UI.button(str(choice.get("label","Choose")),func(): chosen.call(str(choice.get("id",""))))
		button.custom_minimum_size.y = 44
		stack.add_child(button)

func close() -> void:
	if is_instance_valid(layer): layer.queue_free()
