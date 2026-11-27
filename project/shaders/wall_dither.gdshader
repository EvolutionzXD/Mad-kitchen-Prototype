shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 albedo_color : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform float fade_alpha : hint_range(0.05, 1.0) = 1.0;

void fragment() {
	ALBEDO = albedo_color.rgb;
	ALPHA = albedo_color.a * fade_alpha;
}
