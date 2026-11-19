extends Control
## Give the existing world and edge objective cue its full rescue name.
const Objectives = preload("res://scripts/mission_objectives.gd")

var game: Node3D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_priority = 100
	set_process(true)

func _process(_delta: float) -> void:
	if not is_instance_valid(game) or game.mission == null or not Objectives.mira_rescue(game.mission): return
	var cue: Control = game.overlay.get_node_or_null("ObjectiveCue36")
	if cue == null or bool(game.mission.prisoner.get("freed", false)): return
	var label: Label3D = cue.get("world_label")
	if label != null: label.text = "MIRA TAL"
	var value: Dictionary = cue.get("cue")
	if not value.is_empty() and str(value.get("title", "")) != "MIRA TAL":
		value.title = "MIRA TAL"
		cue.set("cue", value)
		cue.queue_redraw()
