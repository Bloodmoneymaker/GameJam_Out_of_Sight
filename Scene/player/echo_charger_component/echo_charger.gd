extends Node
class_name EchoCharger
## Manages only the left-click scan and its charges.
## One charge returns per refresh interval.

signal charges_changed(current: int, maximum: int)

const POWER_ECHO_COST := 3

@export_range(1, 100, 1) var max_charges: int = 3
@export_range(0.1, 120.0, 0.1) var refresh_time: float = 5.0

var current_charges: int = 0
var _last_empty_feedback_ms: int = -500

@onready var refresh_timer: Timer = $RefreshTimer


func _ready() -> void:
	current_charges = max_charges
	charges_changed.emit(current_charges, max_charges)
	print("Echo bereit: %d/%d Ladungen." % [current_charges, max_charges])


func try_scan(origin: Vector3) -> bool:
	if not _consume_charges(1):
		return false
	Echo.player_scan_echo(origin)
	AudioManager.play_sound_3d(Audio.SOUND.Scan, origin)
	return true


func try_power_scan(origin: Vector3) -> bool:
	if current_charges < POWER_ECHO_COST:
		SignalManager.emptyEcho.emit(self)
		return false
	if not _consume_charges(current_charges):
		return false
	Echo.player_power_scan_echo(origin)
	AudioManager.play_sound_3d(Audio.SOUND.Scan, origin)
	_show_beacon_indicator()
	return true


func _show_beacon_indicator() -> void:
	var beacon_indicator := get_parent().get_node_or_null("HUD/BeaconIndicator")
	if is_instance_valid(beacon_indicator) and beacon_indicator.has_method("show_for_power_echo"):
		beacon_indicator.show_for_power_echo()


func _consume_charges(amount: int) -> bool:
	if current_charges < amount:
		var now := Time.get_ticks_msec()
		if now - _last_empty_feedback_ms >= 500:
			_last_empty_feedback_ms = now
			SignalManager.emptyEcho.emit(self)
		return false
	current_charges -= amount
	if refresh_timer.is_stopped():
		refresh_timer.start(refresh_time)
	charges_changed.emit(current_charges, max_charges)
	print("Echo benutzt (%d Ladungen): %d/%d übrig." % [amount, current_charges, max_charges])
	return true



func _on_refresh_timer_timeout() -> void:
	if current_charges >= max_charges:
		return
	current_charges = mini(current_charges + 1, max_charges)
	SignalManager.echo_recharged.emit(self)
	if current_charges < max_charges:
		refresh_timer.start(refresh_time)
	charges_changed.emit(current_charges, max_charges)
	print("Echo nachgeladen: %d/%d Ladungen." % [current_charges, max_charges])
