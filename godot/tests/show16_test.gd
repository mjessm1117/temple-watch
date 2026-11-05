extends SceneTree
const Jedi = preload("res://scripts/characters/jedi_models.gd")
const Portraits = preload("res://scripts/story14_portraits.gd")
const Campaign = preload("res://scripts/campaign/state.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func run() -> void:
	var hashes := {}
	for name in Jedi.NAMES:
		var id: String = Jedi.NAMES[name]
		var path := "res://assets/portraits/jedi/%s.png" % id
		check(ResourceLoader.exists(path), "named portrait exists: " + id)
		check(Portraits.texture(name) != null, "story portrait resolves: " + name)
		check(Jedi.scene_for_id(id, null) != null, "same named model exists: " + id)
		if FileAccess.file_exists(path): hashes[FileAccess.get_md5(path)] = true
	check(hashes.size() == 7, "seven distinct model portraits")
	check(Portraits.texture("Sgt. Rhal Dax") != null, "trooper portrait retained")
	check(Portraits.texture("Darth Malgus") != null, "villain portrait retained")
	var campaign := Campaign.new()
	var view := preload("res://scripts/campaign/temple_view.gd").new()
	root.add_child(view)
	view.setup(campaign.state)
	for frame in 5: await process_frame
	var occupants: Array = view.temple.find_children("Jedi_*", "Node3D", true, false)
	var active_named := 0
	for soldier in campaign.state.roster:
		if Jedi.id_for({"name":soldier.n}) != "": active_named += 1
	check(occupants.size() == active_named, "active named Jedi occupy built rooms")
	for occupant in occupants:
		check(occupant.get_meta("show16_jedi", "") != "", "room actor has named identity")
		check(view.rooms[occupant.get_parent().name].built, "Jedi stands in a built room")
	view.queue_free()
	print("SHOW16 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
