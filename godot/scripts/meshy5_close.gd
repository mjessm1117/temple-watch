extends "res://scripts/meshy5_capture.gd"
## Focused real-map close capture of the accepted snow half cover.
func run() -> void:
	Settings.difficulty = "normal"
	root.borderless = true
	root.unresizable = true
	root.min_size = Vector2i(1920,1080)
	root.size = Vector2i(1920,1080)
	root.position = Vector2i(0,0)
	root.content_scale_size = Vector2i(1920,1080)
	await show_battle("ilum")
	lock_camera()
	var records: Array = game.terrain.get_child(0).batch.records
	for record in records:
		if record.role == "cover" and record.kind in ["c", "h"] and record.has("meshy_path"):
			await close_to(record,5.0)
			await save_shot("ilum-after-half-close")
			break
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
