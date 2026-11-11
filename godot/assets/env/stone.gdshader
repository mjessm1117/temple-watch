shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 stone_color : source_color = vec4(0.47, 0.39, 0.29, 1.0);
uniform vec4 moss_color : source_color = vec4(0.15, 0.23, 0.13, 1.0);
uniform float moss_amount = 0.10;
uniform float grain_scale = 5.0;
uniform float wear = 0.25;
uniform float detail_quality = 0.0;
uniform int atlas_quadrant = 0;
uniform sampler2D atlas_albedo : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D atlas_roughness : filter_linear_mipmap, repeat_disable;
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
	vec3 normal_axis = abs(world_normal);
	vec2 plane = normal_axis.y > max(normal_axis.x, normal_axis.z) ? world_pos.xz : (normal_axis.x > normal_axis.z ? world_pos.zy : world_pos.xy);
	vec2 quadrant = vec2(float(atlas_quadrant % 2), float(atlas_quadrant / 2));
	vec2 uv = (quadrant + clamp(fract(plane * 0.36), vec2(0.012), vec2(0.988))) * 0.5;
	vec3 tex = texture(atlas_albedo, uv).rgb;
	float rough_tex = texture(atlas_roughness, uv).r;
	float veins = sin(world_pos.x * 13.1 + world_pos.z * 7.4 + world_pos.y * 2.1) * 0.5 + 0.5;
	float chips = smoothstep(0.08, 0.01, min(min(tile_uv.x, 1.0-tile_uv.x), min(tile_uv.y, 1.0-tile_uv.y)));
	float contact = (1.0 - smoothstep(-0.08, 0.27, world_pos.y)) * 0.12;
	float side = (1.0 - smoothstep(0.20, 0.70, world_normal.y)) * 0.10;
	float age = 0.78 + grain * 0.10 + veins * 0.04 + dot(tex, vec3(0.299, 0.587, 0.114)) * 0.16;
	age *= 1.0 - contact - side - chips * wear * 0.16;
	if (detail_quality > 0.5) {
		float cracks = smoothstep(0.83, 0.95, hash31(floor(world_pos * 17.0)));
		age *= 1.0 - cracks * 0.12;
	}
	float moss = smoothstep(0.64, 0.80, hash31(floor(world_pos * 2.6 + vec3(3.0, 8.0, 5.0)))) * moss_amount;
	moss *= 0.45 + 0.55 * clamp(world_normal.y + 0.3, 0.0, 1.0);
	ALBEDO = mix(stone_color.rgb * age, stone_color.rgb * tex * 1.18, 0.22 + detail_quality * 0.10);
	ALBEDO = mix(ALBEDO, moss_color.rgb, moss);
	ROUGHNESS = clamp(0.55 + rough_tex * 0.35 + grain * 0.07 + moss * 0.12, 0.54, 0.98);
	METALLIC = 0.015;
	NORMAL_MAP = vec3(0.5 + (grain - 0.5) * 0.10, 0.5 + (veins - 0.5) * 0.06, 1.0);
	NORMAL_MAP_DEPTH = 0.22 + detail_quality * 0.12;
}
