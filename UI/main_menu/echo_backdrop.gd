extends Node3D

@export_range(0.5, 10.0, 0.1) var echo_interval: float = 2.4

@onready var echo_timer: Timer = $EchoTimer
@onready var echo_origin: Marker3D = $EchoOrigin
@onready var camera: Camera3D = $Camera3D

var _elapsed := 0.0
var _camera_base_rotation := Vector3.ZERO


func _ready() -> void:
	_camera_base_rotation = camera.rotation
	echo_timer.wait_time = echo_interval
	echo_timer.start()
	call_deferred("_emit_echo")


func _process(delta: float) -> void:
	_elapsed += delta
	camera.rotation.y = _camera_base_rotation.y + sin(_elapsed * 0.18) * 0.025


func _on_echo_timer_timeout() -> void:
	_emit_echo()


func _emit_echo() -> void:
	if not is_instance_valid(GameManager.ui_main) or not GameManager.ui_main.visible:
		return
	Echo.beacon_echo(echo_origin.global_position)
