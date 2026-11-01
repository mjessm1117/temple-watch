shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform sampler2D cloud_noise : filter_linear, repeat_enable;
void fragment(){vec2 p=(UV-0.5)*2.0;float r=length(p);float a=atan(p.y,p.x);float n=texture(cloud_noise,UV*2.0+TIME*0.0005).r;
 float arms=pow(0.5+0.5*sin(a*4.0-r*16.0+n*3.0-TIME*0.008),4.0);
 float core=exp(-r*r*95.0);float dust=arms*(0.25+n)*smoothstep(1.0,0.15,r)*smoothstep(0.03,0.2,r);
 vec3 color=mix(vec3(0.10,0.27,0.4),vec3(0.30,0.16,0.43),n);color=mix(color,vec3(0.64,0.84,0.85),core);
 ALBEDO=color*0.7;ALPHA=clamp(dust*0.6+core*0.75,0.0,0.9);}
