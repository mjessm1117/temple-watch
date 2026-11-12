extends RefCounted
## Authored plots + parcels. Every campaign id is explicit; missing ids never borrow rescue.
const Validator = preload("res://scripts/map_validator.gd")
const Layout29 = preload("res://scripts/w29c_layout.gd")

static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

static func manifest() -> Dictionary:
	return read("res://data/maps/manifest.json")

static func resolve(id: String) -> String:
	return str(manifest().get("missions", {}).get(id, {}).get("path", ""))

static func layouts(id: String) -> Array[String]:
	var out: Array[String] = []
	var path := resolve(id)
	if path == "": return out
	out.append(path)
	for variant in manifest().web_variants:
		if read(str(variant)).get("web_source",{}).get("base","") == id: out.append(str(variant))
	return out

static func select_layout(id: String, seed_value: int, variant: int = -1) -> String:
	var pool := layouts(id)
	if pool.is_empty(): return ""
	return pool[posmod(seed_value if variant < 0 else variant,pool.size())]

static func load_map(path: String, seed_value: int = 1, retry_count: int = 0) -> Dictionary:
	var data := read(path)
	if not data.has("plot"): return data
	var parcels := read("res://data/maps/parcels.json")
	if bool(data.get("procedural",false)): data = Layout29.transform(data,seed_value+retry_count*1009,parcels)
	var plot: Dictionary = data.plot
	data.width = int(plot.width); data.height = int(plot.height)
	data.prop_overrides = {}
	var rows: Array[String] = []
	for y in range(data.height): rows.append("#".repeat(data.width) if y in [0, data.height-1] else "#" + ".".repeat(data.width-2) + "#")
	for placement in plot.placements:
		var chunk: Array = parcels[placement.parcel].duplicate()
		if bool(placement.get("mirror",false)): chunk = Layout29.mirror(chunk)
		for rotation in int(placement.get("rotate", 0)):
			var rotated: Array = []
			for x in str(chunk[0]).length():
				var line := ""
				for y in range(chunk.size()-1, -1, -1): line += str(chunk[y])[x]
				rotated.append(line)
			chunk = rotated
		stamp(rows, chunk, point(placement.at))
	if plot.has("source_rows"):
		var source: Array = []
		for row in plot.source_rows:
			var line := ""
			for c in str(row): line += c if c in ".#chk^Mrw" else "#" if c == "B" else "c" if c == "x" else "."
			source.append(line)
		stamp(rows, source, point(plot.source_at))
		for y in plot.source_rows.size():
			for x in str(plot.source_rows[y]).length():
				if str(plot.source_rows[y])[x] == "x": data.prop_overrides[Vector2i(x,y)+point(plot.source_at)] = "barrel"
	# Three-wide routes and plazas are plot-owned; parcels cannot close them.
	for x in plot.lanes:
		for y in range(1, data.height-1):
			for dx in [-1, 0, 1]: clear_floor(rows, Vector2i(int(x)+dx,y))
	for y in plot.crossings:
		for x in range(1, data.width-1):
			for dy in [-1, 0, 1]: clear_floor(rows,Vector2i(x,int(y)+dy))
	# Plot sockets guarantee high/low flanks and cover in all four quarters.
	for x in [7, data.width-8]:
		for y in [7, data.height-8]:
			put(rows,Vector2i(x,y),"#")
			put(rows,Vector2i(x,y+2),"c")
	for x in [2,data.width-3]:
		for y in [7,8,9]: put(rows,Vector2i(x,y),"M" if y == 8 else "^")
	var anchors: Array = data.objective.points + data.entries + data.evac
	if data.family == "retaliation": anchors.append_array(data.objective.civilians)
	for u in data.squad: anchors.append([u[1], u[2]])
	for pod in data.groups:
		for u in pod: anchors.append([u[1], u[2]])
	anchors.append([data.prisoner.x, data.prisoner.y])
	for at in anchors:
		var p := point(at)
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var q := p + Vector2i(dx, dy)
				if q.x > 0 and q.y > 0 and q.x < data.width-1 and q.y < data.height-1: clear_floor(rows,q)
	# Web cell doors / single-tile passages are adapted into open connections.
	for attempt in 8:
		var graph := Validator.topology(rows)
		if graph.cuts.is_empty() and graph.components == 1: break
		var open: Array = graph.cuts + graph.isolated
		for p in open:
			for dy in [-1,0,1]:
				for dx in [-1,0,1]:
					var q: Vector2i = p + Vector2i(dx,dy)
					if q.x > 0 and q.y > 0 and q.x < data.width-1 and q.y < data.height-1: put(rows,q,".")
	for x in [2,data.width-3]:
		for y in [6,data.height-6]: put(rows,Vector2i(x,y),"c")
	for at in data.evac: put(rows, point(at), "E")
	preload("res://scripts/map_art_elevation.gd").apply(rows, data.get("elevation", []))
	if bool(data.get("procedural",false)): Layout29.ensure_start_cover(rows,data)
	data.rows = rows
	if bool(data.get("procedural",false)):
		data.layout29.validation = Layout29.validate(data)
		if not bool(data.layout29.validation.ok) and retry_count < 8: return load_map(path,seed_value,retry_count+1)
		assert(bool(data.layout29.validation.ok),"Procedural map has no valid route: %s" % path)
	return data

static func point(at: Array) -> Vector2i:
	return Vector2i(int(at[0]), int(at[1]))

static func put(rows: Array[String], p: Vector2i, tile: String) -> void:
	if p.y < 0 or p.y >= rows.size() or p.x < 0 or p.x >= rows[p.y].length(): return
	rows[p.y] = rows[p.y].substr(0,p.x) + tile + rows[p.y].substr(p.x+1)

static func stamp(rows: Array[String], chunk: Array, at: Vector2i) -> void:
	for y in chunk.size():
		for x in str(chunk[y]).length(): put(rows, at + Vector2i(x,y), str(chunk[y])[x])

static func clear_floor(rows: Array[String], p: Vector2i) -> void:
	if p.y >= 0 and p.y < rows.size() and p.x >= 0 and p.x < rows[p.y].length() and rows[p.y][p.x] not in ["^","M"]: put(rows,p,".")
