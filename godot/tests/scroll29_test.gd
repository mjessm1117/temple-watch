extends SceneTree
const Scroll = preload("res://scripts/touch_scroll.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("SCROLL29: " + label)

func run() -> void:
	check(Scroll.is_drag(9.9) == false and Scroll.is_drag(10.0), "10 pt drag threshold")
	check(Scroll.decay(300.0, 0.1) < 300.0 and Scroll.decay(300.0, 0.1) > 0.0, "inertia decays")
	var position := 100.0
	var speed := 300.0
	for i in 100:
		position += speed * 0.016
		speed = Scroll.decay(speed, 0.016)
	check(position > 120.0 and speed < 1.0, "flick travels then stops")
	var edge := -28.0
	var edge_speed := 0.0
	for i in 120:
		var next := Scroll.spring_step(edge, edge_speed, 0.016)
		edge = next.x
		edge_speed = next.y
	check(absf(edge) < 0.5, "edge springs back")
	check(Scroll.handoff(10.0, 50.0, 100.0) == 0.0, "inner scroll first")
	check(Scroll.handoff(10.0, 100.0, 100.0) == 10.0, "outer handoff at end")
	check(Scroll.handoff(-10.0, 0.0, 100.0) == -10.0, "outer handoff at start")
	var outer := Scroll.new()
	outer.size = Vector2(180, 180)
	outer.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(outer)
	var body := Control.new()
	body.custom_minimum_size = Vector2(180, 500)
	outer.add_child(body)
	var inner := Scroll.new()
	inner.position = Vector2(0, 20)
	inner.size = Vector2(180, 100)
	inner.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(inner)
	var inner_body := Control.new()
	inner_body.custom_minimum_size = Vector2(180, 300)
	inner.add_child(inner_body)
	await process_frame
	inner._move(Vector2(0, 40), true)
	check(inner.scroll_vertical > 0 and outer.scroll_vertical == 0, "inner list consumes drag")
	inner.scroll_vertical = int(inner._limit(1))
	inner._move(Vector2(0, 40), true)
	check(outer.scroll_vertical > 0, "outer takes unused drag at edge")
	inner.scroll_vertical = 0
	outer.scroll_vertical = 0
	inner.edge = Vector2.ZERO
	inner._move(Vector2(0, -80), true)
	check(inner.edge.y > 0.0 and inner.edge.y <= Scroll.EDGE_LIMIT, "content edge is softly limited")
	outer.queue_free()
	await process_frame
	print("SCROLL29 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
