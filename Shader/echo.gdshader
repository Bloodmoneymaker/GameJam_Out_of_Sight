shader_type spatial;
render_mode unshaded, depth_draw_opaque, cull_back, fog_disabled;

// Opaque black geometry supplies depth and normals, including animated monsters.
// EchoContours on the player camera renders the visible echo lines afterwards.
void fragment() {
	ALBEDO = vec3(0.0);
	ROUGHNESS = 1.0;
}
