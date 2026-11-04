extends CanvasLayer
## One-line tactics for new threats currently visible on the battlefield.
var game: Node3D
var panel: PanelContainer
var label: Label
var elapsed := 0.0

func bind(owner: Node3D) -> void:
	game = owner

func _ready() -> void:
	panel = PanelContainer.new(); panel.position = Vector2(1430,545); panel.custom_minimum_size = Vector2(475,0)
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.04,0.08,0.12,0.91); style.border_color = Color("bd8e64")
	style.set_border_width_all(1); style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel",style); add_child(panel)
	label = Label.new(); label.add_theme_font_size_override("font_size",16)
	label.custom_minimum_size = Vector2(450,0); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color",Color("ffe4c4"))
	panel.add_child(label); panel.visible = false

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < 0.25 or game == null or game.mission == null: return
	elapsed = 0.0
	preload("res://scripts/enemy_presentation.gd").decorate(game)
	var rows: Array[String] = []
	var seen := {}
	for u in game.mission.living("enemy"):
		if not u.has("visual_tint") or not bool(u.awake) and not bool(u.spotted): continue
		if preload("res://scripts/enemy11_tactics.gd").hidden(game.mission,u): continue
		var kind := str(u.kind)
		if seen.has(kind): continue
		seen[kind] = true; rows.append("%s: %s" % [u.name,str(u.get("description",""))])
	panel.visible = not rows.is_empty()
	if panel.visible: label.text = "THREAT NOTES\n" + "\n".join(rows)
