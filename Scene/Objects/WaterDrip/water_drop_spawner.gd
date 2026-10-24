extends Area3D
class_name WaterDropSpawner
## Spawns water drops at random positions inside its CollisionShape3D.

enum EchoSize {LIGHT, NORMAL}

@export_range(0.1, 100.0, 0.1, "or_greater") var drops_per_second: float = 1.0
@export var echo_size: EchoSize = EchoSize.NORMAL
@export var play_drop_sound: bool = false

@onready var spawn_shape: CollisionShape3D = $CollisionShape3D
@onready var drop_template: WaterDrop = $WaterDropTemplate

var _spawn_accumulator := 0.0


func _ready() -> void:
	monitoring = false
	monitorable = false
	drop_template.hide()
	drop_template.set_physics_process(false)


func _process(delta: float) -> void:
	if drops_per_second <= 0.0:
		return

	_spawn_accumulator += delta * drops_per_second
	while _spawn_accumulator >= 1.0:
		_spawn_accumulator -= 1.0
		_spawn_drop()


func _spawn_drop() -> void:
	if spawn_shape.shape == null:
		return

	var drop := drop_template.duplicate(Node.DUPLICATE_USE_INSTANTIATION) as WaterDrop
	if drop == null:
		push_error("WaterDropTemplate must use the WaterDrop script.")
		return

	drop.top_level = true
	drop.visible = true
	drop.echo_size = int(echo_size)
	drop.play_impact_sound = drop.play_impact_sound and play_drop_sound
	drop.set_physics_process(true)
	add_child(drop)
	drop.global_position = spawn_shape.global_transform * _random_point_in_shape()


func _random_point_in_shape() -> Vector3:
	if spawn_shape.shape is BoxShape3D:
		var box := spawn_shape.shape as BoxShape3D
		var half_size := box.size * 0.5
		return Vector3(
		randf_range(-half_size.x, half_size.x),
		randf_range(-half_size.y, half_size.y),
		randf_range(-half_size.z, half_size.z)
		)

	if spawn_shape.shape is SphereShape3D:
		var sphere := spawn_shape.shape as SphereShape3D
		return Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * sphere.radius * pow(randf(), 1.0 / 3.0)
	return Vector3.ZERO
