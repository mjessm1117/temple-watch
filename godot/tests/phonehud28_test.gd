extends SceneTree
const Layout = preload("res://scripts/hud_phone_layout.gd")
const Labels = preload("res://scripts/w28d_phone_labels.gd")
var checks := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)

func run() -> void:
	for size in [Vector2(956, 440), Vector2(844, 390), Vector2(390, 844), Vector2(897, 406)]:
		var boxes: Dictionary = Layout.boxes(size)
		var controls: Array[Rect2] = [boxes.plate, boxes.tray, boxes.end, boxes.camera]
		for box in controls:
			check(box.size.x >= 44 and box.size.y >= 44, "%s target at least 44pt" % size)
			check(Rect2(Vector2.ZERO, size).encloses(box), "%s target inside safe viewport" % size)
		for i in controls.size():
			for j in range(i + 1, controls.size()):
				check(not controls[i].intersects(controls[j]), "%s controls separated" % size)
		check(not boxes.map.intersects(boxes.tray), "%s free map above actions" % size)
		check(not boxes.map.intersects(boxes.camera), "%s free map clear of camera rail" % size)
	check(Labels.threat({"next_wave26": {"turns": 2}}) == "Reinforcements in 2 turns", "plain reinforcement alert")
	check(Labels.threat({"objective_risk": 2}) == "Zone threatened", "plain zone alert")
	DisplayServer.window_set_size(Vector2i(844, 390))
	root.size = Vector2i(844, 390)
	await process_frame
	var game = load("res://scenes/rescue.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var before: float = game.yaw
	var first := InputEventScreenTouch.new(); first.index = 0; first.pressed = true; first.position = Vector2(250, 190)
	var second := InputEventScreenTouch.new(); second.index = 1; second.pressed = true; second.position = Vector2(350, 190)
	game.cam.touch.handle(first); game.cam.touch.handle(second)
	var twist := InputEventScreenDrag.new(); twist.index = 1; twist.position = Vector2(327, 254)
	game.cam.touch.handle(twist)
	check(game.yaw > before + 0.1, "landscape map remains free for camera twist")
	game.queue_free()
	await process_frame
	print("PHONEHUD28: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
