extends RefCounted
## Optional class ability effects; legacy definitions keep their original execution.
const ENEMY_TAGS = ["MARKED", "EXPOSED", "STAGGERED", "LIFTED", "PINNED", "IONIZED", "BURNING", "TAUNTED"]
const ALLY_TAGS = ["INSPIRED", "SHIELDED", "ATTUNED", "READY"]

static func tags(unit: Dictionary) -> Dictionary:
	return unit.get("combo_tags", {})

static func has_tag(unit: Dictionary, tag: String) -> bool:
	return tags(unit).has(tag)

static func consume(m: RefCounted, unit: Dictionary, tag: String, preserve: bool = false) -> bool:
	var held := tags(unit)
	if not held.has(tag): return false
	if not preserve: held.erase(tag)
	unit.combo_tags = held
	if tag == "LIFTED" and not preserve: m.apply_damage(unit, 2)
	if str(m.phase) == "player": m.chain_momentum = mini(3, int(m.chain_momentum) + 1)
	return true

static func apply_tag(unit: Dictionary, tag: String, source: int = -1, amount: int = 0) -> bool:
	if tag not in ENEMY_TAGS and tag not in ALLY_TAGS: return false
	var held := tags(unit)
	# A new application refreshes the source without stacking duplicate tags.
	held[tag] = source
	unit.combo_tags = held
	if tag == "IONIZED":
		unit.shield = 0
		if bool(unit.get("droid", false)): unit.stunned = true
	if tag == "SHIELDED": unit.shield = int(unit.get("shield", 0)) + maxi(1, amount)
	if tag == "INSPIRED": unit.erase("panicked")
	return true

static func resolve(m: RefCounted, actor: Dictionary, target: Dictionary, tile: Vector2i, def: Dictionary) -> void:
	var chain: Dictionary = def.get("chain", {})
	var target_before: Dictionary = tags(target).duplicate() if not target.is_empty() else {}
	for entry in chain.get("consume", []):
		var tag := str(entry.get("tag", "")) if entry is Dictionary else str(entry)
		for recipient in _recipients(m, actor, target, tile, entry.get("target", "target") if entry is Dictionary else "target"):
			if recipient == target and not target_before.has(tag): continue
			if consume(m, recipient, tag, bool(entry.get("preserve", false)) if entry is Dictionary else false):
				for bonus in entry.get("bonus", []) if entry is Dictionary else []: _effect(m, actor, recipient, tile, bonus)
	for entry in chain.get("apply", []):
		var tag := str(entry.get("tag", "")) if entry is Dictionary else str(entry)
		for recipient in _recipients(m, actor, target, tile, entry.get("target", "target") if entry is Dictionary else "target"):
			apply_tag(recipient, tag, int(actor.get("id", -1)), int(entry.get("amount", 0)) if entry is Dictionary else 0)
	for effect in def.get("effects", []): _effect(m, actor, target, tile, effect)

static func _recipients(m: RefCounted, actor: Dictionary, target: Dictionary, tile: Vector2i, scope: String) -> Array:
	if scope == "self": return [actor]
	if scope == "target": return [] if target.is_empty() else [target]
	var allies := scope.ends_with("allies")
	var out := []
	for unit in m.units:
		if int(unit.get("hp", 0)) <= 0: continue
		if str(unit.get("side", "")) != (str(actor.get("side", "")) if allies else "enemy" if str(actor.get("side", "")) == "player" else "player"): continue
		if scope.begins_with("area_") and Vector2i(int(unit.x), int(unit.y)).distance_to(tile) > 1.5: continue
		out.append(unit)
	return out

static func _effect(m: RefCounted, actor: Dictionary, target: Dictionary, _tile: Vector2i, effect: Dictionary) -> void:
	for recipient in _recipients(m, actor, target, _tile, str(effect.get("target", "target"))):
		_effect_one(m, actor, recipient, effect)

static func _effect_one(m: RefCounted, actor: Dictionary, recipient: Dictionary, effect: Dictionary) -> void:
	match str(effect.get("type", "")):
		"tag": apply_tag(recipient, str(effect.get("tag", "")), int(actor.get("id", -1)), int(effect.get("amount", 0)))
		"damage": m.apply_damage(recipient, int(effect.get("amount", 0)), actor)
		"heal": recipient.hp = mini(int(recipient.get("max_hp", 0)), int(recipient.get("hp", 0)) + int(effect.get("amount", 0)))
		"shield": recipient.shield = int(recipient.get("shield", 0)) + int(effect.get("amount", 0))
		"focus": recipient.focus_left = mini(int(recipient.get("focus", 0)), int(recipient.get("focus_left", 0)) + int(effect.get("amount", 0)))
		"action": recipient.ap = int(recipient.get("ap", 0)) + int(effect.get("amount", 0))
		"status": recipient[str(effect.get("status", ""))] = true
		_: preload("res://scripts/effects_jedi.gd").apply(m, actor, recipient, effect)

static func damage_amount(m: RefCounted, target: Dictionary, amount: int, source: Dictionary) -> int:
	if has_tag(target, "LIFTED"): amount = ceili(float(amount) * 1.5)
	if has_tag(target, "IONIZED") and not source.is_empty():
		var def: Dictionary = m.abilities.get(str(source.get("active_ability", "")), {})
		if str(def.get("effect", "")) == "blast" or bool(def.get("tech", false)): amount *= 2
	if has_tag(target, "BURNING") and not source.is_empty():
		var def: Dictionary = m.abilities.get(str(source.get("active_ability", "")), {})
		if str(def.get("effect", "")) == "blast":
			for other in m.units:
				if other != target and int(other.get("hp", 0)) > 0 and Vector2i(int(other.x), int(other.y)).distance_to(Vector2i(int(target.x), int(target.y))) <= 1.5:
					apply_tag(other, "BURNING", int(source.get("id", -1)))
	return amount

static func claim_momentum_strike(m: RefCounted, actor: Dictionary) -> bool:
	if str(m.phase) != "player" or str(actor.get("side", "")) != "player" or int(actor.get("hp", 0)) <= 0: return false
	if int(m.chain_momentum) < 3 or int(m.chain_strike_used_turn) == int(m.turn): return false
	m.chain_momentum = 0
	m.chain_strike_used_turn = int(m.turn)
	actor.ap = int(actor.get("ap", 0)) + 1
	return true
