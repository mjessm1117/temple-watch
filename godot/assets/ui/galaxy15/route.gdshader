shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
void fragment() {
	float pulse = 0.72 + 0.28 * sin(TIME * 1.4 + UV.x * 18.0);
	ALBEDO = vec3(0.18, 0.65, 0.82) * pulse;
	ALPHA = 0.66;
}
