shader_type spatial;
render_mode unshaded;
uniform vec4 ocean : source_color = vec4(0.03,0.15,0.3,1.0);
uniform vec4 land : source_color = vec4(0.2,0.6,0.4,1.0);
uniform float seed = 1.0;
uniform float biome = 0.0;
uniform sampler2D cloud_noise : filter_linear, repeat_enable;
float noise(vec3 p){return texture(cloud_noise,p.xy*0.07+p.z*0.025).r;}
void fragment(){
 vec3 p=vec3(sin(UV.x*6.283)*sin(UV.y*3.1416),cos(UV.y*3.1416),cos(UV.x*6.283)*sin(UV.y*3.1416));
 float n=noise(p*4.0+seed)*0.6+noise(p*11.0+seed)*0.28+noise(p*32.0)*0.12;
 float terrain=smoothstep(0.42,0.59,n);
 if(biome>1.5 && biome<2.5)terrain=smoothstep(0.25,0.7,n+sin(p.y*38.0+n*8.0)*0.12);
 vec3 col=mix(ocean.rgb,land.rgb,terrain);
 float ice=smoothstep(0.81,0.98,abs(p.y)+n*0.14);
 col=mix(col,vec3(0.8,0.93,0.98),ice*(biome<0.5?0.65:0.0));
 float clouds=smoothstep(0.64,0.78,noise(p*8.0+vec3(TIME*0.012,seed,0.0)));
 float light=0.16+0.84*max(0.0,dot(normalize(NORMAL),normalize(vec3(-0.6,0.7,0.8))));
 ALBEDO=mix(col,vec3(0.78,0.87,0.9),clouds*0.3)*light;ROUGHNESS=1.0;
 EMISSION=col*0.07;
 if(biome>2.5){float cities=step(0.87,noise(p*100.0))*terrain;EMISSION+=vec3(1.0,0.65,0.2)*cities*1.5;}
}
