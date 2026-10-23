extends Node3D

@export_range(0.1, 60.0, 0.1) var beacon_rate: float = 5.0
@export_range(2.0,10.0,0.1) var beacon_speed:float = 5.0
@export_range(1.0,5.0,0.1) var beacon_lifetime:float = 2.0
@export_range(0.5,3.0,0.1) var beacon_intensity:float = 1.0
@export var beacon_color = Color(0.033, 0.277, 0.184, 1.0)
@export var beacon_refelecting:bool = true

@onready var timer: Timer = $Timer

signal player_entered_beacon(player: PlayerCharacter)

func _ready() -> void:
	timer.wait_time = beacon_rate


func _emit_echo() -> void:
	Echo.emit_wave(global_position, beacon_speed, beacon_lifetime, beacon_intensity, beacon_refelecting, beacon_color)



func _on_timer_timeout() -> void:
	_emit_echo()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is PlayerCharacter:
		player_entered_beacon.emit(body)
		GameManager.show_win_screen()
		print("Spieler hat den Bereich betreten!")
