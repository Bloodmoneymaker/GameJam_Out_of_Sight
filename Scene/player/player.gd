extends CharacterBody3D
class_name PlayerCharacter

@export var speed := 5.0
@export var sprint_speed := 8.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.002
@export var aim_range := 100.0
@export var step_distance := 1.8
@export var feet_offset := 0.9

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _step_progress := 0.0
var _was_on_floor := true

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var echo_charger = $EchoCharger


func _ready() -> void:
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT:
			echo_charger.try_scan(head.global_position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_emit_wave_at_aim()


func _emit_wave_at_aim() -> void:
	var origin := camera.global_position
	var target := origin - camera.global_basis.z * aim_range
	var query := PhysicsRayQueryParameters3D.create(origin, target, 0xFFFFFFFF, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		Echo.emit_wave(hit.position + hit.normal * 0.1, 10.0, 1.0, 0.7, true, Color(0.0, 0.0, 0.718, 1.0))


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		Echo.emit_wave(_feet_position(), 5.0, 1.0, 0.6)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed := sprint_speed if Input.is_action_pressed("sprint") else speed

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
	_update_footsteps()


func _update_footsteps() -> void:
	var on_floor := is_on_floor()

	if on_floor and not _was_on_floor:
		# Landing
		Echo.emit_wave(_feet_position(), 5.0, 0.5, 0.5)
		_step_progress = 0.0
	elif on_floor:
		_step_progress += Vector2(velocity.x, velocity.z).length() * get_physics_process_delta_time()
		if _step_progress >= step_distance:
			_step_progress = 0.0
			Echo.emit_wave(_feet_position(), 4.5, 0.75, 0.25)

	_was_on_floor = on_floor


func _feet_position() -> Vector3:
	return global_position - Vector3(0, feet_offset, 0)
