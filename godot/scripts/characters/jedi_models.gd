extends RefCounted
## Named Jedi battle models. The existing generic Jedi is the safe fallback.

const ROOT := "res://assets/characters/jedi/"
const NAMES := {
	"Kira Venn": "kira",
	"Tor Saalen": "tor",
	"Satele Shan": "satele",
	"Lord Ressa Vaun": "ressa",
	"Kell Darrow": "kell",
	"Knight Sava Orrin": "sava",
	"Tem Ruhl": "tem",
}

static func id_for(unit: Dictionary) -> String:
	return str(NAMES.get(str(unit.get("name", "")), ""))

static func scene_for(unit: Dictionary, fallback: PackedScene) -> PackedScene:
	if str(unit.get("model", "")) != "jedi": return fallback
	return scene_for_id(id_for(unit), fallback)

static func scene_for_id(id: String, fallback: PackedScene) -> PackedScene:
	if id.is_empty(): return fallback
	var path := ROOT + id + "/" + id + ".glb"
	if not ResourceLoader.exists(path): return fallback
	var scene := load(path) as PackedScene
	return scene if scene != null else fallback

static func configure_animation(player: AnimationPlayer) -> void:
	if player == null: return
	for clip in ["idle", "saberIdle", "gunIdle", "run", "walk", "channel", "aim"]:
		if player.has_animation(clip): player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	for idle in ["idle", "saberIdle", "gunIdle"]:
		if not player.has_animation(idle): continue
		for action in ["run", "walk", "swing", "cast", "shoot", "hit", "block", "throw"]:
			if not player.has_animation(action): continue
			player.set_blend_time(idle, action, 0.16 if action in ["run", "walk"] else 0.09)
			player.set_blend_time(action, idle, 0.2 if action in ["run", "walk"] else 0.14)
