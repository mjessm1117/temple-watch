extends SceneTree
## Verify the staged battle figures expose their original named clips in Godot.

func _initialize() -> void:
	for name in ["agent", "jedi", "scout", "sithHeavy", "trooper"]:
		var scene: PackedScene = load("res://assets/models_v2/%s_v2.glb" % name)
		var node: Node = scene.instantiate()
		var player := _find_player(node)
		var clips := player.get_animation_list() if player else PackedStringArray()
		print("BLENDER2 ANIMATIONS ", name, " ", clips.size(), " ", clips.has("idle"), " ", clips.has("gunIdle"))
		node.free()
	quit()

func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := _find_player(child)
		if found: return found
	return null
