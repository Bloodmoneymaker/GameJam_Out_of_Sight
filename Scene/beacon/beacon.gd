extends Node3D

@export_range(0.1, 60.0, 0.1) var beacon_rate: float = 5.0

@onready var timer: Timer = $Timer

signal player_entered_beacon(player: PlayerCharacter)

func _ready() -> void:
	timer.wait_time = beacon_rate


func _emit_echo() -> void:
	Echo.emit_wave(global_position, 15.0, 4.0, 1.0)



func _on_timer_timeout() -> void:
	_emit_echo()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is PlayerCharacter:
		player_entered_beacon.emit(body)
		print("Spieler hat den Bereich betreten!")
