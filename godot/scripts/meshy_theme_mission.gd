extends "res://scripts/game.gd"
## Review-only launch hook: inject an unedited shipped mission before scene/UI setup.
var review_source: RefCounted

func _setup_scene() -> void:
	mission = review_source
	if mission.modern:
		pivot = Vector3(float(mission.spec.width)*0.5,0,float(mission.spec.height)*0.5)
		zoom = maxf(float(mission.spec.width),float(mission.spec.height))*1.3
	super._setup_scene()

func _process(_delta: float) -> void:
	# Idle review retains label layout; unattended windows must not edge-pan on OS input.
	if mission != null: scene_view.arrange_labels()
