extends Button
## A 44 px touch target with a compact, drawn combo symbol.
var tag := ""
const GLYPHS := {"ATTUNED":"✦", "BURNING":"♨", "EXPOSED":"◇", "INSPIRED":"★", "IONIZED":"ϟ", "LIFTED":"↑", "MARKED":"⌖", "PINNED":"⊥", "READY":"➤", "SHIELDED":"⬡", "STAGGERED":"≈", "TAUNTED":"!"}
const COLORS := {"ATTUNED":"bca5ff", "BURNING":"ff7958", "EXPOSED":"ffe38a", "INSPIRED":"92eaa9", "IONIZED":"78dfff", "LIFTED":"c6afff", "MARKED":"ff7b91", "PINNED":"e4ad77", "READY":"9be7e3", "SHIELDED":"82b8ff", "STAGGERED":"ffc16e", "TAUNTED":"ff9dc1"}

static func marks(def: Dictionary) -> String:
	var out: Array[String] = []
	var chain: Dictionary = def.get("chain", {})
	for kind in ["consume", "apply"]:
		for entry in chain.get(kind, []):
			var tag := str(entry.get("tag", "")) if entry is Dictionary else str(entry)
			out.append(("−" if kind == "consume" else "+") + str(GLYPHS.get(tag, "•")))
	return " ".join(out)

func _ready() -> void:
	custom_minimum_size = Vector2(44, 44)
	focus_mode = Control.FOCUS_NONE
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _draw() -> void:
	var color := Color(COLORS.get(tag, "dcebf0"))
	var center := size * 0.5
	draw_circle(center, 13, Color("10212de6"))
	draw_arc(center, 13, 0, TAU, 24, color, 2)
	var glyph: String = GLYPHS.get(tag, tag)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, center + Vector2(-width * 0.5, 6), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
