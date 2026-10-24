extends Node3D
class_name WaterDrip
## Spawns falling water drops at this node's position in regular intervals.

const DROP_SCENE: PackedScene = preload("res://Scene/Objects/WaterDrip/water_drop.tscn")

@export_range(0.1, 30.0, 0.1) var interval: float = 2.0
## Random +/- variation of the interval so several drips don't fall in sync.
@export_range(0.0, 10.0, 0.1) var interval_jitter: float = 0.5

@onready var _timer := Timer.new()


func _ready() -> void:
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_restart_timer()


func _on_timer_timeout() -> void:
	var drop := DROP_SCENE.instantiate() as WaterDrop
	drop.top_level = true
	add_child(drop)
	drop.global_position = global_position
	_restart_timer()


func _restart_timer() -> void:
	_timer.start(maxf(interval + randf_range(-interval_jitter, interval_jitter), 0.1))
