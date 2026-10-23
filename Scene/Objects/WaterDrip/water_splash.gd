extends Node3D
class_name WaterSplash
## Short splash where a drop lands: a few droplets jump outward and a ring spreads on the surface.
## Plain opaque meshes, so the echo contour pass outlines them while the drop's wave passes.

const LIFETIME := 0.5
const DROPLET_COUNT := 6
const RING_GROWTH := 5.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _age := 0.0
var _droplets: Array[MeshInstance3D] = []
var _velocities: Array[Vector3] = []
var _ring: MeshInstance3D


## Call before adding to the tree; `normal` is the surface normal at the impact.
func setup(position_: Vector3, normal: Vector3) -> void:
	top_level = true
	var up := normal.normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	transform = Transform3D(Basis(side, up, side.cross(up)), position_)


func _ready() -> void:
	var droplet_mesh := SphereMesh.new()
	droplet_mesh.radius = 0.03
	droplet_mesh.height = 0.06
	droplet_mesh.radial_segments = 8
	droplet_mesh.rings = 4
	for i in DROPLET_COUNT:
		var droplet := _add_mesh(droplet_mesh)
		var angle := TAU * (i + randf_range(-0.3, 0.3)) / DROPLET_COUNT
		var outward := Vector3(cos(angle), 0.0, sin(angle)) * randf_range(0.5, 1.0)
		_velocities.append(outward + Vector3.UP * randf_range(1.2, 2.0))
		_droplets.append(droplet)

	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.04
	ring_mesh.outer_radius = 0.06
	ring_mesh.rings = 16
	ring_mesh.ring_segments = 6
	_ring = _add_mesh(ring_mesh)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return

	var t := _age / LIFETIME
	# Local space: +Y is the surface normal, gravity pulls along world down
	var local_gravity := global_basis.inverse() * (Vector3.DOWN * gravity)
	for i in _droplets.size():
		_velocities[i] += local_gravity * delta
		_droplets[i].position += _velocities[i] * delta
		_droplets[i].scale = Vector3.ONE * (1.0 - t)

	var ring_scale := 1.0 + RING_GROWTH * t
	_ring.scale = Vector3(ring_scale, 1.0 - t, ring_scale)


func _add_mesh(mesh_: Mesh) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh_
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance
