extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Progression = preload("res://scripts/campaign/progression.gd")
const Classes = preload("res://scripts/class_registry.gd")
const Mentor = preload("res://scripts/campaign/mentor17.gd")
const Beats = preload("res://scripts/story/rank19_beats.gd")
const Room = preload("res://scripts/campaign/training_room19.gd")
const Scroll = preload("res://scripts/touch_scroll.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("TEMPLE19: " + label)

func _unit(c, jedi: bool) -> Dictionary:
	for unit in c.state.roster:
		if Progression.is_jedi(unit) == jedi: return unit
	return {}

func _buttons(node: Node, result: Array) -> void:
	if node is Button: result.append(node)
	for child in node.get_children(): _buttons(child, result)

func run() -> void:
	var c := Campaign.new()
	var events := []
	c.rank_up.connect(func(unit: Dictionary, old: int, new_rank: int): events.append([unit.id, old, new_rank]))
	for jedi in [true, false]:
		var unit := _unit(c, jedi)
		var side := "jedi" if jedi else "soldier"
		var prefix := "j" if jedi else "s"
		for level in range(2, 9 if jedi else 8):
			unit.rank = level - 1; unit.xp = int(Classes.rank_data(side, level).xp)
			var count: int = c.state.get("rank_story_queue", []).size()
			check(Progression.promote(unit, c.state.roster, c), "%s rank %d advances" % [side, level])
			check(events[-1] == [unit.id, level - 1, level], "%s rank %d emits exact event" % [side, level])
			check(c.state.rank_story_queue.size() == count + 1 and c.state.rank_story_seen.has(str(unit.id) + ":" + prefix + str(level)), "%s rank %d queues one beat" % [side, level])
			check(not Progression.promote(unit, c.state.roster, c) and c.state.rank_story_queue.size() == count + 1, "%s rank %d does not repeat" % [side, level])
	check(Beats.BEATS.size() == 16, "sixteen original rank and legacy beats")
	check(c.story.journal(c.state).ranks.size() == 13, "rank beats appear in Journal")
	var first: Dictionary = Beats.next(c.state)
	check(first.id == "u1:j2" and c.state.pending.id == first.id, "queued beat uses story screen pending contract")
	check(c.story.apply_choice(c.state, "rank19:continue").ok, "rank beat resolves through story choice")
	var save_path := "user://temple19-ranks-%d.json" % OS.get_process_id()
	var restored := Campaign.new()
	check(c.save(save_path) and restored.load_save(save_path), "rank story state survives save and load")
	var seen_count: int = restored.state.rank_story_queue.size()
	var restored_unit: Dictionary = restored.soldier("u1")
	restored_unit.rank = 1; restored_unit.xp = int(Classes.rank_data("jedi", 2).xp)
	Progression.promote(restored_unit, restored.state.roster, restored)
	check(restored.state.rank_story_queue.size() == seen_count, "seen rank beat does not replay after load")
	var m := Campaign.new()
	m.state.wings.training = 1
	var master: Dictionary = m.soldier("u1")
	var pupil: Dictionary = m.soldier("u2")
	master.rank = 5; master.title = "Master"
	pupil.rank = 1; pupil.title = "Padawan"; pupil.xp = 0
	check(Mentor.room_slots(m) == 1, "first Training Salle level has one slot")
	check(Mentor.room_assign(m, "u1", "u2"), "tap flow assigns Master and Padawan")
	check(master.trained_padawans.has("u2") and m.state.rank_story_seen.has("u1:first_pupil"), "pairing feeds legacy count and first pupil beat")
	var second: Dictionary = pupil.duplicate(true)
	second.id = "u99"; second.n = "Kiri Vass"; second.erase("mentor_id")
	m.state.roster.append(second)
	check(not Mentor.room_assign(m, "u1", "u99"), "one-slot limit holds")
	var before := int(pupil.xp)
	m.state.pending_mission = {"squad":["u2"]}
	Mentor.tick(m)
	check(int(pupil.xp) == before, "deployed Padawan does not train")
	m.state.pending_mission = {}
	m.advance_days(1)
	check(int(pupil.xp) == before + 3, "paired Padawan receives between-mission XP")
	check(Mentor.unassign(m, "u2") and not pupil.has("mentor_id"), "tap flow unassigns")
	check(master.trained_padawans.has("u2"), "unassign keeps trained history")
	m.state.wings.training = 2
	check(Mentor.room_slots(m) == 2, "existing room upgrade opens second slot")
	check(Mentor.room_assign(m, "u1", "u2") and Mentor.room_assign(m, "u1", "u99"), "two slots accept two pupils")
	var third: Dictionary = second.duplicate(true)
	third.id = "u100"; third.erase("mentor_id"); m.state.roster.append(third)
	check(not Mentor.room_assign(m, "u1", "u100"), "third slot and third pupil rejected")
	check(not Mentor.assign(m, "u1", "u100", "guard"), "direct mentor API cannot bypass room slots")
	pupil.rank = 2; pupil.xp = int(Classes.rank_data("jedi", 3).xp)
	check(Progression.promote(pupil, m.state.roster, m), "pupil becomes Knight")
	check(m.state.rank_story_seen.has("u2:knighted_pupil"), "Master receives knighting line")
	var memorial_before: int = m.state.rank_story_queue.size()
	Mentor.on_death(m, master, "Relay Station")
	check(m.state.rank_story_queue.size() == memorial_before + 1 and m.state.rank_story_seen.has("u1:memorial"), "trained Master's death queues memorial")
	Mentor.on_death(m, master, "Relay Station")
	check(m.state.rank_story_queue.size() == memorial_before + 1, "memorial fires once")
	check(m.story.journal(m.state).ranks.any(func(line): return "What Remains" in line), "memorial enters Journal")
	await _layout()
	print("TEMPLE19: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _layout() -> void:
	for size in [Vector2i(667, 375), Vector2i(844, 390), Vector2i(1366, 768)]:
		root.size = size; root.content_scale_size = size
		var c := Campaign.new(); c.state.wings.training = 1
		var master: Dictionary = c.soldier("u1"); master.rank = 5; master.title = "Master"
		var frame := Control.new(); root.add_child(frame)
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var scroll := Scroll.new(); frame.add_child(scroll)
		scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scroll.offset_left = 8; scroll.offset_right = -8; scroll.offset_top = 8; scroll.offset_bottom = -8
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var room := Room.new(); scroll.add_child(room); room.setup(c)
		await process_frame
		check(room.get_global_rect().position.x >= 0 and room.get_global_rect().end.x <= size.x, "Training Room width fits %s" % size)
		var buttons := []; _buttons(room, buttons)
		check(buttons.size() >= 2 and buttons.all(func(b): return b.size.y >= 44 and b.size.x >= 44), "44 px tap targets at %s" % size)
		check(buttons.all(func(b): return b.mouse_filter == Control.MOUSE_FILTER_PASS), "buttons pass finger drag at %s" % size)
		var button: Button = buttons[0]
		var start := button.get_global_rect().get_center()
		var touch := InputEventScreenTouch.new(); touch.pressed = true; touch.position = start
		scroll._gui_input(touch)
		var drag := InputEventScreenDrag.new(); drag.position = start - Vector2(0, 100)
		scroll._gui_input(drag)
		var progressed := scroll.scroll_vertical
		if size.x < 900: check(progressed > 0, "finger drag starting on button scrolls at %s" % size)
		await process_frame
		check(scroll.scroll_vertical == progressed, "scroll position stays during drag at %s" % size)
		if size.x == 667:
			button.pressed.emit(); await process_frame
			var pupil_buttons := room.find_children("*", "Button", true, false).filter(func(b): return b.text.begins_with("Tor Saalen"))
			check(pupil_buttons.size() == 1, "tap Master reveals eligible Padawan")
			if not pupil_buttons.is_empty(): pupil_buttons[0].pressed.emit()
			await process_frame
			check(str(c.soldier("u2").get("mentor_id", "")) == "u1", "Padawan button assigns pair")
			var pair_buttons := room.find_children("*", "Button", true, false).filter(func(b): return "→" in b.text)
			check(pair_buttons.size() == 1, "assigned pair has unassign button")
			if not pair_buttons.is_empty(): pair_buttons[0].pressed.emit()
			await process_frame
			check(str(c.soldier("u2").get("mentor_id", "")) == "", "pair button unassigns pair")
		frame.queue_free(); await process_frame
