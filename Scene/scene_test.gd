extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Echo.emit_wave(Vector3(0, 0, 0), 15.0, 4.0, 1.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
