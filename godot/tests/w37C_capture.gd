extends SceneTree
## 844x390 villain beat proof. Before reconstructs the unchanged 0d2c8da first beat.

const Story = preload("res://scripts/story/story_engine.gd")
const Phone = preload("res://scripts/phone_layout.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var before := "--before" in OS.get_cmdline_user_args()
	var size := Vector2i(390, 844) if "--portrait" in OS.get_cmdline_user_args() else Vector2i(844, 390)
	Phone.test_touch = 1
	Phone.test_mobile = 1
	Phone.test_scale = 1
	root.size = size
	root.content_scale_size = size
	DisplayServer.window_set_size(size)
	var story = Story.new()
	story.state.story.done = 1
	var beat: Dictionary
	if before:
		beat = {"kind":"villain11", "id":"v01", "name":"Lord Kaan",
			"title":"The equal throne", "eyebrow":"Force vision",
			"text":"A Force vision shows a future Sith Lord named Kaan. He promises every Lord a throne in a Brotherhood of Darkness.",
			"choices":[{"id":"villain:light","label":"Answer with resolve","fx":{"orderDark":-2}}, {"id":"villain:dark","label":"Answer with fear","fx":{"orderDark":2}}]}
	else:
		beat = story.next_villain_beat(story.state)
	var scene = preload("res://scenes/dialogue.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.show_scene(beat)
	for i in 12: await process_frame
	scene._reveal()
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	var path := "/home/jess/projects/tw-logs/w37/lane-C/arc-%s-%dx%d.png" % ["before" if before else "after", size.x, size.y]
	var err := root.get_texture().get_image().save_png(path)
	print("W37 ARC SHOT: %s %s" % [path, error_string(err)])
	quit(0 if err == OK else 1)
