extends RefCounted
## Presentation routing only. No gameplay state or mission RNG is advanced.
static func cover_path(props: Dictionary, theme: String, kind: String) -> String:
	if not props.get("meshy1_enabled",false): return ""
	return str(props.get("meshy_themes",{}).get(theme,{}).get(kind,""))

static func objective_path(props: Dictionary, action: String) -> String:
	if not props.get("meshy1_enabled",false): return ""
	return str(props.get("meshy_objectives",{}).get(action,""))

static func action(props: Dictionary, family: String) -> String:
	return str(props.get("meshy_mission_actions",{}).get(family,""))

static func cover_angle(m: RefCounted, tile: Vector2i, horizontal: bool, vertical: bool) -> float:
	# Connected cover defines its direction in the tile map; isolated props vary by seed.
	if vertical and not horizontal: return PI/2
	if horizontal: return 0.0
	return float(posmod(hash([m.rng.seed,m.spec.get("name",""),tile]),4))*PI/2
