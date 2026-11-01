shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float danger=0.0;
uniform float phase=0.0;
uniform sampler2D cloud_noise : filter_linear, repeat_enable;
void fragment(){vec2 p=UV*7.0;float n=texture(cloud_noise,UV+vec2(TIME*0.003,phase)).r*1.4;float edge=smoothstep(0.5,0.16,length(UV-0.5));ALBEDO=mix(vec3(0.012,0.003,0.018),vec3(0.55,0.025,0.045),smoothstep(0.5,1.2,n));ALPHA=edge*danger*(0.3+n*0.6);}
