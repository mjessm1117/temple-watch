extends SceneTree

const Endings = preload("res://scripts/story/ending_resolution.gd")
const Story = preload("res://scripts/story/story_engine.gd")
const Queue = preload("res://scripts/w37C_return_queue.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1

func run() -> void:
	var cases := [
		["dark_council", {"orderDark":20,"story":{"shadow":2},"flags":{"sith_arrested":true,"chips_all":true}}],
		["dawn_unbroken", {"orderDark":0,"story":{"shadow":3},"flags":{"sith_arrested":true,"chips_all":true}}],
		["vision_fades", {"orderDark":0,"story":{"shadow":4},"flags":{"e2_bane_dead":true}}],
		["long_exile", {"orderDark":0,"story":{"shadow":6},"flags":{}}],
		["grey_peace", {"orderDark":0,"story":{"shadow":8},"flags":{"sith_arrested":true}}],
		["the_fire", {"orderDark":0,"story":{"shadow":8},"flags":{}}]
	]
	var rows: Array = Endings.endings()
	check(rows.size() == 6, "six authored endings load")
	for i in cases.size():
		var expected: String = cases[i][0]
		var state: Dictionary = cases[i][1]
		var ending: Dictionary = Endings.resolve(state)
		check(ending.get("id", "") == expected, expected + " is reachable in order")
		check(Endings.resolve(state) == ending, expected + " is deterministic")
		var words := str(ending.get("text", "")).split(" ", false)
		var sentences := str(ending.get("text", "")).split(".", false)
		check(words.size() <= 60 and sentences.size() >= 2 and sentences.size() <= 4, expected + " fits one phone page")
	var story = Story.new()
	var s: Dictionary = story.state
	s.era = 3
	s.story.shadow = 8
	story.start_debrief({"mission_id":"h_beacon", "won":false})
	Queue.begin(s, "h_beacon")
	var scene: Dictionary = Queue.next(s, story)
	check(scene.get("kind", "") == "ending" and scene.get("id", "") == s.ending, "Era 3 completion resolves and queues ending")
	check(Queue.next(s, story).is_empty(), "ending is a single dismissible scene")
	print("W37 ENDINGS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
