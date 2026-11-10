extends CanvasLayer
## One-line tactics for new threats currently visible on the battlefield.
const UI = preload("res://scripts/campaign/ui.gd")
var game: Node3D
var panel: PanelContainer
var label: Label
var elapsed := 0.0
var revealed_groups := {}
var reveal_text := ""
var reveal_until := 0

func bind(owner: Node3D) -> void:
	game = owner

func _ready() -> void:
	var screen: Vector2 = get_viewport().get_visible_rect().size
	var width := minf(475.0, screen.x - 24.0)
	panel = PanelContainer.new(); panel.position = Vector2(screen.x - width - 12.0, 12.0); panel.custom_minimum_size = Vector2(width,0)
	var style := StyleBoxFlat.new(); style.bg_color = Color(UI.PANEL, 0.94); style.border_color = UI.GOLD
	style.set_border_width_all(1); style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel",style); add_child(panel)
	label = Label.new(); label.add_theme_font_override("font", UI.font()); label.add_theme_font_size_override("font_size",UI.TYPE.body)
	label.custom_minimum_size = Vector2(width - 24.0,0); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color",UI.TEXT)
	panel.add_child(label); panel.visible = false

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < 0.25 or game == null or game.mission == null: return
	elapsed = 0.0
	preload("res://scripts/enemy_presentation.gd").decorate(game)
	var groups := {}
	for u in game.mission.living("enemy"):
		if int(u.get("group", -1)) < 0 or not bool(u.get("awake", false)) or not bool(u.get("spotted", false)): continue
		if not groups.has(int(u.group)): groups[int(u.group)] = []
		groups[int(u.group)].append(u)
	for group_id in groups:
		if revealed_groups.has(group_id): continue
		revealed_groups[group_id] = true
		show_reveal(game.mission, groups[group_id])
	var story: Dictionary = game.mission.objective_state
	if str(story.get("villain_status", "")) == "arriving":
		reveal_text = "%s · %s" % [str(story.get("villain_name", "Sith Lord")), str(story.get("villain_intro_line", ""))]
		reveal_until = Time.get_ticks_msec() + 3500
		preload("res://scripts/villain11_battle.gd").mark_present(game.mission)
	var rows: Array[String] = []
	var seen := {}
	for u in game.mission.living("enemy"):
		if not u.has("visual_tint") or not bool(u.awake) and not bool(u.spotted): continue
		if preload("res://scripts/enemy11_tactics.gd").hidden(game.mission,u): continue
		var kind := str(u.kind)
		if seen.has(kind): continue
		seen[kind] = true; rows.append("%s: %s" % [u.name,str(u.get("description",""))])
	panel.visible = not rows.is_empty() or Time.get_ticks_msec() < reveal_until
	if panel.visible: label.text = (reveal_text + "\n" if Time.get_ticks_msec() < reveal_until else "THREAT NOTES\n") + "\n".join(rows)

func show_reveal(mission: RefCounted, group: Array) -> void:
	var info: Dictionary = preload("res://scripts/mission_pressure.gd").reveal_info(mission, group)
	reveal_text = "%s · %s" % [info.title, info.threat_line]
	reveal_until = Time.get_ticks_msec() + 3500
	if label != null: label.text = reveal_text
