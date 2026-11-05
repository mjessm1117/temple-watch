extends Control
## Batched phone names; empty bays keep their outline and remain in the Rooms drawer.
const SHORT := {"council":"COUNCIL", "war":"WAR RM", "archives":"ARCH", "armory":"ARM", "comms":"COMMS", "gardens":"GARDEN", "training":"TRAIN", "barracks":"BARR", "medical":"MED", "forge":"FORGE", "hangar":"HGR", "works":"WORKS", "under":"UNDER", "u0":"VAULT", "u1":"HOLOCRON", "u2":"MEMORIAL", "sp0":"FIRST", "sp1":"REASSURE", "sp2":"RECONCILE", "sp3":"GUIDANCE"}
const FONT_SIZE := 16
var buttons: Dictionary
var rooms: Dictionary
var labels: Array[Dictionary] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func layout() -> void:
    labels.clear()
    if buttons == null or rooms == null: return
    var font := ThemeDB.fallback_font
    for id in buttons:
        var button: Button = buttons[id]
        if not button.visible or not bool(rooms[id].built): continue
        var title: String = SHORT.get(id, str(rooms[id].name).to_upper())
        var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
        var height := font.get_height(FONT_SIZE)
        var area := Rect2(Vector2(button.position.x + (button.size.x - width) * 0.5 - 3.0, button.position.y + button.size.y - height - 3.0), Vector2(width + 6.0, height + 2.0))
        var conflict := false
        for row in labels:
            if area.intersects(row.area.grow(1.0)): conflict = true
        if conflict: continue
        labels.append({"id":id, "title":title, "area":area, "height":height, "color":button.get_node("RoomName").get_theme_color("font_color")})
    queue_redraw()

func _draw() -> void:
    var font := ThemeDB.fallback_font
    for row in labels:
        draw_rect(row.area, Color(0.018, 0.045, 0.057, 0.94))
        draw_string(font, row.area.position + Vector2(3, 1 + font.get_ascent(FONT_SIZE)), row.title, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, row.color)
