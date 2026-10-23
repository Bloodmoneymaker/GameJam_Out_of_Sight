class_name TrapTrigger
extends Node3D
## Subclasses call activate() when their activation condition is met.

signal triggered

@export var enabled: bool = true
@export var one_shot: bool = false
var _used := false


func activate() -> void:
	if not enabled or (one_shot and _used):
		return
	_used = true
	triggered.emit()


func reset() -> void:
	_used = false
