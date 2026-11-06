extends VBoxContainer
## Shared title/options control. No campaign or battle state is changed.
var choices: OptionButton
var status: Label

func _ready() -> void:
	var title := Label.new(); title.text = "GRAPHICS"; add_child(title)
	choices = OptionButton.new(); choices.name = "GraphicsTier"
	if preload("res://scripts/phone_layout.gd").narrow(preload("res://scripts/phone_layout.gd").window_size()):
		choices.custom_minimum_size.y = 44
		choices.add_theme_font_size_override("font_size", 14)
	for tier in ["Low", "Medium", "High"]: choices.add_item(tier)
	add_child(choices)
	status = Label.new(); status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size",13); add_child(status)
	choices.item_selected.connect(_select)
	get_node("/root/Graphics").changed.connect(refresh)
	refresh()

func refresh() -> void:
	var graphics = get_node("/root/Graphics")
	choices.select(graphics.TIERS.find(graphics.requested))
	status.text = graphics.status_text()

func _select(index: int) -> void:
	var graphics = get_node("/root/Graphics")
	var error: Error = graphics.select_tier(graphics.TIERS[index])
	if error != OK:
		refresh(); status.text = "Could not save graphics: "+error_string(error)
