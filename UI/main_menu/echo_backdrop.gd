extends Node3D

@export_range(0.5, 10.0, 0.1) var echo_interval: float = 2.4

@onready var echo_timer: Timer = $EchoTimer
@onready var echo_origin: Marker3D = $EchoOrigin
@onready var camera: Camera3D = $Camera3D
@onready var angel: CharacterBody3D = $Entity_Angle
@onready var angel_mesh: MeshInstance3D = $Entity_Angle/Angle2/Angle/Skeleton3D/Engel

var _elapsed := 0.0
var _camera_base_rotation := Vector3.ZERO


func _ready() -> void:
	# The menu has no gameplay floor, so disable gravity and movement for its display angel.
	angel.set_physics_process(false)
	# Keep the angel faintly visible between pulses; EchoContours adds the bright outline.
	var angel_material := StandardMaterial3D.new()
	angel_material.albedo_color = Color(0.008, 0.025, 0.035)
	angel_material.emission_enabled = true
	angel_material.emission = Color(0.025, 0.12, 0.16)
	angel_material.emission_energy_multiplier = 0.45
	angel_mesh.material_override = angel_material
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
