shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float danger = 0.0;
uniform float phase = 0.0;
uniform sampler2D cloud_noise : filter_linear, repeat_enable;
void fragment() {
	vec2 centered = UV - 0.5;
	float radius = length(centered);
	float grain = texture(cloud_noise, UV * 1.4 + vec2(TIME * 0.002, phase)).r;
	float feather = 1.0 - smoothstep(0.25, 0.51, radius);
	float cloud = smoothstep(0.22, 0.76, grain);
	float rim = smoothstep(0.27, 0.38, radius) * (1.0 - smoothstep(0.39, 0.51, radius));
	ALBEDO = mix(vec3(0.34, 0.035, 0.065), vec3(0.62, 0.09, 0.10), cloud * 0.55 + rim * 0.20);
	ALPHA = danger * feather * (0.22 + cloud * 0.22 + rim * 0.08);
}
