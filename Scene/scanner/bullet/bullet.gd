extends RigidBody3D
class_name Bullet

@export var speed: float = 60.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0
var _impacted := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(shoot_direction: Vector3, ignore_bodies: Array[RID]) -> void:
	for body_rid in ignore_bodies:
		PhysicsServer3D.body_add_collision_exception(get_rid(), body_rid)
	linear_velocity = shoot_direction.normalized() * speed


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if _impacted:
		return
	_impacted = true
	_finish_impact.call_deferred(body, global_position)


func _finish_impact(body: Node, impact_position: Vector3) -> void:
	Echo.weapon_impact_echo(impact_position)
	if is_instance_valid(body) and body.has_method("take_damage"):
		body.call("take_damage", damage)
	queue_free()
