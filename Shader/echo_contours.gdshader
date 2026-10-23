shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

// Must match MAX_WAVES in echo.gd
const int MAX_WAVES = 64;

// xyz = origin, w = start time
uniform vec4 wave_origin[MAX_WAVES];
// x = speed, y = lifetime, z = intensity (0 = slot unused)
uniform vec4 wave_params[MAX_WAVES];
// Reflected waves only: xyz = wall normal (towards the real source), w = plane distance.
// Zero normal = no clipping.
uniform vec4 wave_plane[MAX_WAVES];
// rgb = color of each wave (set by echo.gd, falls back to wave_color)
uniform vec4 wave_tint[MAX_WAVES];
uniform float now;

// Default color for waves emitted without one
uniform vec3 wave_color : source_color = vec3(1, 0, 0);
uniform float front_width = 0.6;
uniform float afterglow = 0.25;
// Forward+: use the visible scene's depth/normal prepass to find real contours.
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
// Opaque polygon materials encode their real mesh edges in magenta.
uniform sampler2D scene_edges : hint_screen_texture, repeat_disable, filter_nearest;
#if CURRENT_RENDERER == RENDERER_FORWARD_PLUS
uniform sampler2D scene_normals : hint_normal_roughness_texture, repeat_disable, filter_nearest;
#endif
uniform float outline_width : hint_range(0.5, 4.0, 0.1) = 1.0;
uniform float outline_strength : hint_range(0.0, 4.0, 0.1) = 2.4;
uniform float normal_threshold : hint_range(0.01, 1.0, 0.01) = 0.04;
uniform float depth_threshold : hint_range(0.005, 0.2, 0.005) = 0.04;

// Camera-attached quad. Reverse-Z puts the quad at the near plane.
void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec3 view_position(vec2 uv, float depth, mat4 inverse_projection) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec4 position = inverse_projection * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);
#else
	vec4 position = inverse_projection * vec4(uv * 2.0 - 1.0, depth, 1.0);
#endif
	return position.xyz / position.w;
}

vec3 surface_normal(vec2 uv, vec3 center, mat4 inverse_projection, vec2 texel) {
#if CURRENT_RENDERER == RENDERER_FORWARD_PLUS
	return normalize(textureLod(scene_normals, uv, 0.0).xyz * 2.0 - 1.0);
#else
	// WebGL has no normal prepass texture. Reconstruct the visible surface
	// using the depth samples that remain closest to its plane at silhouettes.
	vec2 left_uv = uv - vec2(texel.x, 0.0);
	vec2 right_uv = uv + vec2(texel.x, 0.0);
	vec2 down_uv = uv - vec2(0.0, texel.y);
	vec2 up_uv = uv + vec2(0.0, texel.y);
	vec3 left = center - view_position(left_uv, textureLod(scene_depth, left_uv, 0.0).r, inverse_projection);
	vec3 right = view_position(right_uv, textureLod(scene_depth, right_uv, 0.0).r, inverse_projection) - center;
	vec3 down = center - view_position(down_uv, textureLod(scene_depth, down_uv, 0.0).r, inverse_projection);
	vec3 up = view_position(up_uv, textureLod(scene_depth, up_uv, 0.0).r, inverse_projection) - center;
	vec3 dx = abs(left.z) < abs(right.z) ? left : right;
	vec3 dy = abs(down.z) < abs(up.z) ? down : up;
	vec3 normal = cross(dx, dy);
	return normal / max(length(normal), 0.000001);
#endif
}

float contour_sample(vec2 uv, vec3 center, vec3 normal, mat4 inverse_projection, vec2 texel) {
	float depth = textureLod(scene_depth, uv, 0.0).r;
	// Reverse-Z: a zero depth is the background, hence an outer silhouette.
	if (depth <= 0.0) {
		return 1.0;
	}
	vec3 neighbor = view_position(uv, depth, inverse_projection);
	float tolerance = max(depth_threshold, -center.z * 0.002);
	// Draw silhouettes on the nearer object, never a copy on the wall behind it.
	if (neighbor.z > center.z + tolerance) {
		return 0.0;
	}
	// Distance from the surface plane avoids outlining flat, sloping floors.
	float plane_distance = abs(dot(neighbor - center, normal));
	float depth_edge = smoothstep(tolerance, tolerance * 2.0, plane_distance);
	vec3 neighbor_normal = surface_normal(uv, neighbor, inverse_projection, texel);
	float normal_difference = 1.0 - clamp(dot(normal, normalize(neighbor_normal)), 0.0, 1.0);
	float normal_edge = smoothstep(normal_threshold, normal_threshold * 2.0, normal_difference);
	return max(depth_edge, normal_edge);
}

void fragment() {
	ALBEDO = vec3(0.0);
	ALPHA = 1.0; // Draw after the opaque scene and replace the entire 3D image.
	float visible_depth = textureLod(scene_depth, SCREEN_UV, 0.0).r;
	if (visible_depth > 0.0) {
		vec2 pixel = outline_width / VIEWPORT_SIZE;
		vec3 center = view_position(SCREEN_UV, visible_depth, INV_PROJECTION_MATRIX);
		vec3 normal = surface_normal(SCREEN_UV, center, INV_PROJECTION_MATRIX, 1.0 / VIEWPORT_SIZE);
		float contour = contour_sample(SCREEN_UV + vec2(pixel.x, 0.0), center, normal, INV_PROJECTION_MATRIX, 1.0 / VIEWPORT_SIZE);
		contour = max(contour, contour_sample(SCREEN_UV - vec2(pixel.x, 0.0), center, normal, INV_PROJECTION_MATRIX, 1.0 / VIEWPORT_SIZE));
		contour = max(contour, contour_sample(SCREEN_UV + vec2(0.0, pixel.y), center, normal, INV_PROJECTION_MATRIX, 1.0 / VIEWPORT_SIZE));
		contour = max(contour, contour_sample(SCREEN_UV - vec2(0.0, pixel.y), center, normal, INV_PROJECTION_MATRIX, 1.0 / VIEWPORT_SIZE));
		contour = max(contour, contour_sample(SCREEN_UV + pixel * vec2(0.7071, 0.7071), center, normal, INV_PROJECTION_MATRIX, 1.0 / VIEWPORT_SIZE));
		contour = max(contour, contour_sample(SCREEN_UV + pixel * vec2(-0.7071, 0.7071), center, normal, INV_PROJECTION_MATRIX, 1.0 / VIEWPORT_SIZE));
		contour = max(contour, contour_sample(SCREEN_UV + pixel * vec2(0.7071, -0.7071), center, normal, INV_PROJECTION_MATRIX, 1.0 / VIEWPORT_SIZE));
		contour = max(contour, contour_sample(SCREEN_UV - pixel * vec2(0.7071, 0.7071), center, normal, INV_PROJECTION_MATRIX, 1.0 / VIEWPORT_SIZE));
		vec3 edge_mask = textureLod(scene_edges, SCREEN_UV, 0.0).rgb;
		float polygon_edge = clamp(min(edge_mask.r, edge_mask.b) - edge_mask.g, 0.0, 1.0);
		contour = max(contour, polygon_edge);
		vec3 world_pos = (INV_VIEW_MATRIX * vec4(center, 1.0)).xyz;
		vec3 front = vec3(0.0);
		vec3 glow = vec3(0.0);

		// Most wall pixels are black: skip all 64 wave evaluations there.
		if (contour > 0.001) {
			for (int i = 0; i < MAX_WAVES; i++) {
				float intensity = wave_params[i].z;
				if (intensity <= 0.0) {
					continue;
				}
				float age = now - wave_origin[i].w;
				float life = wave_params[i].y;
				if (age < 0.0 || age > life) {
					continue;
				}
				// A mirrored source is only valid in front of the wall that reflects it
				vec4 plane = wave_plane[i];
				if (dot(plane.xyz, plane.xyz) > 0.5 && dot(plane.xyz, world_pos) - plane.w < 0.02) {
					continue;
				}

				float radius = age * wave_params[i].x;
				vec3 delta = world_pos - wave_origin[i].xyz;
				float distance_squared = dot(delta, delta);
				float reach = radius + front_width;
				if (distance_squared > reach * reach) {
					continue;
				}
				float d = sqrt(distance_squared);
				float fade = 1.0 - age / life;
				fade *= fade;
				float atten = 1.0 / (1.0 + d * 0.08);
				vec3 tint = wave_tint[i].rgb;

				// Bright ring at the wave front
				front += mix(tint, vec3(1.0), 0.15) * (1.0 - smoothstep(0.0, front_width, abs(d - radius))) * fade * intensity;
				// Only contours retain the colored echo after the bright front passes.
				glow += tint * step(d, radius) * afterglow * fade * intensity * atten;
			}
		}

		// Only the nearest visible geometry contributes: no lines through walls.
		ALBEDO = (front + glow) * contour * outline_strength;
	}
}
