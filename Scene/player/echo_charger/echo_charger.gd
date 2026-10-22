extends Node
class_name EchoCharger
## Manages only the left-click scan and its charges.
## One charge returns per refresh interval.

signal charges_changed(current: int, maximum: int)

@export_range(1, 100, 1) var max_charges: int = 3
@export_range(0.1, 120.0, 0.1) var refresh_time: float = 5.0

var current_charges: int = 0

@onready var refresh_timer: Timer = $RefreshTimer


func _ready() -> void:
	current_charges = max_charges
	charges_changed.emit(current_charges, max_charges)
	print("Echo bereit: %d/%d Ladungen." % [current_charges, max_charges])


func try_scan(origin: Vector3) -> bool:
	if not _consume_charge():
		return false
	Echo.emit_wave(origin, 10.0, 1.5, 1.0)
	AudioManager.play_sound_3d(Audio.SOUND.Scan, origin)
	return true


func _consume_charge() -> bool:
	if current_charges <= 0:
		print("Keine Echo-Ladungen mehr! Warte auf das Nachladen.")
		return false
	current_charges -= 1
	if refresh_timer.is_stopped():
		refresh_timer.start(refresh_time)
	charges_changed.emit(current_charges, max_charges)
	print("Echo benutzt: %d/%d Ladungen übrig." % [current_charges, max_charges])
	return true



func _on_refresh_timer_timeout() -> void:
	current_charges = mini(current_charges + 1, max_charges)
	if current_charges < max_charges:
		refresh_timer.start(refresh_time)
	charges_changed.emit(current_charges, max_charges)
	print("Echo nachgeladen: %d/%d Ladungen." % [current_charges, max_charges])
