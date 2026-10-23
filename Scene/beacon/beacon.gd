extends Node3D

const SOUND_MAX_DISTANCE := 30.0
const SOUND_VOLUME_DB := 6.0
const SOUND_UNIT_SIZE := 10.0

@export_range(0.1, 60.0, 0.1) var beacon_rate: float = 1.0
@export_range(0.0, 0.5, 0.01) var float_amplitude: float = 0.12
@export_range(0.5, 10.0, 0.1) var float_cycle_duration: float = 2.8

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
	if body is PlayerCharacter:
		player_entered_beacon.emit(body)
		GameManager.show_win_screen()
		print("Spieler hat den Bereich betreten!")
