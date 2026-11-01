shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float arms = pow(0.5 + 0.5 * sin(a * 3.0 - r * 15.0), 4.0);
	float wisps = 0.6 + 0.4 * sin(p.x * 32.0 + sin(p.y * 26.0));
	float cloud = exp(-r * 3.3) * (0.12 + arms * 0.65 * wisps);
	vec3 col = mix(vec3(0.15, 0.29, 0.48), vec3(0.28, 0.6, 0.65), arms);
	ALBEDO = col * cloud + vec3(0.55, 0.65, 0.76) * exp(-r * 23.0) * 0.6;
	ALPHA = smoothstep(1.0, 0.7, r);
}
