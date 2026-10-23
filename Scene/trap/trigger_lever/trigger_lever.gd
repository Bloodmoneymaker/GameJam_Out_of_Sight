extends TrapTrigger

@export_range(0.05, 2.0, 0.05) var lever_duration: float = 0.35
@export_range(0.05, 2.0, 0.05) var return_duration: float = 0.35

@onready var lever_pivot: Node3D = $LeverPivot
@onready var return_timer: Timer = $ReturnTimer

var _lever_moving := false


## Call this when the player or another system pulls the lever.
## The inherited `triggered` signal is emitted after the lever finishes moving.
func activate() -> void:
	if not enabled or _lever_moving or (one_shot and _used):
		return

	_lever_moving = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		lever_pivot,
		"rotation",
		Vector3(deg_to_rad(-90.0), 0.0, 0.0),
		lever_duration
	)
	await tween.finished
	super.activate()
	return_timer.start()


func _on_return_timer_timeout() -> void:
	var return_tween := create_tween()
	return_tween.set_trans(Tween.TRANS_SINE)
	return_tween.set_ease(Tween.EASE_IN_OUT)
	return_tween.tween_property(lever_pivot, "rotation", Vector3.ZERO, return_duration)
	await return_tween.finished
	_lever_moving = false
