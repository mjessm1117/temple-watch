extends RefCounted
## One bounded visual motif and one synthesized sound for each common ability.

const PROFILES := {
	"rapidFire": {"shape":"triple", "sound":"rapid_fire", "spacing":0.075},
	"suppress": {"shape":"fan", "sound":"suppress", "spacing":0.10},
	"push": {"shape":"cone", "sound":"force_push", "spacing":0.12},
	"pull": {"shape":"inward", "sound":"force_pull", "spacing":0.14},
	"forceHeal": {"shape":"cross", "sound":"force_heal", "spacing":0.16},
	"barrier": {"shape":"hex", "sound":"barrier", "spacing":0.18},
	"saberThrow": {"shape":"arc", "sound":"saber_throw", "spacing":0.17},
	"grenade": {"shape":"burst", "sound":"grenade", "spacing":0.19},
}

static func profile(id: String) -> Dictionary:
	return PROFILES.get(id, {})

static func budget() -> Dictionary:
	return {"draws_per_beat": 4, "particles_max": 12}
