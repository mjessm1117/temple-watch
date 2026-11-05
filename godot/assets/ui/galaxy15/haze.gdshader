shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float danger = 0.0;
uniform float phase = 0.0;
uniform sampler2D cloud_noise : filter_linear, repeat_enable;
void fragment() {
	vec2 centered = UV - 0.5;
	float radius = length(centered);
	float grain = texture(cloud_noise, UV * 1.4 + vec2(TIME * 0.002, phase)).r;
	float interior = 1.0 - smoothstep(0.27, 0.48, radius);
	float border = smoothstep(0.30, 0.39, radius) * (1.0 - smoothstep(0.46, 0.51, radius));
	ALBEDO = mix(vec3(0.24, 0.018, 0.045), vec3(0.68, 0.06, 0.075), border);
	ALPHA = danger * (interior * (0.12 + grain * 0.18) + border * 0.26);
}
