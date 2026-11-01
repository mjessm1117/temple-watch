shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
varying vec4 tint;
void vertex(){tint=COLOR;MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);}
void fragment(){float r=length(UV-0.5)*2.0;float glow=pow(max(0.0,1.0-r),3.0);ALBEDO=tint.rgb*2.0;ALPHA=glow*(0.65+0.35*sin(TIME*(0.5+tint.a)+tint.a*60.0));}
