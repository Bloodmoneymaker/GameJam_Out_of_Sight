extends Node3D

const SOUND_MAX_DISTANCE := 30.0
const SOUND_VOLUME_DB := 6.0
const SOUND_UNIT_SIZE := 10.0

@export_range(0.1, 60.0, 0.1) var beacon_rate: float = 1.0
@export_range(0.0, 0.5, 0.01) var float_amplitude: float = 0.12
@export_range(0.5, 10.0, 0.1) var float_cycle_duration: float = 2.8

var _completed := false

@onready var timer: Timer = $Timer
@onready var orb: Node3D = $Orb

signal player_entered_beacon(player: PlayerCharacter)

func _ready() -> void:
	timer.wait_time = beacon_rate
	_start_floating_animation()


func _start_floating_animation() -> void:
	var base_height := orb.position.y
	var bob_tween := create_tween().set_loops()
	bob_tween.set_trans(Tween.TRANS_SINE)
	bob_tween.set_ease(Tween.EASE_IN_OUT)
	bob_tween.tween_property(orb, "position:y", base_height + float_amplitude, float_cycle_duration * 0.25)
	bob_tween.tween_property(orb, "position:y", base_height - float_amplitude, float_cycle_duration * 0.5)
	bob_tween.tween_property(orb, "position:y", base_height, float_cycle_duration * 0.25)


func _emit_echo() -> void:
	Echo.beacon_echo(orb.global_position)



func _on_timer_timeout() -> void:
	AudioManager.play_sound_3d_special(
		Audio.sound[Audio.SOUND.Beacon],
		orb.global_position,
		1.0,
		SOUND_MAX_DISTANCE,
		SOUND_VOLUME_DB,
		SOUND_UNIT_SIZE
	)
	_emit_echo()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body is PlayerCharacter or _completed or GameManager.finish_in_progress:
		return
	if body.health_component.is_dead():
		return
	_completed = true
	GameManager.finish_in_progress = true
	timer.stop()
	get_tree().paused = true
	player_entered_beacon.emit(body)
	# Keep the beacon visible even when the normal echo has faded.
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.3, 1.0, 0.75)
	(orb as MeshInstance3D).material_override = material
	# The player and enemies remain frozen; only this presentation tween runs.
	var sequence := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var camera: Camera3D = body.camera
	if camera.global_position.distance_squared_to(orb.global_position) > 0.001:
		var target := camera.global_transform.looking_at(orb.global_position, Vector3.UP)
		sequence.tween_property(camera, "global_transform", target, 0.25).set_trans(Tween.TRANS_SINE)
	sequence.tween_property(orb, "scale", Vector3.ONE * 1.3, 0.2).set_trans(Tween.TRANS_QUAD)
	sequence.tween_callback(_release_completion_echo)
	sequence.tween_property(orb, "scale", Vector3.ONE * 0.8, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sequence.tween_interval(0.85)
	sequence.tween_callback(_finish_completion)


func _release_completion_echo() -> void:
	Echo.beacon_completion_echo(orb.global_position)
	SignalManager.beacon_reached.emit(orb.global_position)


func _finish_completion() -> void:
	if is_queued_for_deletion() or not GameManager.finish_in_progress:
		return
	GameManager.finish_in_progress = false
	GameManager.show_win_screen()
