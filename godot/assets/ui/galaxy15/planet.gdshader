shader_type spatial;
render_mode unshaded;
uniform vec4 ocean : source_color = vec4(0.03, 0.15, 0.3, 1.0);
uniform vec4 land : source_color = vec4(0.2, 0.6, 0.4, 1.0);
uniform float seed = 1.0;
uniform float biome = 0.0;
uniform bool low_mode = false;
uniform float phone_boost = 1.0;
uniform sampler2D cloud_noise : filter_linear, repeat_enable;
float grain(vec3 p) { return texture(cloud_noise, p.xy * 0.075 + p.z * 0.027).r; }
void fragment() {
	vec3 globe = vec3(sin(UV.x * 6.283) * sin(UV.y * 3.1416), cos(UV.y * 3.1416), cos(UV.x * 6.283) * sin(UV.y * 3.1416));
	float broad = grain(globe * 5.0 + seed);
	float fine = grain(globe * 17.0 + seed * 1.7);
	float land_mask = smoothstep(0.43, 0.57, broad * 0.72 + fine * 0.28);
	if (biome > 1.5 && biome < 2.5) land_mask = smoothstep(0.24, 0.70, broad + sin(globe.y * 34.0 + fine * 6.0) * 0.14);
	vec3 color = mix(ocean.rgb, land.rgb, land_mask);
	float ice = smoothstep(0.78, 0.98, abs(globe.y) + broad * 0.17);
	color = mix(color, vec3(0.81, 0.94, 0.99), ice * (biome < 0.5 ? 0.7 : 0.0));
	if (biome > 0.5 && biome < 1.5) color += vec3(0.14, 0.035, 0.005) * smoothstep(0.63, 0.78, fine);
	float cloud = 0.0;
	if (!low_mode) cloud = smoothstep(0.65, 0.8, grain(globe * 10.0 + vec3(TIME * 0.01, seed, 0.0)));
	color = mix(color, vec3(0.78, 0.88, 0.92), cloud * 0.25);
	float day = dot(normalize(NORMAL), normalize(vec3(-0.6, 0.7, 0.8)));
	float light = 0.12 + 0.88 * max(0.0, day);
	ALBEDO = color * light * phone_boost;
	ROUGHNESS = 1.0;
	EMISSION = color * 0.035;
	if (biome > 2.5) {
		float city = step(0.86, fine) * land_mask * (1.0 - smoothstep(-0.08, 0.24, day));
		EMISSION += vec3(1.0, 0.57, 0.18) * city * 1.8;
	}
}
