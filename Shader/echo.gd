extends Node
## Autoload "Echo": keeps track of active sound waves and feeds them to the echo shader.
##
## Wall reflections use the image-source method: a wave reflected by a flat wall looks
## exactly like a second wave starting at the same time from the source mirrored across
## that wall. The shader clips each mirrored wave to the source's side of its wall.

const MAX_WAVES := 64 # must match MAX_WAVES in echo.gdshader
const MATERIAL: ShaderMaterial = preload("res://Shader/echo_material.tres")

## Intensity of a reflection relative to the original wave.
const REFLECTION_STRENGTH := 0.5
## Walls closer than this to the source are skipped; their reflection would overlap the original.
const MIN_WALL_DISTANCE := 0.25

## Receivers decide whether and when this wave hits them.
signal wave_emitted(origin: Vector3, speed: float, lifetime: float, can_stun: bool)

var _origins := PackedVector4Array()
var _params := PackedVector4Array()
var _planes := PackedVector4Array()
var _colors := PackedVector4Array()
var _next := 0
var _time := 0.0
var _ray_dirs: Array[Vector3] = []


func _ready() -> void:
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
	_time += delta
	MATERIAL.set_shader_parameter("now", _time)


func player_scan_echo(origin: Vector3) -> void:
	_emit_wave(origin, 10.0, 1.5, 1.0, true, Color.TRANSPARENT, true)


func player_aim_echo(origin: Vector3) -> void:
	_emit_wave(origin, 10.0, 1.0, 0.7, true, Color(0.0, 0.0, 0.718, 1.0), true)


func player_jump_echo(origin: Vector3) -> void:
	_emit_wave(origin, 5.0, 1.0, 0.6, true, Color.TRANSPARENT)


func player_landing_echo(origin: Vector3) -> void:
	_emit_wave(origin, 5.0, 0.5, 0.5, true, Color.TRANSPARENT)


func player_footstep_echo(origin: Vector3) -> void:
	_emit_wave(origin, 4.5, 0.75, 0.25, true, Color.TRANSPARENT)


func weapon_impact_echo(origin: Vector3) -> void:
	_emit_wave(origin, 15.0, 0.1, 0.3, true, Color.TRANSPARENT, true)


func spider_echo(origin: Vector3) -> void:
	_emit_wave(origin, 10.0, 0.1, 0.02, true, Color(0.097030394, 0.09369888, 0.083710216, 1.0))


func beacon_echo(origin: Vector3) -> void:
	_emit_wave(origin, 5.0, 2.0, 1.0, true, Color(0.033, 0.277, 0.184, 1.0))


func debug_echo(origin: Vector3) -> void:
	_emit_wave(origin, 15.0, 4.0, 1.0, true, Color.TRANSPARENT)


## Spawns a wave plus first-order wall reflections, overwriting the oldest waves as needed.
## A transparent color uses the material's wave_color.
func _emit_wave(origin: Vector3, speed: float, lifetime: float, intensity: float, reflect: bool, color: Color, can_stun: bool = false) -> void:
	if color.a == 0.0:
		color = MATERIAL.get_shader_parameter("wave_color")
	var rgb := Vector4(color.r, color.g, color.b, 1.0)
	var params := Vector4(speed, lifetime, intensity, 0.0)
	_add(origin, params, Vector4.ZERO, rgb)

	if reflect:
		var reflected := Vector4(speed, lifetime, intensity * REFLECTION_STRENGTH, 0.0)
		for plane in _find_walls(origin, speed * lifetime):
			var n := Vector3(plane.x, plane.y, plane.z)
			var mirrored := origin - 2.0 * (n.dot(origin) - plane.w) * n
			_add(mirrored, reflected, plane, rgb)

	_push()
	wave_emitted.emit(origin, speed, lifetime, can_stun)


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


func _add(origin: Vector3, params: Vector4, plane: Vector4, color: Vector4) -> void:
	_origins[_next] = Vector4(origin.x, origin.y, origin.z, _time)
	_params[_next] = params
	_planes[_next] = plane
	_colors[_next] = color
	_next = (_next + 1) % MAX_WAVES


func _push() -> void:
	MATERIAL.set_shader_parameter("wave_origin", _origins)
	MATERIAL.set_shader_parameter("wave_params", _params)
	MATERIAL.set_shader_parameter("wave_plane", _planes)
	MATERIAL.set_shader_parameter("wave_tint", _colors)
