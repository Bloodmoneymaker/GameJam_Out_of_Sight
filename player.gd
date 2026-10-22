extends CharacterBody3D

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


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.button_index == MOUSE_BUTTON_LEFT:
			Echo.emit_wave(head.global_position, 15.0, 4.0, 1.0)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_emit_wave_at_aim()


func _emit_wave_at_aim() -> void:
	var from := camera.global_position
	var to := from - camera.global_basis.z * aim_range
	var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		Echo.emit_wave(hit.position + hit.normal * 0.1, 15.0, 2.5, 0.7)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		Echo.emit_wave(_feet_position(), 15.0, 2.0, 0.6)

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
		Echo.emit_wave(_feet_position(), 15.0, 0.5, 0.5)
		_step_progress = 0.0
	elif on_floor:
		_step_progress += Vector2(velocity.x, velocity.z).length() * get_physics_process_delta_time()
		if _step_progress >= step_distance:
			_step_progress = 0.0
			Echo.emit_wave(_feet_position(), 15, 0.5, 0.25)

	_was_on_floor = on_floor


func _feet_position() -> Vector3:
	return global_position - Vector3(0, feet_offset, 0)
