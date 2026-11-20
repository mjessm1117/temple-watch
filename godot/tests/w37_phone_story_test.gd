extends SceneTree

const Phone = preload("res://scripts/phone_layout.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1

func run() -> void:
	root.size = Vector2i(844, 390)
	root.content_scale_size = root.size
	Phone.test_window_size = root.size
	var packed := load("res://scenes/briefing.tscn") as PackedScene
	check(packed != null, "story screen scene loads")
	if packed == null:
		quit(1)
		return
	var screen := packed.instantiate() as Control
	root.add_child(screen)
	screen.show_scene({"kind":"talk", "name":"Kira Venn", "title":"The Vision", "eyebrow":"Temple", "text":"The first sentence starts here. The next sentence stays on this page.", "choices":[{"id":"one", "label":"First choice"}, {"id":"two", "label":"Second choice"}]})
	await process_frame
	await process_frame
	var scroll := screen.find_child("StoryScroll", true, false) as ScrollContainer
	check(scroll != null, "story screen has one story ScrollContainer")
	if scroll != null:
		check(scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "story scroll allows vertical touch scrolling")
		check(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "story scroll uses automatic scroll mode")
	check(screen.custom_minimum_size.y <= 350 and screen.anchor_bottom == 1.0, "root fills the 390px viewport without a tall minimum")
	check(screen.narrative != null and screen.narrative.get_global_rect().position.y < 200, "first sentence starts above y=200 (%.0f)" % (screen.narrative.get_global_rect().position.y if screen.narrative != null else -1.0))
	var action: Button = null
	for button in screen.find_children("*", "Button", true, false):
		if button.text.begins_with("TAP TO ADVANCE"): action = button
	check(action != null and action.get_global_rect().end.y <= 390, "page action stays in initial viewport")
	check(screen.choice_buttons.size() == 2, "both choice buttons are built")
	var choices_in_scroll := scroll != null
	for button in screen.choice_buttons:
		if scroll == null or not scroll.is_ancestor_of(button): choices_in_scroll = false
	check(choices_in_scroll, "all choice buttons share the story scroll region")
	screen._skip_dialogue()
	await process_frame
	await process_frame
	check(screen.choice_buttons[0].visible and screen.choice_buttons[0].get_global_rect().intersects(scroll.get_global_rect()), "first choice comes into view when decisions open")
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await process_frame
	check(screen.choice_buttons[1].get_global_rect().intersects(scroll.get_global_rect()), "last choice is reachable in the same scroll region")
	var opening := load("res://scenes/opening.tscn").instantiate() as Control
	root.add_child(opening)
	await process_frame
	check(opening.narrative.get_global_rect().position.y < 200 and opening.next_button.get_global_rect().end.y <= 390, "opening sentence and page action fit 844x390")
	Phone.test_window_size = Vector2i.ZERO
	print("W37 PHONE STORY: %d checks, %d FAIL" % [checks, failures])
	quit(1 if failures > 0 else 0)
