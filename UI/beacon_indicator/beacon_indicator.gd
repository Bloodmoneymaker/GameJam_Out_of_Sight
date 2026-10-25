extends Control

const BEACON_GROUP := "beacons"

@onready var arrow: TextureRect = $Arrow

var _beacon: Node3D
var _fade_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.pivot_offset = arrow.size * 0.5
	arrow.hide()


func _process(_delta: float) -> void:
	refresh_direction()


func refresh_direction() -> void:
	if not is_instance_valid(_beacon):
		_beacon = get_tree().get_first_node_in_group(BEACON_GROUP) as Node3D
	if not is_instance_valid(_beacon):
		arrow.hide()
		return

	var camera := get_viewport().get_camera_3d()
	if not is_instance_valid(camera):
		return

	var direction := _beacon.global_position - camera.global_position
	direction.y = 0.0
	var forward := -camera.global_basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return
	forward = forward.normalized()
	var right := Vector3(-forward.z, 0.0, forward.x)
	arrow.pivot_offset = arrow.size * 0.5
	if direction.length_squared() < 0.0001:
		arrow.rotation = 0.0
	else:
		arrow.rotation = atan2(direction.dot(right), direction.dot(forward))


func show_for_power_echo() -> void:
	refresh_direction()
	if not is_instance_valid(_beacon):
		return
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	arrow.show()
	arrow.modulate.a = 1.0
	_fade_tween = create_tween()
	_fade_tween.tween_interval(3.0)
	_fade_tween.tween_property(arrow, "modulate:a", 0.0, 0.6)
	_fade_tween.tween_callback(_finish_fade)


func _finish_fade() -> void:
	arrow.hide()
	arrow.modulate.a = 1.0
