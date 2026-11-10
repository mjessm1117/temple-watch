extends SceneTree
const OUT := "/home/jess/projects/tw-logs/w22/storydelivery/"

func _initialize() -> void: call_deferred("run")

func shot(name: String) -> void:
	for i in 12: await process_frame
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(OUT + name + ".png")
	print("SHOT %s %s" % [name,err])

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var portrait := "--portrait" in OS.get_cmdline_user_args()
	var dimensions := Vector2i(390,844) if portrait else Vector2i(844,390)
	var suffix := "-portrait" if portrait else ""
	DisplayServer.window_set_size(dimensions)
	root.size = dimensions
	root.content_scale_size = root.size
	var opening = preload("res://scenes/opening.tscn").instantiate()
	root.add_child(opening)
	await process_frame
	opening._show_page(0)
	opening.narrative.visible_characters = -1
	await shot("after-opening" + suffix)
	print("OPENING_NEXT_RECT %s %s" % [suffix,opening.next_button.get_global_rect()])
	if "--opening-only" in OS.get_cmdline_user_args():
		quit()
		return
	opening.queue_free()
	await process_frame
	if "--story-screen" in OS.get_cmdline_user_args():
		var story_screen = preload("res://scenes/briefing.tscn").instantiate()
		root.add_child(story_screen)
		story_screen.show_scene({"kind":"briefing","title":"A longer briefing","text":"A second distress call reaches the squad. The wounded wait beneath the gate while the enemy regroups. The squad must decide where to stand before the next assault.","choices":[]})
		story_screen._reveal()
		await shot("after-story-screen" + suffix)
		quit()
		return
	var game = preload("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 16: await process_frame
	var prompt = preload("res://scripts/storydelivery22_prompt.gd").new()
	prompt.present(game,{"name":"Field Comms","text":"A local garrison asks where the Jedi should stand.","choices":[{"id":"beat:0","label":"Protect the people first"},{"id":"beat:1","label":"Press the objective"}]},func(_id): pass)
	await shot("after-choice" + suffix)
	print("PROMPT_RECT %s %s" % [suffix,prompt.get_global_rect()])
	prompt.close()
	var comms = game.get_meta("story_comms") if game.has_meta("story_comms") else preload("res://scripts/story14_comms.gd").new(game)
	comms.show_radio("Darth Malgus","Darth Malgus","The gate is mine.",3)
	await shot("after-radio" + suffix)
	quit()
