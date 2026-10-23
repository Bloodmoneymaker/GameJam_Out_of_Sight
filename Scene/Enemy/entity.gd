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


@export var echo_speed:float = 2.0
@export var echo_lifetime:float = 1.0
@export var echo_intensity:float = 1.0
@export var echo_reflecting:bool = true
@export var echo_color:Color = Color.BURLYWOOD

@export_group("AI")
@export var chase_speed: float = 3.0
@export var stop_distance: float = 1.5

@export var skeleton:Skeleton3D

@export var bones:Array[BoneAttachment3D] = []

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	audio_player.stream = sound_body
	audio_player.play()


var _player: PlayerCharacter
var _is_walking := true


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not is_instance_valid(_player):
		_player = _find_player()

	var direction := Vector3.ZERO
	if is_instance_valid(_player):
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

	if direction.length_squared() > 0.001:
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
	Echo.emit_wave(bones[0].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)

func send_xxx(xxx:int) -> void:
	match xxx:
		0:
			Echo.emit_wave(bones[0].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)
			Echo.emit_wave(bones[2].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)
			Echo.emit_wave(bones[4].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)

		1:
			Echo.emit_wave(bones[1].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)
			Echo.emit_wave(bones[3].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)
			Echo.emit_wave(bones[5].global_position,echo_speed,echo_lifetime,echo_intensity,echo_reflecting,echo_color)



func _on_timer_timeout() -> void:
	timer.start()
	if animation_tree.get("parameters/XXX/current_state") == "Walk":
		sound_trigger_movement()
	
