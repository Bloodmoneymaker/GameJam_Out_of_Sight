extends "res://Scene/Enemy/enemy.gd"
## Plays occasional, spatial Angel sounds without changing shared enemy behaviour.

const ANGEL_SOUNDS: Array[int] = [
	Audio.SOUND.Angel_01,
	Audio.SOUND.Angel_02,
	Audio.SOUND.Angel_03
]
const MIN_SOUND_INTERVAL := 10.0
const MAX_SOUND_INTERVAL := 22.0
const SOUND_MAX_DISTANCE := 24.0
const SOUND_VOLUME_DB := 0.0
const SOUND_UNIT_SIZE := 8.0

var _sound_timer: Timer
var _blink_wait_remaining := 0.0
@onready var _animation_player: AnimationPlayer = $Angle2/AnimationPlayer


func _ready() -> void:
	super._ready()
	_blink_wait_remaining = _next_blink_wait(20.0)
	if is_instance_valid(_animation_player):
		_animation_player.play("Angle_Stay")
	if Engine.is_editor_hint():
		return

	_sound_timer = Timer.new()
	_sound_timer.one_shot = true
	_sound_timer.timeout.connect(_play_random_sound)
	add_child(_sound_timer)
	_schedule_next_sound()


func _process(_delta: float) -> void:
	if not is_instance_valid(_sound_timer):
		return
	if not _can_move_and_laugh():
		_sound_timer.stop()
	elif _sound_timer.time_left <= 0.0:
		_schedule_next_sound()


func _play_random_sound() -> void:
	if not is_inside_tree() or not _can_move_and_laugh():
		return
	var sound_id: int = ANGEL_SOUNDS.pick_random()
	AudioManager.play_sound_3d_special(
		Audio.sound[sound_id],
		global_position,
		randf_range(0.95, 1.05),
		SOUND_MAX_DISTANCE,
		SOUND_VOLUME_DB,
		SOUND_UNIT_SIZE
	)
	_schedule_next_sound()


func _schedule_next_sound() -> void:
	if _can_move_and_laugh():
		_sound_timer.start(randf_range(MIN_SOUND_INTERVAL, MAX_SOUND_INTERVAL))


func _can_move_and_laugh() -> bool:
	return not is_stunned() and chase_enabled and is_instance_valid(get_chase_target())


func _on_attack_started() -> void:
	if is_instance_valid(_animation_player):
		_animation_player.play("Angle_Grab")


func _on_walking_changed(walking: bool) -> void:
	if not is_instance_valid(_animation_player):
		return
	var close_to_player := _is_close_to_player_for_attack_pose()
	var use_attack_pose := (walking and not is_stunned()) or (is_stunned() and close_to_player)
	_animation_player.play("Angle_Grab" if use_attack_pose else "Angle_Stay")


func _on_stunned() -> void:
	_blink_wait_remaining = _next_blink_wait(_distance_to_player())
	if is_instance_valid(_animation_player):
		var close_to_player := _is_close_to_player_for_attack_pose()
		_animation_player.play("Angle_Grab" if close_to_player else "Angle_Stay")


func _is_close_to_player_for_attack_pose() -> bool:
	var player := _player
	if not is_instance_valid(player):
		player = _find_player()
	if not is_instance_valid(player):
		return false
	var offset := player.global_position - global_position
	offset.y = 0.0
	return offset.length() <= maxf(attack_range, stop_distance) + 0.75


func _update_special_chase_movement(delta: float, target: Node3D) -> bool:
	if is_stunned() or not chase_enabled or not is_instance_valid(target):
		return true

	_blink_wait_remaining -= delta
	if _blink_wait_remaining > 0.0:
		return true

	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance_to_target := to_target.length()
	var remaining_distance := distance_to_target - stop_distance
	if remaining_distance <= 0.05:
		_blink_wait_remaining = _next_blink_wait(distance_to_target)
		return true

	if randf() < 0.2 and _try_flank_teleport(target, distance_to_target):
		_blink_wait_remaining = _next_blink_wait(distance_to_target)
		return true

	var direction := to_target.normalized()
	var hop_distance := minf(remaining_distance, distance_to_target * randf_range(0.2, 0.3))
	if is_instance_valid(navigation_agent):
		var navigation_map := navigation_agent.get_navigation_map()
		if navigation_map.is_valid() and NavigationServer3D.map_get_iteration_id(navigation_map) > 0:
			navigation_agent.target_position = NavigationServer3D.map_get_closest_point(navigation_map, target.global_position)
			var path_offset := navigation_agent.get_next_path_position() - global_position
			path_offset.y = 0.0
			if path_offset.length_squared() > 0.001:
				direction = path_offset.normalized()
				hop_distance = minf(hop_distance, path_offset.length())

	look_at(global_position - direction, Vector3.UP)
	global_position += direction * hop_distance
	_blink_wait_remaining = _next_blink_wait(distance_to_target)
	return true


func _try_flank_teleport(target: Node3D, distance_to_target: float) -> bool:
	if not is_instance_valid(navigation_agent):
		return false
	var navigation_map := navigation_agent.get_navigation_map()
	if not navigation_map.is_valid() or NavigationServer3D.map_get_iteration_id(navigation_map) <= 0:
		return false

	var behind_direction := target.global_basis.z
	behind_direction.y = 0.0
	if behind_direction.length_squared() <= 0.001:
		return false
	behind_direction = behind_direction.normalized()
	var desired_position := target.global_position + behind_direction * distance_to_target
	desired_position.y = global_position.y
	var nav_position := NavigationServer3D.map_get_closest_point(navigation_map, desired_position)
	if nav_position.distance_to(desired_position) > 0.5:
		return false

	var path := NavigationServer3D.map_get_path(
		navigation_map,
		global_position,
		nav_position,
		true,
		navigation_agent.navigation_layers
	)
	if path.size() < 2 or path[path.size() - 1].distance_to(nav_position) > 0.5:
		return false

	var toward_player := target.global_position - nav_position
	toward_player.y = 0.0
	if toward_player.length_squared() > 0.001:
		look_at(nav_position - toward_player.normalized(), Vector3.UP)
	global_position = nav_position
	return true


func _distance_to_player() -> float:
	var player := get_chase_target()
	return global_position.distance_to(player.global_position) if is_instance_valid(player) else 20.0


func _next_blink_wait(distance: float) -> float:
	var distance_factor := clampf(distance / 20.0, 0.0, 1.0)
	var minimum_wait := lerpf(0.15, 1.0, distance_factor)
	var maximum_wait := lerpf(0.4, 3.0, distance_factor)
	return randf_range(minimum_wait, maximum_wait)
