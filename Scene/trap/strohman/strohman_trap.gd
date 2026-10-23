class_name StrohmanTrap
extends Trap

## Lifetime starts with activation, not while waiting for a trigger.
@export_range(0.1, 300.0, 0.1) var lifetime: float = 15.0
@export_range(0.1, 60.0, 0.1) var echo_interval: float = 2.0

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var echo_timer: Timer = $EchoTimer


func _ready() -> void:
	lifetime_timer.start(lifetime)
	echo_timer.start(echo_interval)
	super._ready()


func _on_deactivated() -> void:
	lifetime_timer.stop()
	echo_timer.stop()


func _emit_echo() -> void:
	if is_active:
		Echo.strohman_echo(global_position, self)



func _on_lifetime_timer_timeout() -> void:
	deactivate()
	queue_free()


func _on_echo_timer_timeout() -> void:
	_emit_echo()
