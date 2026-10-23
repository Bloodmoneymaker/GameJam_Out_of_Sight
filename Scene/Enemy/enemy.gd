@tool
class_name Enemy
extends CharacterBody3D
## Shared movement and echo stun behaviour. Assign optional nodes in the Inspector.

@export_group("AI")
@export var chase_enabled: bool = true
@export var target_group: StringName = &"player"
@export var chase_speed: float = 3.0
@export var stop_distance: float = 1.5
@export var navigation_agent: NavigationAgent3D

@export_group("Echo Stun")
@export var echo_stun_enabled: bool = true
@export_range(0.0, 10.0, 0.1) var stun_duration: float = 1.5
@export var refresh_stun_on_hit: bool = true
## Optional hit point, e.g. the collision shape. Defaults to the enemy origin.
@export var echo_hit_point: Node3D

var _player: Node3D
var _is_walking := true
var _stun_time_remaining := 0.0
var _incoming_echoes: Array[IncomingEcho] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("enemy")
	Echo.wave_emitted.connect(_on_echo_emitted)


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
	if chase_enabled and not is_stunned() and is_instance_valid(_player):
		var player_offset := _player.global_position - global_position
		player_offset.y = 0.0
		if player_offset.length() > stop_distance:
			direction = player_offset
			if is_instance_valid(navigation_agent):
				var navigation_map := navigation_agent.get_navigation_map()
				if navigation_map.is_valid() and NavigationServer3D.map_get_iteration_id(navigation_map) > 0:
					navigation_agent.target_position = NavigationServer3D.map_get_closest_point(navigation_map, _player.global_position)
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
	if not echo_stun_enabled or not can_stun or lifetime <= 0.0:
		return
	var distance := _echo_hit_position().distance_to(origin)
	_incoming_echoes.append(IncomingEcho.new(origin, speed, lifetime, distance))


func _echo_hit_position() -> Vector3:
	return echo_hit_point.global_position if is_instance_valid(echo_hit_point) else global_position


func _update_echo_hits(delta: float) -> void:
	if not echo_stun_enabled:
		_incoming_echoes.clear()
		return
	for index in range(_incoming_echoes.size() - 1, -1, -1):
		var wave := _incoming_echoes[index]
		wave.age = minf(wave.age + delta, wave.lifetime)
		var gap := _echo_hit_position().distance_to(wave.origin) - wave.speed * wave.age
		# Detect the travelling front, including a wave emitted at our position.
		if gap <= 0.0 and wave.previous_gap >= 0.0:
			apply_stun()
			_incoming_echoes.remove_at(index)
		elif wave.age >= wave.lifetime:
			_incoming_echoes.remove_at(index)
		else:
			wave.previous_gap = gap


func apply_stun() -> void:
	if is_stunned() and not refresh_stun_on_hit:
		return
	_stun_time_remaining = maxf(stun_duration, 0.0)
	if is_stunned():
		velocity.x = 0.0
		velocity.z = 0.0
		_set_walking(false)


func _set_walking(walking: bool) -> void:
	if _is_walking == walking:
		return
	_is_walking = walking
	_on_walking_changed(walking)


## Override in a specific enemy to update its animations.
func _on_walking_changed(_walking: bool) -> void:
	pass


func _find_player() -> Node3D:
	for node in get_tree().get_nodes_in_group(target_group):
		if node is Node3D:
			return node
	return null
