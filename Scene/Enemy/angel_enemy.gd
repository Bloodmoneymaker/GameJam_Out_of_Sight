extends "res://Scene/Enemy/enemy.gd"
## Blink movement, poses and spatial laughter for the Angel.

const ANGEL_SOUNDS: Array[int] = [
	Audio.SOUND.Angel_01,
	Audio.SOUND.Angel_02,
	Audio.SOUND.Angel_03
]
const MIN_SOUND_INTERVAL := 4.0
const MAX_SOUND_INTERVAL := 9.0
const SOUND_MAX_DISTANCE := 24.0
const SOUND_VOLUME_DB := 0.0
const SOUND_UNIT_SIZE := 8.0

@export_group("Angel Teleport")
@export_range(0.0, 3.0, 0.05) var attack_delay_after_teleport: float = 0.6
@export_range(0.0, 1.0, 0.05) var flank_chance: float = 0.55
@export_range(0.0, 1.0, 0.05) var quick_blink_chance: float = 0.3
@export_range(0.1, 3.0, 0.05) var blink_interval_scale: float = 0.65
@export_range(0.1, 1.0, 0.05) var approach_fraction_min: float = 0.35
@export_range(0.1, 1.0, 0.05) var approach_fraction_max: float = 0.6
@export_range(3.0, 20.0, 0.5) var flank_max_distance: float = 8.0

var _visibility_radius := 2.5
var _last_blink_was_quick := false
var _sound_timer: Timer
var _laugh_player: AudioStreamPlayer3D
var _blink_wait_remaining := 0.0
@onready var _animation_player: AnimationPlayer = $Angle2/AnimationPlayer


func _ready() -> void:
	super._ready()
	# Enclose the entire model, including wings, regardless of its landing rotation.
	for node in find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		var bounds := mesh_node.get_aabb()
		for corner in range(8):
			var world_corner := mesh_node.global_transform * bounds.get_endpoint(corner)
			_visibility_radius = maxf(_visibility_radius, global_position.distance_to(world_corner) + 0.3)
	_blink_wait_remaining = _next_blink_wait(20.0)
	if is_instance_valid(_animation_player):
		_animation_player.play("Angle_Stay")
	if Engine.is_editor_hint():
		return

	_sound_timer = Timer.new()
	_sound_timer.one_shot = true
	add_child(_sound_timer)
	_sound_timer.start(randf_range(1.0, 3.0))
	_laugh_player = AudioStreamPlayer3D.new()
	_laugh_player.max_distance = SOUND_MAX_DISTANCE
	_laugh_player.volume_db = SOUND_VOLUME_DB
	_laugh_player.unit_size = SOUND_UNIT_SIZE
	add_child(_laugh_player)
	_laugh_player.position = Vector3.UP * 1.4


func _process(_delta: float) -> void:
	if not is_instance_valid(_sound_timer):
		return
	if not _can_move_and_laugh():
		_laugh_player.stop()
	elif _is_behind_player() and _sound_timer.is_stopped():
		_try_laugh(0.6)


func _try_laugh(chance: float) -> void:
	if not is_inside_tree() or not _can_move_and_laugh():
		return
	if not _sound_timer.is_stopped() or _laugh_player.playing:
		return
	# Retry after a short pause, never roll a new chance every frame.
	if randf() >= chance:
		_sound_timer.start(randf_range(1.0, 2.0))
		return
	var sound_id: int = ANGEL_SOUNDS.pick_random()
	_laugh_player.stream = Audio.sound[sound_id]
	_laugh_player.pitch_scale = randf_range(0.95, 1.05)
	_laugh_player.play()
	_schedule_next_sound()


func _schedule_next_sound() -> void:
	if _can_move_and_laugh():
		_sound_timer.start(randf_range(MIN_SOUND_INTERVAL, MAX_SOUND_INTERVAL))


func _can_move_and_laugh() -> bool:
	return not is_stunned() and chase_enabled and is_instance_valid(get_chase_target())


func _is_behind_player() -> bool:
	var player := _player
	if not is_instance_valid(player):
		player = _find_player()
	if not is_instance_valid(player):
		return false
	var offset := global_position - player.global_position
	if offset.length() > SOUND_MAX_DISTANCE:
		return false
	offset.y = 0.0
	var backward := player.global_basis.z
	backward.y = 0.0
	return offset.normalized().dot(backward.normalized()) > 0.25


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
	if is_instance_valid(_laugh_player):
		_laugh_player.stop()
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

	if _position_in_player_view(global_position):
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

	if randf() < flank_chance and _try_flank_teleport(target, distance_to_target):
		_try_laugh(0.7)
		_blink_wait_remaining = _next_blink_wait(distance_to_target)
		_delay_attack_after_teleport(target)
		return true

	var direction := to_target.normalized()
	var hop_distance := minf(remaining_distance, distance_to_target * randf_range(minf(approach_fraction_min, approach_fraction_max), maxf(approach_fraction_min, approach_fraction_max)))
	if is_instance_valid(navigation_agent):
		var navigation_map := navigation_agent.get_navigation_map()
		if navigation_map.is_valid() and NavigationServer3D.map_get_iteration_id(navigation_map) > 0:
			navigation_agent.target_position = NavigationServer3D.map_get_closest_point(navigation_map, target.global_position)
			var path_offset := navigation_agent.get_next_path_position() - global_position
			path_offset.y = 0.0
			if path_offset.length_squared() > 0.001:
				direction = path_offset.normalized()
				hop_distance = minf(hop_distance, path_offset.length())

	var destination := global_position + direction * hop_distance
	if not can_teleport_to(destination):
		_blink_wait_remaining = 0.2
		return true
	look_at(global_position - direction, Vector3.UP)
	global_position = destination
	_try_laugh(0.6 if _is_behind_player() else 0.35)
	_blink_wait_remaining = _next_blink_wait(distance_to_target)
	_delay_attack_after_teleport(target)
	return true


## Shared by AI blinks and scripted level teleports. No camera means no teleport.
func can_teleport_to(destination: Vector3) -> bool:
	return not is_stunned() and not _position_in_player_view(global_position) and not _position_in_player_view(destination)


func _position_in_player_view(position: Vector3) -> bool:
	var camera := get_viewport().get_camera_3d()
	if not is_instance_valid(camera):
		return true
	# Conservative sphere/frustum intersection: even a wing at the screen edge
	# blocks teleportation. Darkness and intervening walls do not bypass this rule.
	for plane in camera.get_frustum():
		if plane.distance_to(position) > _visibility_radius:
			return false
	return true


func _delay_attack_after_teleport(target: Node3D) -> void:
	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining, attack_delay_after_teleport)
	# Stay long enough to finish the reaction window before blinking again.
	if global_position.distance_to(target.global_position) <= attack_range:
		_blink_wait_remaining = maxf(_blink_wait_remaining, attack_delay_after_teleport + 0.1)


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
	# Try different flanks rather than always appearing directly behind the player.
	# Land outside attack range, giving the player time to react to the next blink.
	var minimum_distance := maxf(attack_range + 0.75, 3.0)
	var maximum_distance := maxf(minimum_distance, minf(flank_max_distance, distance_to_target * 0.75))
	for attempt in range(8):
		var angle := randf_range(-PI * 0.85, PI * 0.85)
		var flank_direction := behind_direction.rotated(Vector3.UP, angle)
		var desired_position := target.global_position + flank_direction * randf_range(minimum_distance, maximum_distance)
		var nav_position := NavigationServer3D.map_get_closest_point(navigation_map, desired_position)
		if nav_position.distance_to(desired_position) > 0.75:
			continue
		if nav_position.distance_to(target.global_position) < minimum_distance:
			continue
		if nav_position.distance_to(global_position) < 1.0:
			continue
		if not can_teleport_to(nav_position):
			continue
		var path := NavigationServer3D.map_get_path(
			navigation_map, global_position, nav_position, true, navigation_agent.navigation_layers
		)
		if path.size() < 2 or path[path.size() - 1].distance_to(nav_position) > 0.5:
			continue
		var collider := $CollisionShape3D as CollisionShape3D
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = collider.shape
		query.transform = collider.global_transform
		query.transform.origin += nav_position - global_position
		query.collision_mask = collision_mask
		query.exclude = [get_rid()]
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			continue
		global_position = nav_position
		velocity = Vector3.ZERO
		var toward_player := target.global_position - nav_position
		toward_player.y = 0.0
		if toward_player.length_squared() > 0.001:
			look_at(nav_position - toward_player.normalized(), Vector3.UP)
		return true
	return false


func _distance_to_player() -> float:
	var player := get_chase_target()
	return global_position.distance_to(player.global_position) if is_instance_valid(player) else 20.0


func _next_blink_wait(distance: float) -> float:
	var distance_factor := clampf(distance / 20.0, 0.0, 1.0)
	var minimum_wait := lerpf(0.15, 1.0, distance_factor)
	var maximum_wait := lerpf(0.4, 3.0, distance_factor)
	var wait_time := randf_range(minimum_wait, maximum_wait) * blink_interval_scale
	# Occasional double blinks, with a recovery pause instead of endless bursts.
	if _last_blink_was_quick:
		_last_blink_was_quick = false
		return maxf(wait_time, 0.55)
	if randf() < quick_blink_chance:
		_last_blink_was_quick = true
		return randf_range(0.16, 0.28)
	return maxf(wait_time, 0.2)
