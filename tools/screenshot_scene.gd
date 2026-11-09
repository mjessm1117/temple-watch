extends SceneTree
## Capture the current battle scene at the mobile battle viewport size.

const OUTPUT := "/home/jess/projects/tw-logs/tooling/battle-engine.png"

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	var scene := load("res://scenes/rescue.tscn") as PackedScene
	if scene == null:
		push_error("Battle scene res://scenes/rescue.tscn did not load")
		quit(1)
		return
	root.add_child(scene.instantiate())
	for frame in 30:
		await process_frame
	var error := root.get_texture().get_image().save_png(OUTPUT)
	if error == OK:
		print("SCREENSHOT SAVED: ", OUTPUT)
	else:
		push_error("Screenshot failed: " + error_string(error))
	quit(0 if error == OK else 1)
