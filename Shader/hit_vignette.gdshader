shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 edge_distance = min(UV, vec2(1.0) - UV);
	float edge = 1.0 - smoothstep(0.0, 0.24, min(edge_distance.x, edge_distance.y));
	COLOR = vec4(0.9, 0.025, 0.015, edge * 0.65 * COLOR.a);
}
