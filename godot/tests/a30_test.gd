extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("A30: " + label)

func run() -> void:
	var definitions := {}
	var signatures := {}
	var applied := {}
	var consumed := {}
	for side in ["jedi", "soldier"]:
		var directory := DirAccess.open("res://data/classes/" + side)
		check(directory != null, side + " class directory opens")
		if directory == null:
			continue
		var files := directory.get_files()
		files.sort()
		for file in files:
			if not file.ends_with(".json"):
				continue
			var path := "res://data/classes/%s/%s" % [side, file]
			var source := FileAccess.get_file_as_string(path)
			var row = JSON.parse_string(source)
			check(row is Dictionary, path + " parses")
			if not row is Dictionary:
				continue
			check(row.has("abilities") and row.abilities is Dictionary, path + " has abilities")
			if not row.has("abilities") or not row.abilities is Dictionary:
				continue
			for ability_id in row.abilities:
				var ability: Dictionary = row.abilities[ability_id]
				var label := "%s/%s" % [file, ability_id]
				var description := str(ability.get("description", ""))
				check(ability.has("description") and description.length() >= 10, label + " has a useful description")
				check(description.length() <= 60, label + " description is at most 60 characters")
				check(not description.contains("…"), label + " description is complete")
				check(ability.has("chain") and ability.get("chain") is Dictionary, label + " declares a chain")
				if not ability.get("chain") is Dictionary:
					continue
				var chain: Dictionary = ability.chain
				var mentioned := chain.is_empty()
				for kind in ["apply", "consume"]:
					for entry in chain.get(kind, []):
						var tag := str(entry.get("tag", ""))
						check(not tag.is_empty(), label + " has a named " + kind + " tag")
						if tag.is_empty():
							continue
						if kind == "apply":
							applied[tag] = true
							var scope := str(entry.get("target", "target"))
							var ally_scope := scope == "self" or scope.ends_with("allies") or (scope == "target" and str(ability.get("target", "")).begins_with("ally"))
							var enemy_scope := scope.ends_with("enemies") or (scope == "target" and str(ability.get("target", "")).begins_with("enemy"))
							check(not (ally_scope and tag in ["MARKED", "EXPOSED", "STAGGERED", "LIFTED", "PINNED", "IONIZED", "BURNING", "TAUNTED"]), label + " does not mark an ally with " + tag)
							check(not (enemy_scope and tag in ["INSPIRED", "SHIELDED", "ATTUNED", "READY"]), label + " does not buff an enemy with " + tag)
						else:
							consumed[tag] = true
						if description.to_upper().contains(tag):
							mentioned = true
				check(mentioned, label + " description names a chain tag")
				if definitions.has(ability_id):
					continue # Base abilities intentionally appear in several classes.
				definitions[ability_id] = true
				var signature := JSON.stringify([ability.get("damage", null), ability.get("ap", null), ability.get("chance", null), ability.get("target", null)])
				if not signatures.has(signature):
					signatures[signature] = []
				for previous in signatures[signature]:
					check(previous.chain != chain, "%s duplicates %s in damage/AP/chance/target and chain" % [ability_id, previous.id])
				signatures[signature].append({"id": ability_id, "chain": chain})
	for tag in applied:
		check(consumed.has(tag), tag + " has a consumer")
	check(definitions.size() == 241, "all 241 unique class abilities loaded")
	print("A30 TEST RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
