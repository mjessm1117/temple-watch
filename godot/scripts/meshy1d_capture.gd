extends "res://scripts/map_preview.gd"
## Real window, actual missions and HUD. Same deterministic camera before/after.
func run() -> void:
	Settings.difficulty = "normal"
	root.borderless = true; root.unresizable = true
	root.size = Vector2i(1920,1080); root.position = Vector2i(0,50)
	root.content_scale_size = Vector2i(1920,1080)
	var args := OS.get_cmdline_user_args()
	var suffix := args[0] if not args.is_empty() else "after"
	for asset in ["cover_half_temple"]:
		await show_battle("archive" if asset == "obj_terminal" else "fixture")
		game.terrain.get_child(0).props.meshy1_enabled = true
		if suffix == "candidate":
			game.terrain.get_child(0).props.meshy1_models.half_cover = "res://assets/maps/meshy1/cover_half_temple_v3.glb"
		game._build_terrain(); game._refresh()
		await create_timer(2.0).timeout
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		assert(picture.get_size() == Vector2i(1920,1080))
		picture.save_png(ProjectSettings.globalize_path("res://../docs/godot/shots/meshy1d-cover-%s.png" % suffix))
		for record in game.terrain.get_child(0).batch.records:
			if (asset == "obj_terminal" and record.role == "objective" and record.kind == "hack_terminal") or (asset == "cover_half_temple" and record.role == "cover" and record.kind in ["c","h"]):
				var target := Vector3(record.tile.x,float(record.floor)+0.6,record.tile.y)
				await game.cam.frame(target+Vector3(1,0,2),target,"shoot")
				if game.action_tween != null: game.action_tween.kill()
				game.camera.position = target+Vector3(2.2,1.8,3.2)
				game.camera.look_at(target)
				await create_timer(0.5).timeout
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../docs/godot/shots/meshy1d-cover-%s-close.png" % suffix))
				game.cam.finish(); break
		game.queue_free(); await process_frame
	quit()
