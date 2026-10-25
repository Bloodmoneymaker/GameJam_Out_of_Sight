extends Node
## Autoload "Echo": keeps track of active sound waves and feeds them to the echo shader.
##
## Wall reflections use the image-source method: a wave reflected by a flat wall looks
## exactly like a second wave starting at the same time from the source mirrored across
## that wall. The shader clips each mirrored wave to the source's side of its wall.

const MAX_WAVES := 96 # must match MAX_WAVES in echo_contours.gdshader
const MAX_WATER_DROP_WAVES := 32
const MAX_OTHER_WAVES := MAX_WAVES - MAX_WATER_DROP_WAVES
const MATERIAL: ShaderMaterial = preload("res://Shader/echo_contours_material.tres")

## Intensity of a reflection relative to the original wave.
const REFLECTION_STRENGTH := 0.5
## Walls closer than this to the source are skipped; their reflection would overlap the original.
const MIN_WALL_DISTANCE := 0.25

enum WaterDropEchoSize {LIGHT, NORMAL}

## Receivers decide whether and when this wave hits them.
signal wave_emitted(origin: Vector3, speed: float, lifetime: float, can_stun: bool, lure_source: Node3D)
signal visual_wave_emitted(origin: Vector3, speed: float, lifetime: float, plane: Vector4)

var _origins := PackedVector4Array()
var _params := PackedVector4Array()
var _planes := PackedVector4Array()
var _colors := PackedVector4Array()
var _next := 0
var _next_water_drop := 0
var _time := 0.0
var _ray_dirs: Array[Vector3] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_origins.resize(MAX_WAVES)
	_params.resize(MAX_WAVES)
	_planes.resize(MAX_WAVES)
	_colors.resize(MAX_WAVES)
	# 6 axis directions + 8 diagonals to find the surrounding walls
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			for z in [-1, 0, 1]:
				var n := absi(x) + absi(y) + absi(z)
				if n == 1 or n == 3:
					_ray_dirs.append(Vector3(x, y, z).normalized())
	_push()


func _process(delta: float) -> void:
	if get_tree().paused and not GameManager.finish_in_progress:
		return
	_time += delta
	MATERIAL.set_shader_parameter("now", _time)


func player_scan_echo(origin: Vector3) -> void:
	# Shorter range keeps the regular scan useful for nearby navigation.
	_emit_wave(origin, 5.0, 3.0, 1.25, true, Color.TRANSPARENT, true)


func player_power_scan_echo(origin: Vector3) -> void:
	# The full-charge scan is white, faster, and stays visible over a longer range.
	_emit_wave(origin, 12.0, 6.0, 2.0, true, Color.WHITE, true)


func player_aim_echo(origin: Vector3) -> void:
	_emit_wave(origin, 15.0, 10.0, 1.0, true, Color(0.641, 0.517, 0.289, 1.0))


func player_jump_echo(origin: Vector3) -> void:
	_emit_wave(origin, 5.0, 1.0, 0.6, true, Color.TRANSPARENT)


func player_landing_echo(origin: Vector3) -> void:
	_emit_wave(origin, 5.0, 0.5, 0.5, true, Color.TRANSPARENT)


func player_footstep_echo(origin: Vector3) -> void:
	_emit_wave(origin, 4.5, 0.75, 0.25, true, Color.TRANSPARENT)


func weapon_impact_echo(origin: Vector3) -> void:
	_emit_wave(origin, 15.0, 0.1, 0.3, true, Color.TRANSPARENT, true)


func spider_echo(origin: Vector3) -> void:
	_emit_wave(origin, 4.5, 0.75, 0.25, true, Color.TRANSPARENT)


## Local confirmation pulse only: cannot stun or lure other enemies.
func enemy_stun_echo(origin: Vector3) -> void:
	_emit_wave(origin, 6.0, 0.65, 0.8, false, Color(0.45, 0.9, 1.0, 1.0))
	AudioManager.play_sound_3d_special(
		Audio.sound[Audio.SOUND.Scan], origin, 1.7, 24.0, -3.0, 10.0
	)


func beacon_echo(origin: Vector3) -> void:
	_emit_wave(origin, 5.0, 2.0, 1.0, true, Color(0.033, 0.277, 0.184, 1.0))


func beacon_completion_echo(origin: Vector3) -> void:
	_emit_wave(origin, 16.0, 1.4, 1.8, false, Color(0.3, 1.0, 0.75, 1.0))


## A player-like scan that attracts enemies without stunning them.
func strohman_echo(origin: Vector3, source: Node3D) -> void:
	_emit_wave(origin, 10.0, 1.5, 1.0, true, Color.TRANSPARENT, false, source)


## Small and without reflections: dripping water is frequent and should not use up wave slots.
func water_drop_echo(origin: Vector3, size: int = WaterDropEchoSize.NORMAL) -> void:
	if size == WaterDropEchoSize.LIGHT:
		_emit_wave(origin, 2.5, 0.4, 0.15, false, Color(0.25, 0.55, 1.0, 1.0), false, null, true)
	else:
		_emit_wave(origin, 3.0, 0.6, 0.3, false, Color(0.25, 0.55, 1.0, 1.0), false, null, true)


func debug_echo(origin: Vector3) -> void:
	_emit_wave(origin, 15.0, 4.0, 1.0, true, Color.TRANSPARENT)


func clear_waves() -> void:
	for index in range(MAX_WAVES):
		_origins[index] = Vector4.ZERO
		_params[index] = Vector4.ZERO
		_planes[index] = Vector4.ZERO
		_colors[index] = Vector4.ZERO
	_next = 0
	_next_water_drop = 0
	_push()


## Spawns a wave plus first-order wall reflections, overwriting the oldest waves as needed.
## A transparent color uses the material's wave_color.
func _emit_wave(origin: Vector3, speed: float, lifetime: float, intensity: float, reflect: bool, color: Color, can_stun: bool = false, lure_source: Node3D = null, water_drop: bool = false) -> void:
	if color.a == 0.0:
		color = MATERIAL.get_shader_parameter("wave_color")
	var rgb := Vector4(color.r, color.g, color.b, 1.0)
	var params := Vector4(speed, lifetime, intensity, 0.0)
	_add(origin, params, Vector4.ZERO, rgb, water_drop)
	visual_wave_emitted.emit(origin, speed, lifetime, Vector4.ZERO)

	if reflect:
		var reflected := Vector4(speed, lifetime, intensity * REFLECTION_STRENGTH, 0.0)
		for plane in _find_walls(origin, speed * lifetime):
			var n := Vector3(plane.x, plane.y, plane.z)
			var mirrored := origin - 2.0 * (n.dot(origin) - plane.w) * n
			_add(mirrored, reflected, plane, rgb, water_drop)
			visual_wave_emitted.emit(mirrored, speed, lifetime, plane)

	_push()
	wave_emitted.emit(origin, speed, lifetime, can_stun, lure_source)


## Returns unique wall planes (normal facing the origin, distance) the wave can reach.
func _find_walls(origin: Vector3, reach: float) -> Array[Vector4]:
	var space := get_viewport().find_world_3d().direct_space_state
	var planes: Array[Vector4] = []
	var seen := {}

	for dir in _ray_dirs:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * reach)
		var hit := space.intersect_ray(query)
		if not hit:
			continue
		var n: Vector3 = hit.normal
		var d := n.dot(hit.position)
		if n.dot(origin) - d < MIN_WALL_DISTANCE:
			continue
		var key := Vector4i(roundi(n.x * 10), roundi(n.y * 10), roundi(n.z * 10), roundi(d * 10))
		if seen.has(key):
			continue
		seen[key] = true
		planes.append(Vector4(n.x, n.y, n.z, d))

	return planes


func _add(origin: Vector3, params: Vector4, plane: Vector4, color: Vector4, water_drop: bool = false) -> void:
	var first_slot: int
	var slot_count: int
	var cursor: int
	if water_drop:
		first_slot = MAX_OTHER_WAVES
		slot_count = MAX_WATER_DROP_WAVES
		cursor = _next_water_drop
	else:
		first_slot = 0
		slot_count = MAX_OTHER_WAVES
		cursor = _next

	# Keep waves that are still travelling. The old ring buffer overwrote slots
	# blindly, so a burst of echoes and their reflections could restart visible waves.
	var index := -1
	var oldest_slot := first_slot + cursor
	var oldest_age := -1.0
	for offset in range(slot_count):
		var candidate := first_slot + (cursor + offset) % slot_count
		var intensity := _params[candidate].z
		var age := _time - _origins[candidate].w
		if intensity <= 0.0 or age > _params[candidate].y:
			index = candidate
			break
		if age > oldest_age:
			oldest_age = age
			oldest_slot = candidate
	if index < 0:
		index = oldest_slot

	var next_cursor := (index - first_slot + 1) % slot_count
	if water_drop:
		_next_water_drop = next_cursor
	else:
		_next = next_cursor

	_origins[index] = Vector4(origin.x, origin.y, origin.z, _time)
	_params[index] = params
	_planes[index] = plane
	_colors[index] = color


func _push() -> void:
	MATERIAL.set_shader_parameter("wave_origin", _origins)
	MATERIAL.set_shader_parameter("wave_params", _params)
	MATERIAL.set_shader_parameter("wave_plane", _planes)
	MATERIAL.set_shader_parameter("wave_tint", _colors)
