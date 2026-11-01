shader_type spatial;
render_mode unshaded, blend_add, cull_front, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.2,0.7,1.0,1.0);
uniform float strength = 0.65;
void fragment(){float rim=pow(1.0-abs(dot(normalize(NORMAL),normalize(VIEW))),3.0);ALBEDO=tint.rgb;ALPHA=rim*strength;}
