extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Mentor = preload("res://scripts/campaign/mentor17.gd")
const Beats = preload("res://scripts/story/rank19_beats.gd")
const OUT = "/home/jess/projects/tw-logs/w19/temple/"

func _initialize() -> void:
	call_deferred("run")

func _shot(name: String) -> bool:
	var path := OUT + name + ".png"
	var ok := root.get_texture().get_image().save_png(path) == OK
	print("TEMPLE19 SHOT ", path, " ", "ok" if ok else "failed")
	return ok

func run() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://temple19-capture.json"
	var okay := true
	for size in [Vector2i(844, 390), Vector2i(667, 375)]:
		DisplayServer.window_set_size(size)
		root.size = size; root.content_scale_size = size
		var c := Campaign.new(); c.state.wings.training = 1
		var master: Dictionary = c.soldier("u1")
		master.rank = 5; master.title = "Master"
		var pupil: Dictionary = c.soldier("u2")
		pupil.rank = 1; pupil.title = "Padawan"; pupil.xp = 18
		Mentor.room_assign(c, "u1", "u2")
		flow.campaign = c; flow.story = c.story; flow.active = true
		var temple: Control = load("res://scenes/temple.tscn").instantiate()
		root.add_child(temple)
		await process_frame
		temple._open_room("training", "Roster")
		await create_timer(0.4).timeout
		if temple.panel_tween != null: temple.panel_tween.kill()
		temple.station_panel.offset_left = 0
		temple.station_panel.offset_right = 0
		temple.station_panel.modulate.a = 1.0
		for i in 3: await process_frame
		okay = (await _shot("training-room-%dx%d" % [size.x, size.y])) and okay
		temple.queue_free(); await process_frame
	var c := Campaign.new()
	var unit: Dictionary = c.soldier("u2")
	unit.rank = 2
	Beats.on_rank(c.state, unit, 2, 3)
	var trial: Dictionary = Beats.next(c.state)
	okay = (await _story("trials-844x390", trial, c.state)) and okay
	var master: Dictionary = c.soldier("u1")
	master.rank = 5; master.title = "Master"; master.trained_padawans = ["u2", "u4"]
	Beats.on_death(c.state, master, "Relay Station")
	var memorial: Dictionary = Beats.next(c.state)
	okay = (await _story("legacy-memorial-844x390", memorial, c.state)) and okay
	quit(0 if okay else 1)

func _story(name: String, data: Dictionary, state: Dictionary) -> bool:
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390); root.content_scale_size = root.size
	var scene: Control = load("res://scenes/dialogue.tscn").instantiate()
	scene.set_campaign_state(state); scene.show_scene(data)
	root.add_child(scene)
	for i in 6: await process_frame
	scene._reveal()
	scene._advance_dialogue()
	scene._reveal()
	for i in 3: await process_frame
	var ok := await _shot(name)
	scene.queue_free(); await process_frame
	return ok
