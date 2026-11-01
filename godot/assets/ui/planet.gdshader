shader_type spatial;
render_mode unshaded;
uniform vec4 sea : source_color = vec4(0.08,0.25,0.32,1.0);
uniform vec4 land : source_color = vec4(0.24,0.5,0.44,1.0);
uniform float seed = 0.0;
varying vec3 point;
void vertex() { point = VERTEX; }
void fragment() {
 vec3 p = normalize(point);
 float n = sin(p.x*8.0+seed)*cos(p.y*7.0-p.z*6.0)+sin(p.z*14.0+p.y*5.0)*0.4+cos(p.x*25.0+p.z*19.0)*0.12;
 vec3 terrain = mix(sea.rgb,land.rgb,smoothstep(0.0,0.18,n));
 float light = 0.38+0.62*max(dot(p,normalize(vec3(-1.0,0.5,1.0))),0.0);
 float scan = 0.94+0.06*sin(p.y*160.0+TIME*2.0);
 ALBEDO = terrain*light*scan;
 EMISSION = terrain*0.22;
}
