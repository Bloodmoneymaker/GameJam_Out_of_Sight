shader_type spatial;
render_mode unshaded;

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
uniform float grid_size = 1.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 front = vec3(0.0);
	vec3 glow = vec3(0.0);

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
		float d = distance(world_pos, wave_origin[i].xyz);
		float fade = 1.0 - age / life;
		fade *= fade;
		float atten = 1.0 / (1.0 + d * 0.08);
		vec3 tint = wave_tint[i].rgb;

		// Bright ring at the wave front
		front += mix(tint, vec3(1.0), 0.5) * (1.0 - smoothstep(0.0, front_width, abs(d - radius))) * fade * intensity;
		// Surfaces the wave already passed stay faintly lit
		glow += tint * step(d, radius) * afterglow * fade * intensity * atten;
	}

	// World-space grid lines so surfaces read as geometry
	vec3 coord = world_pos / grid_size;
	vec3 g = abs(fract(coord - 0.5) - 0.5) / max(fwidth(coord), vec3(1e-4));
	g += abs(world_normal) * 1e3; // ignore the axis along the surface normal
	float line = 1.0 - clamp(min(min(g.x, g.y), g.z), 0.0, 1.0);

	float shade = 0.55 + 0.45 * abs(dot(world_normal, normalize(vec3(0.3, 0.8, 0.5))));

	vec3 col = glow * (shade + line * 2.0);
	col += front * (0.7 + line);
	ALBEDO = col;
}
