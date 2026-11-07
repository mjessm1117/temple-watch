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
