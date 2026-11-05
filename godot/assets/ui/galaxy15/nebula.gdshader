shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform sampler2D cloud_noise : filter_linear, repeat_enable;
uniform bool low_mode = false;
uniform float layer_alpha = 1.0;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float radius = length(p);
	float angle = atan(p.y, p.x);
	float grain = texture(cloud_noise, UV * 2.2 + vec2(TIME * 0.0003)).r;
	float detail = texture(cloud_noise, UV * 6.4).r;
	if (!low_mode) detail = mix(detail, texture(cloud_noise, UV * 11.0).r, 0.35);
	float arms = pow(0.5 + 0.5 * sin(angle * 4.0 - radius * 17.0 + grain * 2.4), 3.0);
	float lane = 1.0 - smoothstep(0.39, 0.54, detail);
	float cloud = arms * (0.38 + grain * 0.62) * (1.0 - lane * 0.58);
	cloud *= smoothstep(1.0, 0.25, radius) * smoothstep(0.045, 0.2, radius);
	float core = exp(-radius * radius * 110.0);
	vec3 blue = vec3(0.08, 0.35, 0.55);
	vec3 violet = vec3(0.34, 0.13, 0.39);
	ALBEDO = mix(blue, violet, grain) + core * vec3(0.65, 0.84, 0.88);
	ALPHA = clamp((cloud * 0.75 + core * 0.9) * layer_alpha, 0.0, 0.94);
}
