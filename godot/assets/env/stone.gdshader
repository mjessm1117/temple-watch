shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 stone_color : source_color = vec4(0.47, 0.39, 0.29, 1.0);
uniform vec4 moss_color : source_color = vec4(0.15, 0.23, 0.13, 1.0);
uniform float moss_amount = 0.10;
uniform float grain_scale = 5.0;
uniform float wear = 0.25;
varying vec3 world_pos;
varying vec3 world_normal;
varying vec2 tile_uv;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	tile_uv = UV;
}

void fragment() {
	// World-space grain remains continuous across differently scaled slabs and columns.
	float grain = hash31(floor(world_pos * grain_scale));
	float veins = sin(world_pos.x * 13.1 + world_pos.z * 7.4 + world_pos.y * 2.1) * 0.5 + 0.5;
	float chips = smoothstep(0.08, 0.01, min(min(tile_uv.x, 1.0-tile_uv.x), min(tile_uv.y, 1.0-tile_uv.y)));
	float age = 0.80 + grain * 0.25 + veins * 0.16 + chips * wear;
	float moss = smoothstep(0.64, 0.80, hash31(floor(world_pos * 2.6 + vec3(3.0, 8.0, 5.0)))) * moss_amount;
	moss *= 0.45 + 0.55 * clamp(world_normal.y + 0.3, 0.0, 1.0);
	ALBEDO = mix(stone_color.rgb * age, moss_color.rgb, moss);
	ROUGHNESS = 0.9;
	METALLIC = 0.015;
}
