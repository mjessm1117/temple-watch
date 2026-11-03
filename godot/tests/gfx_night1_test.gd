extends "res://scripts/map_preview.gd"
## Night 1 contract: theme coverage, tier safety, unit rims, capped marks.
const Presets = preload("res://scripts/gfx_theme_presets.gd")
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	var graphics := root.get_node("Graphics")
	var tier: String = graphics.requested
	var seen := {}
	for id in ["fixture","ilum","h_grove","web_rooftop_chase","sabotage","h_husks","cache","thul"]:
		await show_battle(id)
		for i in 4: await process_frame
		graphics.apply_all()
		for i in 2: await process_frame
		var theme: String = str(game.mission.spec.get("theme","temple"))
		seen[theme] = true
		check(Presets.PRESETS.has(theme),"preset for "+theme)
		var env: Environment = game.scene_view.world.environment
		var preset: Dictionary = Presets.get_preset(theme)
		check(env.fog_light_color.is_equal_approx(Color(preset.fog)),"fog color "+theme)
		check(game.scene_view.sun.light_color.is_equal_approx(Color(preset.sun)),"sun color "+theme)
		check(env.ssao_enabled == (graphics.effective == "high"),"SSAO "+theme)
		check(env.glow_enabled == (graphics.effective != "low"),"glow "+theme)
		check(not env.volumetric_fog_enabled,"height fog path "+theme)
		check(env.fog_enabled == (graphics.effective != "low"),"fog tier "+theme)
		check(game.scene_view.sun.shadow_enabled == (graphics.effective != "low"),"shadows "+theme)
		for unit in game.views.values():
			var meshes: Array[Node] = unit.model.find_children("*","MeshInstance3D",true,false)
			check(not meshes.is_empty(),"unit mesh "+theme)
			for mesh in meshes:
				check(mesh.material_overlay is ShaderMaterial,"unit rim "+theme)
			var marker: Node3D = unit.get_node_or_null("GfxSelectionRing")
			check(marker != null and marker.visible == (unit.unit_id == game.selected_id),"selection ring "+theme)
		if id == "cache":
			game.cinematic = true
			await process_frame
			check((game.camera.attributes != null and game.camera.attributes.dof_blur_far_enabled) == (graphics.effective == "high"),"cinematic depth of field")
			game.cinematic = false
			await process_frame
			check(game.camera.attributes == null or not game.camera.attributes.dof_blur_far_enabled,"normal camera stays sharp")
			for i in 40: game.fx._scorch(Vector3(5,1,5))
			check(game.fx._scorches.size() <= (12 if graphics.effective == "low" else 24),"scorch cap")
			game.mission.turn += 3
			await process_frame
			check(game.fx._scorches.is_empty(),"scorch fades after turns")
			for target in ["high","low","medium",tier]:
				check(graphics.select_tier(target,false) == OK,"switch "+target)
				check(game.scene_view.world.environment.ssao_enabled == (graphics.effective == "high"),"switch SSAO "+target)
				check(game.scene_view.world.environment.glow_enabled == (graphics.effective != "low"),"switch glow "+target)
		game.queue_free()
		await process_frame
	check(seen.size() == 8,"eight distinct themes")
	print("gfx_night1 %s: %d checks, %d failures" % [tier,checks,failures])
	quit(1 if failures else 0)
