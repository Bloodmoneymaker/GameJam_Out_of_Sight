shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 wave_data[4];
uniform float now = 0.0;
uniform vec2 viewport_pixel_size = vec2(0.001, 0.001);
uniform vec3 echo_color : source_color = vec3(0.15, 0.85, 1.0);
uniform float darkness : hint_range(0.0, 1.0) = 0.0;
uniform float edge_threshold : hint_range(0.0, 1.0) = 0.1;

const float WAVE_TRAVEL_TIME = 3.0;
const float AFTERGLOW_DURATION = 0.7;
const float MAX_WAVE_AGE = 4.5;

float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

vec2 wave_signal(vec2 point, vec2 source, float age, float speed) {
	float distance_from_source = length(point - source);
	float wave_passed = age - distance_from_source / speed;
	float radius = age * speed;
	float ring_width = viewport_pixel_size.y;
	float ring = 1.0 - smoothstep(ring_width, ring_width * 1.5, abs(distance_from_source - radius));
	float afterglow = (1.0 - smoothstep(0.0, AFTERGLOW_DURATION, wave_passed)) * step(0.0, wave_passed);
	return vec2(ring, afterglow);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 texel = viewport_pixel_size;
	float center = luminance(texture(screen_texture, uv).rgb);
	float edge = 0.0;
	edge = max(edge, abs(center - luminance(texture(screen_texture, uv + vec2(texel.x, 0.0)).rgb)));
	edge = max(edge, abs(center - luminance(texture(screen_texture, uv - vec2(texel.x, 0.0)).rgb)));
	edge = max(edge, abs(center - luminance(texture(screen_texture, uv + vec2(0.0, texel.y)).rgb)));
	edge = max(edge, abs(center - luminance(texture(screen_texture, uv - vec2(0.0, texel.y)).rgb)));
	edge = smoothstep(edge_threshold, edge_threshold * 2.0, edge);

	vec2 aspect = vec2(texel.y / texel.x, 1.0);
	vec2 point = uv * aspect;
	float speed = length(aspect) / WAVE_TRAVEL_TIME;
	float total_ring = 0.0;
	float total_afterglow = 0.0;

	for (int i = 0; i < 4; i++) {
		vec4 wave = wave_data[i];
		float age = now - wave.z;
		if (wave.w < 0.5 || age < 0.0 || age > MAX_WAVE_AGE) {
			continue;
		}

		vec2 source = wave.xy * aspect;
		vec2 signal = wave_signal(point, source, age, speed);
		total_ring += signal.x;
		total_afterglow += signal.y;

		vec2 left = vec2(-source.x, source.y);
		vec2 right = vec2(2.0 * aspect.x - source.x, source.y);
		vec2 top = vec2(source.x, -source.y);
		vec2 bottom = vec2(source.x, 2.0 - source.y);
		signal = wave_signal(point, left, age, speed);
		total_ring += signal.x * 0.28;
		total_afterglow += signal.y * 0.28;
		signal = wave_signal(point, right, age, speed);
		total_ring += signal.x * 0.28;
		total_afterglow += signal.y * 0.28;
		signal = wave_signal(point, top, age, speed);
		total_ring += signal.x * 0.28;
		total_afterglow += signal.y * 0.28;
		signal = wave_signal(point, bottom, age, speed);
		total_ring += signal.x * 0.28;
		total_afterglow += signal.y * 0.28;

		signal = wave_signal(point, vec2(left.x, top.y), age, speed);
		total_ring += signal.x * 0.1;
		total_afterglow += signal.y * 0.1;
		signal = wave_signal(point, vec2(left.x, bottom.y), age, speed);
		total_ring += signal.x * 0.1;
		total_afterglow += signal.y * 0.1;
		signal = wave_signal(point, vec2(right.x, top.y), age, speed);
		total_ring += signal.x * 0.1;
		total_afterglow += signal.y * 0.1;
		signal = wave_signal(point, vec2(right.x, bottom.y), age, speed);
		total_ring += signal.x * 0.1;
		total_afterglow += signal.y * 0.1;
	}

	vec3 sampled_color = texture(screen_texture, uv).rgb;
	float glow = clamp(total_afterglow, 0.0, 1.0);
	float echo_line = clamp(total_ring * 0.55 + glow * 0.2, 0.0, 1.0);
	vec3 result = sampled_color * darkness;
	result += sampled_color * glow * 0.7;
	result += echo_color * edge * echo_line * 0.45;
	result += echo_color * clamp(total_ring, 0.0, 1.0) * 0.08;
	COLOR = vec4(result, 1.0);
}
