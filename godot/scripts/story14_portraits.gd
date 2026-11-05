extends RefCounted
## Names map to baked unit-model portraits. Unknown speakers use the Council portrait.

const NAMES := {
	"Kira Venn":"kira", "Tor Saalen":"tor", "Sgt. Rhal Dax":"rhal", "Ilsa Myr":"ilsa",
	"Doc Bren":"bren", "Grak Ordo":"grak", "Satele Shan":"satele", "Jace Malcom":"jace",
	"Varra Ordo":"varra", "Darth Malgus":"malgus", "Lord Kaan":"kaan", "Darth Bane":"bane",
	"Lord Ressa Vaun":"ressa", "Kell Darrow":"kell", "Sgt. Bo Hallan":"bo", "Mira Tesk":"mira",
	"Doc Ilo Venn":"ilo", "Rusk Abernath":"rusk", "Knight Sava Orrin":"sava", "Tem Ruhl":"tem",
	"Sgt. Dace Morrow":"dace", "Kiri Vass":"kiri", "Doc Halden Pree":"halden", "Bruk Tannar":"bruk",
	"Marchion Ro":"ro", "Jedi Council":"council"
}

static func texture(name: String) -> Texture2D:
	var key: String = NAMES.get(name,"council")
	if key in ["kira", "tor", "satele", "ressa", "kell", "sava", "tem"]:
		var jedi_path := "res://assets/portraits/jedi/%s.png" % key
		if ResourceLoader.exists(jedi_path): return load(jedi_path)
	var path := "res://assets/story/portraits14/%s.png" % key
	return load(path) if ResourceLoader.exists(path) else null

static func picture(name: String, dimensions: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture(name)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	node.custom_minimum_size = dimensions
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
