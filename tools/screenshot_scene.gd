extends SceneTree
## Capture the current battle scene at the mobile battle viewport size.

const DEFAULT_OUTPUT := "/home/jess/projects/tw-logs/tooling/battle-engine.png"

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var output := DEFAULT_OUTPUT
	var mask_controls := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
		if arg == "--mask-controls":
			mask_controls = true
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	var scene := load("res://scenes/rescue.tscn") as PackedScene
	if scene == null:
		push_error("Battle scene res://scenes/rescue.tscn did not load")
		quit(1)
		return
	root.add_child(scene.instantiate())
	if mask_controls:
		var layer := CanvasLayer.new()
		layer.layer = 100
		root.add_child(layer)
		var mask := ColorRect.new()
		mask.color = Color.BLACK
		mask.position = Vector2(0, 240)
		mask.size = Vector2(844, 150)
		layer.add_child(mask)
		var turn_mask := ColorRect.new()
		turn_mask.color = Color.BLACK
		turn_mask.position = Vector2(690, 0)
		turn_mask.size = Vector2(154, 70)
		layer.add_child(turn_mask)
	for frame in 30:
		await process_frame
	var error := root.get_texture().get_image().save_png(output)
	if error == OK:
		print("SCREENSHOT SAVED: ", output)
	else:
		push_error("Screenshot failed: " + error_string(error))
	quit(0 if error == OK else 1)
