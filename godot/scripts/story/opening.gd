extends Control
## Eight short, paced panels before the first mission. Skip shares the completion route.
const UI = preload("res://scripts/campaign/ui.gd")
const World = preload("res://scripts/ui_world.gd")
const Portraits = preload("res://scripts/story14_portraits.gd")
const Phone = preload("res://scripts/phone_layout.gd")
var pages: Array = []
var page_index := 0
var typed := 0.0
var narrative: RichTextLabel
var heading: Label
var speaker: Label
var counter: Label
var portrait: TextureRect
var next_button: Button
var finished := false
var header: HBoxContainer
var panel: Panel
var actions: HBoxContainer
var brand: Label
var hint: Label
var layout_size := Vector2.ZERO

func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/opening.json"))
	if parsed is Dictionary: pages = parsed.get("pages", [])
	_build()
	_show_page(0)

func _build() -> void:
	var bg := World.new()
	bg.stage = "temple"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var wash := ColorRect.new()
	wash.color = Color(0.02, 0.05, 0.06, 0.84)
	wash.mouse_filter = MOUSE_FILTER_IGNORE
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(wash)
	header = HBoxContainer.new()
	add_child(header)
	brand = UI.label("TEMPLE WATCH  /  THE SEALED VISION", 14, UI.GOLD)
	brand.size_flags_horizontal = SIZE_EXPAND_FILL
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.add_child(brand)
	counter = UI.label("", 14, UI.ACCENT)
	counter.autowrap_mode = TextServer.AUTOWRAP_OFF
	counter.custom_minimum_size.x = 70
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(counter)
	portrait = Portraits.picture("Kira Venn", Vector2.ZERO)
	portrait.clip_contents = true
	add_child(portrait)
	panel = Panel.new()
	panel.add_theme_stylebox_override("panel", UI.style(Color(0.04, 0.075, 0.085, 0.97)))
	add_child(panel)
	speaker = UI.label("", 13, UI.GOLD)
	speaker.autowrap_mode = TextServer.AUTOWRAP_OFF
	panel.add_child(speaker)
	heading = UI.label("", 23, UI.ACCENT)
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	panel.add_child(heading)
	narrative = RichTextLabel.new()
	narrative.add_theme_font_override("normal_font", UI.font())
	narrative.add_theme_font_size_override("normal_font_size", 15)
	narrative.add_theme_color_override("default_color", UI.TEXT)
	narrative.bbcode_enabled = false
	narrative.fit_content = false
	narrative.scroll_active = false
	narrative.mouse_filter = MOUSE_FILTER_STOP
	narrative.gui_input.connect(_on_narrative_input)
	panel.add_child(narrative)
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	add_child(actions)
	hint = UI.label("Tap text to reveal, then advance.", 13, UI.MUTED)
	hint.size_flags_horizontal = SIZE_EXPAND_FILL
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	actions.add_child(hint)
	var skip := UI.button("SKIP STORY", _finish)
	skip.custom_minimum_size = Vector2(118, 44)
	actions.add_child(skip)
	next_button = UI.button("CONTINUE  ›", _advance)
	next_button.custom_minimum_size = Vector2(142, 44)
	actions.add_child(next_button)
	resized.connect(_layout)
	_layout.call_deferred()

func _layout() -> void:
	if not is_instance_valid(panel): return
	layout_size = size
	var compact := Phone.narrow(Phone.window_size())
	var safe := Phone.safe_margins(size)
	safe = Vector4(maxf(0.0, safe.x), maxf(0.0, safe.y), maxf(0.0, safe.z), maxf(0.0, safe.w))
	var edge := 12 if compact else 36
	var top := int(safe.y) + (8 if compact else 24)
	var left := int(safe.x) + edge
	var right := int(safe.z) + edge
	var bottom := int(safe.w) + (8 if compact else 24)
	var available := size.x - left - right
	var small := compact and size.x < 750
	var portrait_width := (70 if small else 112) if compact else 260
	var gap := 10 if compact else 22
	var action_height := 44 if compact else 48
	var row_top := top + (23 if small else 28 if compact else 40)
	var row_bottom := size.y - bottom - action_height - 8
	header.position = Vector2(left, top)
	header.size = Vector2(available, 22 if compact else 32)
	portrait.position = Vector2(left, row_top)
	portrait.size = Vector2(portrait_width, row_bottom - row_top)
	panel.position = Vector2(left + portrait_width + gap, row_top)
	panel.size = Vector2(available - portrait_width - gap, row_bottom - row_top)
	speaker.position = Vector2(12, 7 if small else 9)
	speaker.size = Vector2(panel.size.x - 24, 15 if small else 17)
	heading.position = Vector2(12, 23 if small else 28)
	heading.size = Vector2(panel.size.x - 24, 25 if small else 28)
	heading.add_theme_font_size_override("font_size", 20 if small else 23 if compact else 34)
	narrative.position = Vector2(12, 50 if small else 59)
	narrative.size = Vector2(panel.size.x - 24, panel.size.y - (56 if small else 66))
	narrative.add_theme_font_size_override("normal_font_size", 13 if small else 15 if compact else 21)
	actions.position = Vector2(left, row_bottom + 8)
	actions.size = Vector2(available, action_height)
	hint.visible = not small

func _show_page(index: int) -> void:
	if index >= pages.size():
		_finish()
		return
	page_index = index
	var page: Dictionary = pages[index]
	counter.text = "%02d / %02d" % [index + 1, pages.size()]
	speaker.text = str(page.get("speaker", "Jedi Council")).to_upper()
	heading.text = str(page.get("title", ""))
	narrative.text = str(page.get("text", ""))
	narrative.visible_characters = 0
	portrait.texture = Portraits.display_texture(str(page.get("speaker", "Jedi Council")))
	typed = 0.0
	next_button.text = "TO BRIEFING  ›" if index + 1 == pages.size() else "CONTINUE  ›"

func _process(delta: float) -> void:
	if layout_size != size: _layout()
	if narrative != null and narrative.visible_characters >= 0:
		typed += delta * 105.0
		narrative.visible_characters = int(typed)
		if narrative.visible_characters >= narrative.text.length(): narrative.visible_characters = -1

func _advance() -> void:
	if narrative.visible_characters != -1:
		narrative.visible_characters = -1
		return
	_show_page(page_index + 1)

func _on_narrative_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
	elif event is InputEventScreenTouch and event.pressed:
		_advance()

func _finish() -> void:
	if finished: return
	finished = true
	var flow := get_node_or_null("/root/CampaignFlow")
	if flow != null and flow.active: flow.opening_finished()
