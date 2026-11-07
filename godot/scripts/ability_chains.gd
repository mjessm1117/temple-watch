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
	if str(m.phase) == "player": m.chain_momentum = mini(3, int(m.chain_momentum) + 1)
	return true

static func apply_tag(unit: Dictionary, tag: String, source: int = -1) -> bool:
	if tag not in ENEMY_TAGS and tag not in ALLY_TAGS: return false
	var held := tags(unit)
	# A new application refreshes the source without stacking duplicate tags.
	held[tag] = source
	unit.combo_tags = held
	return true

static func resolve(m: RefCounted, actor: Dictionary, target: Dictionary, tile: Vector2i, def: Dictionary) -> void:
	var chain: Dictionary = def.get("chain", {})
	var target_before: Dictionary = tags(target).duplicate() if not target.is_empty() else {}
	for entry in chain.get("consume", []):
		var tag := str(entry.get("tag", "")) if entry is Dictionary else str(entry)
		var recipient := actor if entry is Dictionary and str(entry.get("target", "target")) == "self" else target
		if recipient.is_empty(): continue
		if recipient == target and not target_before.has(tag): continue
		if consume(m, recipient, tag, bool(entry.get("preserve", false)) if entry is Dictionary else false):
			for bonus in entry.get("bonus", []) if entry is Dictionary else []: _effect(m, actor, recipient, tile, bonus)
	for entry in chain.get("apply", []):
		var tag := str(entry.get("tag", "")) if entry is Dictionary else str(entry)
		var recipient := actor if entry is Dictionary and str(entry.get("target", "target")) == "self" else target
		if not recipient.is_empty(): apply_tag(recipient, tag, int(actor.get("id", -1)))
	for effect in def.get("effects", []): _effect(m, actor, target, tile, effect)

static func _effect(m: RefCounted, actor: Dictionary, target: Dictionary, _tile: Vector2i, effect: Dictionary) -> void:
	var recipient := actor if str(effect.get("target", "target")) == "self" else target
	if recipient.is_empty(): return
	match str(effect.get("type", "")):
		"tag": apply_tag(recipient, str(effect.get("tag", "")), int(actor.get("id", -1)))
		"damage": m.apply_damage(recipient, int(effect.get("amount", 0)), actor)
		"heal": recipient.hp = mini(int(recipient.get("max_hp", 0)), int(recipient.get("hp", 0)) + int(effect.get("amount", 0)))
		"shield": recipient.shield = int(recipient.get("shield", 0)) + int(effect.get("amount", 0))
		"focus": recipient.focus_left = mini(int(recipient.get("focus", 0)), int(recipient.get("focus_left", 0)) + int(effect.get("amount", 0)))
		"action": recipient.ap = int(recipient.get("ap", 0)) + int(effect.get("amount", 0))
		"status": recipient[str(effect.get("status", ""))] = true

static func claim_momentum_strike(m: RefCounted, actor: Dictionary) -> bool:
	if str(m.phase) != "player" or str(actor.get("side", "")) != "player" or int(actor.get("hp", 0)) <= 0: return false
	if int(m.chain_momentum) < 3 or int(m.chain_strike_used_turn) == int(m.turn): return false
	m.chain_momentum = 0
	m.chain_strike_used_turn = int(m.turn)
	actor.ap = int(actor.get("ap", 0)) + 1
	return true
