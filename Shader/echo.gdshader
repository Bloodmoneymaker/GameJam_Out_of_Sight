shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_back, fog_disabled;

uniform bool polygon_edges_enabled = false;
uniform float polygon_line_width : hint_range(0.5, 3.0, 0.1) = 1.0;
varying vec3 barycentric;

void vertex() {
	barycentric = COLOR.rgb;
}

// Opaque black geometry supplies depth and normals, including animated monsters.
// EchoContours on the player camera renders the visible echo lines afterwards.
void fragment() {
	ALBEDO = vec3(0.0);
	if (polygon_edges_enabled) {
		vec3 pixel_width = max(fwidth(barycentric), vec3(0.00001));
		vec3 interior = smoothstep(pixel_width * polygon_line_width * 0.5, pixel_width * polygon_line_width * 1.5, barycentric);
		float edge = 1.0 - min(interior.x, min(interior.y, interior.z));
		// The fullscreen echo pass reads this mask, then hides it outside waves.
		ALBEDO = vec3(edge, 0.0, edge);
	}
	ROUGHNESS = 1.0;
}
