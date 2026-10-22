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

var _origins := PackedVector4Array()
var _params := PackedVector4Array()
var _planes := PackedVector4Array()
var _next := 0
var _time := 0.0
var _ray_dirs: Array[Vector3] = []


func _ready() -> void:
	_origins.resize(MAX_WAVES)
	_params.resize(MAX_WAVES)
	_planes.resize(MAX_WAVES)
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


## Spawns a wave plus its first-order wall reflections.
## Overwrites the oldest waves when all slots are taken.
func emit_wave(origin: Vector3, speed := 10.0, lifetime := 3.0, intensity := 1.0, reflect := true) -> void:
	var params := Vector4(speed, lifetime, intensity, 0.0)
	_add(origin, params, Vector4.ZERO)

	if reflect:
		var reflected := Vector4(speed, lifetime, intensity * REFLECTION_STRENGTH, 0.0)
		for plane in _find_walls(origin, speed * lifetime):
			var n := Vector3(plane.x, plane.y, plane.z)
			var mirrored := origin - 2.0 * (n.dot(origin) - plane.w) * n
			_add(mirrored, reflected, plane)

	_push()


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


func _add(origin: Vector3, params: Vector4, plane: Vector4) -> void:
	_origins[_next] = Vector4(origin.x, origin.y, origin.z, _time)
	_params[_next] = params
	_planes[_next] = plane
	_next = (_next + 1) % MAX_WAVES


func _push() -> void:
	MATERIAL.set_shader_parameter("wave_origin", _origins)
	MATERIAL.set_shader_parameter("wave_params", _params)
	MATERIAL.set_shader_parameter("wave_plane", _planes)
