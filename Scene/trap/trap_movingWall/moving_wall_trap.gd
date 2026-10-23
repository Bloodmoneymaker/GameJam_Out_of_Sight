class_name MovingWallTrap
extends Trap

@export var closed_offset: Vector3 = Vector3(2.2, 0.0, 0.0)
@export_range(0.05, 10.0, 0.05) var close_duration: float = 0.8
@export_range(0.05, 10.0, 0.05) var open_duration: float = 0.8

@onready var echo_wall: EchoMesh = $EchoWall
@onready var return_timer: Timer = $ReturnTimer

var _open_position: Vector3
var _wall_tween: Tween
var _transitioning := false


func _ready() -> void:
	_open_position = echo_wall.position
	super._ready()


func activate() -> void:
	if _transitioning:
		return
	super.activate()


func _on_activated() -> void:
	_transitioning = true
	_wall_tween = create_tween()
	_wall_tween.set_trans(Tween.TRANS_SINE)
	_wall_tween.set_ease(Tween.EASE_IN_OUT)
	_wall_tween.tween_property(echo_wall, "position", _open_position + closed_offset, close_duration)
	await _wall_tween.finished
	_transitioning = false
	if is_active:
		return_timer.start()


func _on_deactivated() -> void:
	return_timer.stop()
	if _wall_tween and _wall_tween.is_running():
		_wall_tween.kill()
	_transitioning = true
	_wall_tween = create_tween()
	_wall_tween.set_trans(Tween.TRANS_SINE)
	_wall_tween.set_ease(Tween.EASE_IN_OUT)
	_wall_tween.tween_property(echo_wall, "position", _open_position, open_duration)
	await _wall_tween.finished
	_transitioning = false


func _on_return_timer_timeout() -> void:
	deactivate()
