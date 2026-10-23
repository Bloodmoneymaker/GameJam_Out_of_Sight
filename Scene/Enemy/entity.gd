@tool
extends CharacterBody3D

@export var audio_player:AudioStreamPlayer3D
@export var timer:Timer
@export var animation_player:AnimationPlayer
@export var animation_tree:AnimationTree
@onready var ani_tree:AnimationTree = $Monster_Schabe/AnimationTree
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

@export var sound_movment:Array[AudioStream] = []
@export var sound_attack:Array[AudioStream] = []
@export var sound_body:AudioStream


@export_group("AI")
@export var chase_speed: float = 3.0
@export var stop_distance: float = 1.5
@export_range(0.0, 10.0, 0.1) var stun_duration: float = 1.5

@export var skeleton:Skeleton3D

@export var bones:Array[BoneAttachment3D] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if is_in_group("enemy"):
		Echo.wave_emitted.connect(_on_echo_emitted)
	audio_player.stream = sound_body
	audio_player.play()


var _player: PlayerCharacter
var _is_walking := true
var _stun_time_remaining := 0.0
var _incoming_echoes: Array[IncomingEcho] = []


class IncomingEcho:
	var origin: Vector3
	var speed: float
	var lifetime: float
	var age := 0.0
	var previous_gap: float

	func _init(source: Vector3, wave_speed: float, wave_lifetime: float, distance: float) -> void:
		origin = source
		speed = wave_speed
		lifetime = wave_lifetime
		previous_gap = distance


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_stun_time_remaining = maxf(_stun_time_remaining - delta, 0.0)
	_update_echo_hits(delta)

	if _stun_time_remaining <= 0.0 and not is_instance_valid(_player):
		_player = _find_player()

	var direction := Vector3.ZERO
	if _stun_time_remaining <= 0.0 and is_instance_valid(_player):
		var player_offset := _player.global_position - global_position
		player_offset.y = 0.0
		if player_offset.length() > stop_distance:
			var nav_target := _player.global_position
			var navigation_map := navigation_agent.get_navigation_map()
			if navigation_map.is_valid() and NavigationServer3D.map_get_iteration_id(navigation_map) > 0:
				nav_target = NavigationServer3D.map_get_closest_point(navigation_map, nav_target)
			navigation_agent.target_position = nav_target
			direction = navigation_agent.get_next_path_position() - global_position
			direction.y = 0.0
			if direction.length_squared() <= 0.001:
				direction = player_offset
			direction = direction.normalized()

	if _stun_time_remaining > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		_set_walking(false)
	elif direction.length_squared() > 0.001:
		velocity.x = direction.x * chase_speed
		velocity.z = direction.z * chase_speed
		look_at(global_position + direction, Vector3.UP)
		_set_walking(true)
	else:
		velocity.x = move_toward(velocity.x, 0.0, chase_speed * delta * 4.0)
		velocity.z = move_toward(velocity.z, 0.0, chase_speed * delta * 4.0)
		_set_walking(false)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta

	move_and_slide()


func is_stunned() -> bool:
	return _stun_time_remaining > 0.0


func _on_echo_emitted(origin: Vector3, speed: float, lifetime: float, can_stun: bool) -> void:
	if not can_stun or lifetime <= 0.0:
		return
	var distance := _echo_hit_position().distance_to(origin)
	_incoming_echoes.append(IncomingEcho.new(origin, speed, lifetime, distance))


func _echo_hit_position() -> Vector3:
	return $CollisionShape3D.global_position


func _update_echo_hits(delta: float) -> void:
	for index in range(_incoming_echoes.size() - 1, -1, -1):
		var wave := _incoming_echoes[index]
		wave.age = minf(wave.age + delta, wave.lifetime)
		var gap := _echo_hit_position().distance_to(wave.origin) - wave.speed * wave.age
		# Detect the travelling front, including a wave emitted at our position.
		if gap <= 0.0 and wave.previous_gap >= 0.0:
			_stun_time_remaining = stun_duration
			_incoming_echoes.remove_at(index)
		elif wave.age >= wave.lifetime:
			_incoming_echoes.remove_at(index)
		else:
			wave.previous_gap = gap


func _set_walking(walking: bool) -> void:
	if _is_walking == walking:
		return
	_is_walking = walking
	animation_tree.set("parameters/XXX/transition_request", "Walk" if walking else "Idle")


func _find_player() -> PlayerCharacter:
	for node in get_tree().get_nodes_in_group("player"):
		if node is PlayerCharacter:
			return node
	return null

func sound_trigger_movement() -> void:
	AudioManager.play_sound_3d_special(sound_movment.pick_random(),global_position,1.0,15)

func sound_trigger_position() -> void:
	AudioManager.play_sound_3d(0,global_position)

func send_echo() -> void:
	_emit_bone_echo(0)


func send_xxx(xxx: int) -> void:
	if xxx == 0 or xxx == 1:
		for index in range(xxx, 6, 2):
			_emit_bone_echo(index)


func _emit_bone_echo(index: int) -> void:
	if Engine.is_editor_hint() or index >= bones.size() or not is_instance_valid(bones[index]):
		return
	Echo.spider_echo(bones[index].global_position)


func _on_timer_timeout() -> void:
	timer.start()
	if animation_tree.get("parameters/XXX/current_state") == "Walk":
		sound_trigger_movement()
	
