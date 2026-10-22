@tool
extends MeshInstance3D
class_name EchoMesh
## Static level geometry: choose a Mesh in the Inspector.
## The shared echo material and mesh-surface collision are assigned at runtime.

const ECHO_MATERIAL: ShaderMaterial = preload("res://Shader/echo_material.tres")

@export_flags_3d_physics var collision_layer: int = 1
@export_flags_3d_physics var collision_mask: int = 1


func _ready() -> void:
	material_override = ECHO_MATERIAL
	var body: StaticBody3D = $StaticBody3D
	var collider: CollisionShape3D = $StaticBody3D/CollisionShape3D
	body.collision_layer = collision_layer
	body.collision_mask = collision_mask
	if mesh == null:
		push_warning("EchoMesh needs a Mesh to generate collision: %s" % name)
		return
	collider.shape = mesh.create_trimesh_shape()
