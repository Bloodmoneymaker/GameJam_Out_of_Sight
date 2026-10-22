extends Node3D

@export var bullet_scene: PackedScene
@export var rate_of_fire: float = 5.0
@export var player: CollisionObject3D
@export var aim_range: float = 100.0
@export_flags_3d_physics var aim_collision_mask: int = 1

@onready var bulletSpawn: Marker3D = $BulletSpawn
@onready var anim_player:AnimationPlayer = $AnimationPlayer
@onready var scene_player:CharacterBody3D = $"../../.."

var cooldown: float = 0.0


func _physics_process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)

	if Input.is_action_pressed("shoot") and cooldown <= 0.0:
		shoot()
	if scene_player.velocity.z <= 0.1:
		anim_player.play("Stand")


func shoot() -> void:
	if bullet_scene == null or cooldown > 0.0:
		return

	var bullet = bullet_scene.instantiate()

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = bulletSpawn.global_position

	var ignore_bodies: Array[RID] = []
	if is_instance_valid(player):
		ignore_bodies.append(player.get_rid())

	var target := _get_aim_target(ignore_bodies)
	bullet.setup((target - bulletSpawn.global_position).normalized(), ignore_bodies)
	#Echo.emit_wave(global_position, 15.0, 4.0, 1.0, true, Color(0.442, 0.035, 0.118, 1.0))

	cooldown = 1.0 / maxf(rate_of_fire, 0.1)


func _get_aim_target(ignore_bodies: Array[RID]) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return bulletSpawn.global_position - bulletSpawn.global_basis.z * aim_range
	var screen_center := get_viewport().get_visible_rect().size * 0.5
	var origin := camera.project_ray_origin(screen_center)
	var target := origin + camera.project_ray_normal(screen_center) * aim_range
	var query := PhysicsRayQueryParameters3D.create(origin, target, aim_collision_mask, ignore_bodies)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return hit.position
	return target
