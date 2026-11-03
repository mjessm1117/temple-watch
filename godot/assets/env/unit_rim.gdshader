shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;
uniform vec4 rim_color : source_color = vec4(0.4, 0.8, 1.0, 0.35);

void fragment() {
	float edge = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.2);
	ALBEDO = rim_color.rgb;
	EMISSION = rim_color.rgb * edge;
	ALPHA = edge * rim_color.a;
}
