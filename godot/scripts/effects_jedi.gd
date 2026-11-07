extends RefCounted
## Conditional Jedi effects that the shared consume/apply data cannot express.
const TAGS := ["MARKED", "EXPOSED", "STAGGERED", "LIFTED", "PINNED", "IONIZED", "BURNING", "TAUNTED", "INSPIRED", "SHIELDED", "ATTUNED", "READY"]

static func apply(m: RefCounted, actor: Dictionary, recipient: Dictionary, effect: Dictionary) -> void:
	match str(effect.get("type", "")):
		"kill_refund":
			if int(recipient.get("hp", 0)) > 0 or int(actor.get("jedi_kill_refund_turn", -1)) == int(m.turn): return
			actor.ap = int(actor.get("ap", 0)) + int(effect.get("amount", 1))
			actor.jedi_kill_refund_turn = int(m.turn)
		"stance_switch":
			var form := "force_adept" if str(actor.get("jedi_form", "shii_cho")) == "shii_cho" else "shii_cho"
			actor.jedi_form = form
			actor.buff_aim = int(effect.get("amount", 0)) if form == "force_adept" else 0
			actor.buff_defense = int(effect.get("amount", 0)) if form == "shii_cho" else 0
			actor.buff_until = int(m.turn) + 1
		"adaptive_consume":
			var chains = load("res://scripts/ability_chains.gd")
			for tag in TAGS:
				if not chains.has_tag(recipient, tag): continue
				chains.consume(m, recipient, tag)
				if int(recipient.get("hp", 0)) > 0: m.apply_damage(recipient, int(effect.get("amount", 0)), actor)
				break
			chains.apply_tag(recipient, str(effect.get("apply", "STAGGERED")), int(actor.get("id", -1)))
		"cleanse":
			for key in ["stunned", "disarmed", "rooted", "suppressed", "panicked", "burning"]:
				recipient.erase(key)
				recipient.erase(key + "_until")
			var held: Dictionary = recipient.get("combo_tags", {})
			for tag in ["BURNING", "IONIZED", "PINNED", "STAGGERED"]: held.erase(tag)
			recipient.combo_tags = held
		"reveal":
			recipient.spotted = true
			recipient.detected = true
			recipient.awake = true
		"aim_boost":
			recipient.buff_aim = int(recipient.get("buff_aim", 0)) + int(effect.get("amount", 0))
			recipient.buff_until = int(m.turn) + 1
		"defense_boost":
			recipient.buff_defense = int(recipient.get("buff_defense", 0)) + int(effect.get("amount", 0))
			recipient.buff_until = int(m.turn) + 1
		"disarm":
			recipient.disarmed = true
			recipient.disarmed_until = int(m.turn) + 1
			recipient.overwatch = false
		"hold":
			recipient.rooted = true
			recipient.rooted_until = int(m.turn) + 1
			recipient.ap = 0
		"guard_counter":
			actor.guard = true
			actor.guard_until = int(m.turn) + 1
			actor.overwatch = true
		"jump_strikes":
			var current: Dictionary = recipient
			var hit: Dictionary = {}
			if int(current.get("hp", 0)) <= 0:
				var fallen: Dictionary = current
				current = {}
				var nearest := INF
				for enemy in m.living("enemy"):
					var distance := Vector2(int(enemy.x) - int(fallen.x), int(enemy.y) - int(fallen.y)).length()
					if distance <= float(effect.get("range", 4)) and distance < nearest:
						nearest = distance
						current = enemy
			for i in range(int(effect.get("jumps", 3))):
				if current.is_empty() or int(current.get("hp", 0)) <= 0: break
				hit[int(current.id)] = true
				m.apply_damage(current, int(effect.get("amount", 0)) + i * 2, actor)
				if int(current.get("hp", 0)) > 0: break
				var next: Dictionary = {}
				var best := INF
				for enemy in m.living("enemy"):
					if hit.has(int(enemy.id)): continue
					var distance := Vector2(int(enemy.x) - int(current.x), int(enemy.y) - int(current.y)).length()
					if distance <= float(effect.get("range", 4)) and distance < best:
						best = distance
						next = enemy
				current = next
