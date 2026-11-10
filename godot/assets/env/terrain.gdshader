shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color = vec4(0.35,0.3,0.23,1.0);
uniform vec4 secondary_color : source_color = vec4(0.19,0.25,0.12,1.0);
// 0 stone, 1 deck, 2 earth/grass, 3 snow, 4 sand, 5 cave
uniform int biome = 0;
uniform vec2 hover_tile = vec2(-100.0);
uniform float grid_strength = 0.0;
uniform float detail_quality = 0.0;
uniform float map_seed = 0.0;
uniform int atlas_quadrant = 0;
uniform sampler2D atlas_albedo : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D atlas_roughness : filter_linear_mipmap, repeat_disable;
varying vec3 world_pos;
varying vec3 world_normal;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex() {
	world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
	vec2 p=world_pos.xz;
	float broad=noise(p*0.22), grain=noise(p*32.0);
	float detail=noise(p*4.0)*0.23+grain*0.08;
	vec2 quad=vec2(float(atlas_quadrant%2),float(atlas_quadrant/2));
	vec2 uv=(quad+clamp(fract(p*0.32+map_seed*0.0001),vec2(0.012),vec2(0.988)))*0.5;
	vec3 tex=texture(atlas_albedo,uv).rgb;
	float rough_tex=texture(atlas_roughness,uv).r;
	float tile=noise(p*0.31+vec2(map_seed*0.017,map_seed*0.031));
	float wear=noise(p*0.78+vec2(map_seed*0.011,map_seed*0.023));
	vec3 col=base_color.rgb*(0.72+broad*0.18+detail*0.55+tile*0.06);
	col=mix(col,col*tex*2.0,0.27);
	col*=mix(0.88,1.06,smoothstep(0.12,0.84,wear));
	float rough=clamp(0.61+rough_tex*0.33+grain*0.07,0.55,0.98), metal=0.015;
	if(biome==0) {
		float vein=sin(p.x*7.0+p.y*3.0+noise(p)*8.0)*0.025;
		float crack=smoothstep(0.76,0.88,noise(p*1.37+vec2(4.0,7.0)));
		col*=1.0+vein-crack*0.11;
		if(detail_quality>0.5) {
			float chips=noise(p*11.0+vec2(3.7,8.1));
			col*=0.94+chips*0.10;
			rough=clamp(0.56+rough_tex*0.30+chips*0.08,0.55,0.95);
		}
	} else if(biome==1) {
		float tread=step(0.85,sin((p.x+p.y)*55.0))*step(0.6,sin((p.x-p.y)*32.0));
		float scorch=smoothstep(0.70,0.86,noise(p*0.55+vec2(map_seed*0.01)));
		col*=1.0+tread*0.06-scorch*0.19;
		rough=0.35+rough_tex*0.32; metal=0.65;
		float puddle=smoothstep(0.77,0.89,wear)*step(0.65,tile);
		col=mix(col,col*vec3(0.64,0.82,0.91),puddle*0.58);
		rough=mix(rough,0.20,puddle*0.72);
		if(detail_quality>0.5) rough+=noise(p*16.0)*0.08;
	} else if(biome==2) {
		col=mix(col,secondary_color.rgb*(0.9+detail),smoothstep(0.25,0.78,broad)*0.65);
		col=mix(col,secondary_color.rgb,smoothstep(0.52,0.78,wear)*0.26);
	} else if(biome==3) {
		col=mix(secondary_color.rgb, col,0.75+0.25*sin(p.x*2.0+noise(p*0.7)*6.0));
		col*=0.88+wear*0.22;
		rough=0.83;
	} else if(biome==4) {
		col*=0.88+wear*0.22+sin(p.y*18.0+noise(p)*5.0)*0.035;
	} else {
		col=mix(col,secondary_color.rgb,noise(p*1.9)*0.23);
		col*=0.82+wear*0.24+abs(sin(p.x*3.0+p.y*2.0+noise(p)*6.0))*0.12;
	}
	// Tactical grid is local to the hovered destination; never a permanent checkerboard.
	vec2 edge=abs(fract(p+0.5)-0.5);
	float line=smoothstep(0.43,0.50,max(edge.x,edge.y));
	float grid=line*(1.0-smoothstep(1.0,4.5,distance(p,hover_tile)))*grid_strength*step(0.7,world_normal.y);
	ALBEDO=mix(col,vec3(0.28,0.62,0.68),grid*0.22);
	EMISSION=vec3(0.15,0.45,0.53)*grid*0.08;
	ROUGHNESS=rough; METALLIC=metal;
	float micro=detail_quality>0.5?noise(p*25.0):grain;
	NORMAL_MAP=vec3(0.5+(grain-0.5)*0.08,0.5+(micro-0.5)*0.08,1.0);
	NORMAL_MAP_DEPTH=detail_quality>0.5?0.42:0.3;
}
