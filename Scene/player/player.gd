extends CharacterBody3D
class_name PlayerCharacter

@export var speed := 5.0
@export var sprint_speed := 8.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.002
@export var step_distance := 1.8
@export var feet_offset := 0.9

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _player_step_sounds: Array[int] = [
	Audio.SOUND.PlayerStep_01,
	Audio.SOUND.PlayerStep_02,
	Audio.SOUND.PlayerStep_03,
	Audio.SOUND.PlayerStep_04,
	Audio.SOUND.PlayerStep_05,
	Audio.SOUND.PlayerStep_06
]
var _step_progress := 0.0
var _was_on_floor := true

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var echo_charger = $EchoCharger
@onready var health_component = $HealthComponent


func _ready() -> void:
	health_component.died.connect(_on_died)
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


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		Echo.player_jump_echo(_feet_position())
		_play_step_pair()

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
		Echo.player_landing_echo(_feet_position())
		_play_step_pair()
		_step_progress = 0.0
	elif on_floor:
		_step_progress += Vector2(velocity.x, velocity.z).length() * get_physics_process_delta_time()
		if _step_progress >= step_distance:
			_step_progress = 0.0
			Echo.player_footstep_echo(_feet_position())
			_play_single_step()

	_was_on_floor = on_floor


func _feet_position() -> Vector3:
	return global_position - Vector3(0, feet_offset, 0)


func _play_single_step() -> void:
	AudioManager.play_sound_3d(_player_step_sounds.pick_random(), _feet_position())


func _play_step_pair() -> void:
	_player_step_sounds.shuffle()
	var step_position := _feet_position()
	AudioManager.play_sound_3d(_player_step_sounds[0], step_position)
	await get_tree().create_timer(0.06).timeout
	if is_inside_tree():
		AudioManager.play_sound_3d(_player_step_sounds[1], _feet_position())


func take_damage(amount: float) -> void:
	if amount > 0.0 and not health_component.is_dead():
		AudioManager.play_sound_2d(Audio.SOUND.PlayerHit)
		$HitFeedback/HitVignette.pulse()
	health_component.take_damage(amount)


func _on_died() -> void:
	velocity = Vector3.ZERO
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	$HUD.hide()
	GameManager.show_lose_screen()
