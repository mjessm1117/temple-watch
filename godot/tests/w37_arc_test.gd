extends SceneTree

const Story = preload("res://scripts/story/story_engine.gd")
const Queue = preload("res://scripts/w37C_return_queue.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
const RoomStory = preload("res://scripts/w25_menus_room_story.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1

func run() -> void:
	var fresh = Campaign.new("normal")
	var story = Story.new(fresh.state)
	var s: Dictionary = story.state
	var debrief: Dictionary = story.start_debrief({"mission_id":"relay", "won":true})
	check(debrief.get("kind", "") == "debrief" and int(s.story.done) == 1, "first mission shows its debrief first")
	Queue.begin(s, "relay")
	check(Queue.active(s) and str(s.w37c_return.stage) == "threat", "return queues current threat after debrief")
	var malgus: Dictionary = Queue.next(s, story)
	check(malgus.get("id", "") == "v00" and malgus.get("name", "") == "Darth Malgus", "first villain beat is Malgus")
	check(str(malgus.get("text", "")).contains("Temple") and str(malgus.get("text", "")).contains("gate"), "Malgus has motive and taunt")
	check(str(malgus.get("eyebrow", "")).contains("Current threat"), "Malgus is labelled current threat")
	check(not s.villain11_seen.has("v01") and int(s.story.done) == 1, "Kaan has not appeared")
	var late = Story.new()
	late.state.story.done = 2
	check(late.next_villain_beat(late.state).get("id", "") == "v00", "even a late first beat is Malgus before Kaan")
	check(story.apply_choice(s, "villain:light").get("ok", false), "Malgus beat dismisses")
	var talk: Dictionary = Queue.next(s, story)
	check(talk.get("kind", "") in ["talk", "scene11"], "one optional Temple talk follows threat")
	check(Queue.next(s, story).is_empty(), "return queue ends after one talk")
	var campaign = Campaign.new("normal")
	campaign.state.story.done = 1
	check(RoomStory.due(campaign, "comms").get("id", "") == "comms_signal", "Comms conversation remains reachable")
	story.start_debrief({"mission_id":"rescue", "won":true})
	Queue.begin(s, "rescue")
	var kaan: Dictionary = Queue.next(s, story)
	check(s.villain11_seen.has("v00") and kaan.get("id", "") == "v01", "Kaan follows an answered Malgus beat")
	check(str(kaan.get("title", "")) == "A vision of what is coming" and str(kaan.get("text", "")).contains("age yet to come"), "Kaan is labelled as a future vision")
	check(not str(kaan.get("text", "")).contains("Bane"), "Era 1 vision keeps Bane hidden")
	print("W37 ARC: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
