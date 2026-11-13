extends SceneTree

const Impact31 = preload("res://scripts/w31c_impact.gd")
const Trail31 = preload("res://scripts/w31c_trail.gd")
const Presentation = preload("res://scripts/enemy_presentation.gd")
const Signature = preload("res://scripts/w27d_ability_signature.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)

func run() -> void:
	check(Impact31.new().has_method("apply_hit_shake") and Impact31.new().has_method("enlarge_contact_flash"), "impact helper exports both functions")
	check(Trail31.new().has_method("spawn_trail_ghost") and Trail31.new().has_method("clear_trail_ghosts"), "trail helper exports both functions")
	var camera := Camera3D.new()
	root.add_child(camera)
	Impact31.apply_hit_shake(camera, 2.0, 50)
	check(camera.has_meta("w31c_shake_active") and bool(camera.get_meta("w31c_shake_active")), "hit shake active on camera")
	for i in 4: await process_frame
	check(not camera.has_meta("w31c_shake_active") and camera.position.length() < 0.001, "shake returns camera within three frames")
	check(Presentation.kill_hold_ms >= 300, "kill hold lasts 300 ms")
	var sprite := Node3D.new()
	root.add_child(sprite)
	var mesh := MeshInstance3D.new()
	mesh.mesh = CapsuleMesh.new()
	sprite.add_child(mesh)
	var before := get_nodes_in_group("w31c_trail_ghosts").size()
	var ghost := Trail31.spawn_trail_ghost(self, Vector3(2, 0, 3), sprite)
	check(ghost != null and ghost.is_inside_tree() and get_nodes_in_group("w31c_trail_ghosts").size() == before + 1, "trail creates a scene node")
	Trail31.clear_trail_ghosts(self)
	await process_frame
	check(get_nodes_in_group("w31c_trail_ghosts").is_empty(), "trail clears on turn end")
	var anchor := Node3D.new()
	root.add_child(anchor)
	var flash := Impact31.enlarge_contact_flash(anchor, 2.5)
	check(flash != null and flash.scale.x >= 2.5, "contact flash scales for tactical zoom")
	check(Signature.new().has_method("chain_result_pulse"), "chain has a result pulse function")
	var pulse := Signature.chain_result_pulse(anchor, Vector3.ZERO)
	check(pulse != null and pulse.name == "W31CChainResultPulse" and pulse.mesh is TorusMesh, "chain result makes a separate ring")
	print("IMPACT31 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
