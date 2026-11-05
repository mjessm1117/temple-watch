extends SceneTree
const Campaign = preload("res://scripts/campaign/state.gd")
const Theme13 = preload("res://scripts/armory13_theme.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1; push_error("ARMORY13: " + message)

func check_slots(screen: Control, size_name: String) -> void:
	var bounds := Rect2(Vector2.ZERO, root.size)
	for tile in screen.arsenal.slot_row.get_children():
		var art: TextureRect = tile.get_node("GearArt")
		var item: Label = tile.get_node("ItemName")
		var tier: Label = tile.get_node("Tier")
		check(bounds.encloses(tile.get_global_rect()), size_name + " slot fits screen: " + tile.name)
		check(art.texture != null and art.texture.get_size() == Vector2(128, 128), size_name + " baked gear art: " + tile.name)
		check(Rect2(Vector2.ZERO, tile.size).encloses(art.get_rect()), size_name + " art fits card: " + tile.name)
		var text_width := item.get_theme_font("font").get_string_size(item.text, HORIZONTAL_ALIGNMENT_LEFT, -1, item.get_theme_font_size("font_size")).x
		check(text_width <= item.size.x + 1, size_name + " item name is not clipped: " + tile.name)
		check(tier.text.begins_with("Mk ") and tile.has_node("TierPip2"), size_name + " tier is legible: " + tile.name)
	var form: Button = screen.arsenal.slot_row.get_node("Slot_form")
	check(form.get_node("ItemName").text == "Shii-Cho" and "Form I" in form.tooltip_text, size_name + " full form name is accessible")

func run() -> void:
	var flow = root.get_node("CampaignFlow")
	flow.save_path = "user://armory13-test.json"
	flow.campaign = Campaign.new(); flow.active = true
	var graphics = root.get_node("Graphics")
	var original_tier: String = graphics.effective
	for dimensions in [Vector2i(1366, 768), Vector2i(844, 390)]:
		root.size = dimensions
		graphics.effective = "low"
		var expected_mark := 3 if dimensions.x == 844 else 2
		flow.campaign.soldier("u1").gear.mk.s = expected_mark
		var screen = load("res://scenes/squad.tscn").instantiate()
		root.add_child(screen); await process_frame
		screen.inspect(0); await process_frame
		var size_name := "phone" if dimensions.x == 844 else "desktop"
		check_slots(screen, size_name)
		var weapon: Button = screen.arsenal.slot_row.get_node("Slot_weapon")
		check(weapon.get_node("Tier").text == ("Mk III" if expected_mark == 3 else "Mk II"), size_name + " upgraded mark is explicit")
		check(weapon.get_node("TierPip2").color == (Theme13.GOLD if expected_mark == 3 else Color("2b3d44")), size_name + " three tier pips track mark")
		check(screen.stage.get_node_or_null("ShowroomKey") == null and screen.stage.get_node_or_null("ShowroomRim") == null and screen.stage.get_node_or_null("ShowroomFloorGlow") == null, size_name + " Low adds no lights or glow")
		check(screen.drawer.get_global_rect().end.x <= dimensions.x and screen.drawer.get_global_rect().end.y <= dimensions.y, size_name + " drawer fits screen")
		screen.queue_free(); await process_frame
	graphics.effective = "high"
	root.size = Vector2i(1366, 768)
	var screen = load("res://scenes/squad.tscn").instantiate()
	root.add_child(screen); await process_frame
	check(screen.stage.has_node("ShowroomKey") and screen.stage.has_node("ShowroomRim") and screen.stage.has_node("ShowroomFloorGlow"), "Med/High showroom exists")
	screen.queue_free(); await process_frame
	graphics.effective = original_tier
	var button := Button.new(); Theme13.style_button(button)
	check(button.has_theme_stylebox_override("normal") and button.has_theme_stylebox_override("pressed"), "shared dark panel button style exists")
	button.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(flow.save_path))
	print("ARMORY13 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
