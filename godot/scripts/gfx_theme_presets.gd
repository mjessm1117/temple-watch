extends RefCounted
## Battle lighting in one table. Colors are linearized by Godot from HTML notation.
const PRESETS := {
	"temple": {"mood":"warm gold dusk","sun":"ffd19a","sun_angle":Vector3(-32,-55,0),"sun_power":1.35,"ambient":"8f7790","ambient_power":0.52,"fog":"73546a","fog_density":0.005,"height":0.018,"exposure":0.82,"glow":0.33},
	"snow": {"mood":"cold blue dawn","sun":"c7e1ff","sun_angle":Vector3(-24,42,0),"sun_power":1.20,"ambient":"829fc5","ambient_power":0.62,"fog":"8caeca","fog_density":0.004,"height":0.012,"exposure":0.86,"glow":0.28},
	"jungle": {"mood":"humid green haze","sun":"e3d8a2","sun_angle":Vector3(-49,-28,0),"sun_power":1.05,"ambient":"5d8067","ambient_power":0.56,"fog":"466e56","fog_density":0.009,"height":0.035,"exposure":0.94,"glow":0.30},
	"city": {"mood":"sodium night","sun":"ffa966","sun_angle":Vector3(-19,75,0),"sun_power":0.88,"ambient":"435877","ambient_power":0.50,"fog":"343f5b","fog_density":0.010,"height":0.026,"exposure":0.92,"glow":0.40},
	"dock": {"mood":"industrial blue hour","sun":"fbbf82","sun_angle":Vector3(-22,-68,0),"sun_power":1.05,"ambient":"59758a","ambient_power":0.54,"fog":"44576b","fog_density":0.007,"height":0.020,"exposure":0.88,"glow":0.36},
	"caves": {"mood":"cool subterranean glow","sun":"9ac5df","sun_angle":Vector3(-57,22,0),"sun_power":0.98,"ambient":"566d86","ambient_power":0.58,"fog":"425469","fog_density":0.007,"height":0.018,"exposure":0.94,"glow":0.34},
	"ruins": {"mood":"violet twilight","sun":"e5bca3","sun_angle":Vector3(-31,-73,0),"sun_power":1.10,"ambient":"77708e","ambient_power":0.55,"fog":"5e5977","fog_density":0.006,"height":0.022,"exposure":0.88,"glow":0.32},
	"plains": {"mood":"harsh dry noon","sun":"fff0c4","sun_angle":Vector3(-68,-25,0),"sun_power":1.32,"ambient":"a59a78","ambient_power":0.56,"fog":"a99777","fog_density":0.003,"height":0.010,"exposure":0.78,"glow":0.25},
}

static func get_preset(theme: String) -> Dictionary:
	return PRESETS.get(theme,PRESETS.temple)
