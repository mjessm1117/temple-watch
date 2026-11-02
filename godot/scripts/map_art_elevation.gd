extends RefCounted
## Data adapter: authored tier digits become the existing movement/LOS rule tiles.
## Intended call in MapCatalog.load_map, after plot/anchor routing and before data.rows.
static func apply(rows: Array[String], elevation: Array) -> void:
	for y in mini(rows.size(),elevation.size()):
		var tiers := str(elevation[y])
		for x in mini(rows[y].length(),tiers.length()):
			if rows[y][x] not in [".","^","M","r"]: continue
			var level := int(tiers[x])
			var tile := "M" if level == 2 else "^" if level == 1 else "."
			# Preserve low rubble; it remains passable with no cover.
			if level == 0 and rows[y][x] == "r": continue
			rows[y] = rows[y].substr(0,x)+tile+rows[y].substr(x+1)
